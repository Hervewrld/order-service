# Postmortem: Redis outage (chaos test)

**Date:** 2026-08-23
**Severity:** Simulated (Sev-2 equivalent) - deliberately injected as a Phase 7 chaos
experiment, not a real production incident.
**Duration:** ~10 minutes (14:02:59 UTC - ~14:13:30 UTC), self-inflicted for the
purpose of this test.

## Summary

Redis was stopped (`docker stop docker-redis-1`) while the api, worker, and
monitoring stack were running under normal traffic, to see how the system
actually behaves when its only backing dependency disappears mid-flight -
not at startup, which Phase 3 already covered with the worker's
`wait-for-redis` init container.

The api degraded as intended (503/500 with clear error messages). The worker
did not: it crashed on the first unhandled `redis.exceptions.ConnectionError`
and, because `docker-compose.yml` had no `restart:` policy, stayed dead
until manually restarted. A gap in the alerting was also found: the
rate-based error alert never fired despite a 100% error rate, because it
requires continuous traffic to stay valid. Both issues were fixed and
re-verified live before this was written up.

## Timeline (UTC)

| Time | Event |
|---|---|
| 14:02:xx | Baseline: 5/5 orders processed successfully, all Prometheus targets `up` |
| 14:02:59 | Chaos injected: `docker stop docker-redis-1` |
| 14:02:59 | Worker crashed immediately - unhandled `ConnectionError` on `r.blpop(...)`, exited with code 1, **did not restart** (no restart policy) |
| 14:02:59+ | `GET /health` → `503 {"detail": "redis unavailable"}`; `POST /order` → `500 {"detail": "failed to queue order"}` |
| ~14:03:3x | Prometheus `worker` scrape target went `down` (worker container fully exited) |
| 14:04:07 | `HighAPIErrorRate` alert entered `pending` (error ratio = 1.0) |
| ~14:05:00 | `WorkerDown` alert reached `firing` (target down for > 1m) |
| 14:09:00 | `HighAPIErrorRate` silently reverted to `inactive` **without ever firing** - see Finding 3 |
| 14:13:19 | Recovery: `docker start docker-redis-1`, then manually `docker start docker-worker-1` (no auto-heal without a restart policy) |
| 14:13:2x | `/health` back to `200`; 5/5 post-recovery orders processed; all targets and alerts back to healthy |

**Fix applied and re-tested:** added `restart: unless-stopped` to `redis`,
`api`, and `worker` in `docker/docker-compose.yml`. Re-ran the same
experiment: worker auto-restarted 8 times while Redis was down (confirmed
via `docker inspect --format 'RestartCount'`) and, once Redis came back,
recovered and processed all 3 follow-up orders with **zero manual
intervention** - a direct improvement over the first run.

## Root cause

`worker.py`'s main loop calls `r.blpop(...)` with no exception handling
around Redis connection errors - only `json.JSONDecodeError` is caught.
Any `redis.exceptions.ConnectionError` (Redis restarting, network blip,
DNS hiccup) propagates all the way out of `main()` and kills the process.
This exact fragility was already visible in Phase 3 at *startup* (worker
crashing before Redis was ready, fixed there with an init container that
waits for `PING`) - this test showed the same root cause resurfaces mid-flight,
after the worker is already running, which the init container does nothing
for.

## Findings

1. **Worker has no resilience to a Redis connection loss after startup.**
   The Phase 3 init container only solves the cold-start ordering problem;
   it doesn't help if Redis disappears while the worker is already running.
   The API, by contrast, degrades correctly - `/health` and `/order` both
   have explicit exception handling and return clear error responses
   instead of crashing.

2. **`docker-compose.yml` had no restart policy, so nothing self-healed.**
   Kubernetes gives you this for free via the Deployment controller (we
   observed exactly that kind of auto-restart back in Phase 3's minikube
   testing); plain `docker compose` does not, unless you ask for it. Fixed
   by adding `restart: unless-stopped` - validated live, see timeline above.

3. **The rate-based error alert (`HighAPIErrorRate`) is not a reliable
   detector during low/zero-traffic outages.** `rate(...[5m])` needs
   continuous counter increases within its window to produce a meaningful
   ratio; once the one-time burst of failed requests aged out of the
   5-minute window with no follow-up traffic, both sides of the ratio
   dropped and the alert cleared on its own - despite Redis still being
   down. `WorkerDown` (an `up{job=...} == 0` check) was the alert that
   actually caught this incident reliably, because it doesn't depend on
   request volume at all.

## Action items

- [x] Add `restart: unless-stopped` to `redis`/`api`/`worker` in
      `docker/docker-compose.yml` - done and re-verified in this test.
- [ ] Add retry/backoff around the worker's Redis connection instead of
      letting it crash on every transient error - would reduce the
      restart-storm behavior (8 restarts in ~8 seconds) observed above to
      a handful of retries instead.
- [ ] Add an absolute-count alert (e.g.
      `increase(api_requests_total{status=~"5.."}[5m]) > 5`) alongside the
      existing percentage-based one, so low-traffic outages aren't missed.
- [ ] Consider a `redis_exporter` so Redis itself is a first-class
      Prometheus target instead of only being inferred from api/worker
      symptoms.
