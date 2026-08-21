# order-service

A small order-processing app used as a learning vehicle for the full
SRE/DevOps lifecycle: Python/Bash → Git → Docker → Kubernetes → Terraform →
CI/CD → Prometheus/Grafana → chaos testing & postmortems.

Each folder below corresponds to one phase of that lifecycle. As each phase
is completed, its section here gets checked off and a short write-up is
linked from `docs/`.

## Architecture (grows over the phases)

```
client -> api (Flask/FastAPI) -> queue (Redis) -> worker -> db (Postgres)
```

## Project phases

- [ ] **Phase 0 — App**: `src/api`, `src/worker`, `tests/`, `scripts/bootstrap.sh`
- [ ] **Phase 1 — Git workflow**: branching, PRs, conventional commits (see `docs/git-workflow.md`)
- [ ] **Phase 2 — Docker**: `docker/`, `docker-compose.yml`
- [ ] **Phase 3 — Kubernetes**: `k8s/base` (raw manifests), `k8s/helm` (chart)
- [ ] **Phase 4 — Terraform**: `terraform/modules`, `terraform/environments/{dev,prod}`
- [ ] **Phase 5 — CI/CD**: `.github/workflows/`
- [ ] **Phase 6 — Observability**: `monitoring/dashboards`, `monitoring/alerts`
- [ ] **Phase 7 — Chaos & postmortems**: `docs/postmortems/`

## Local development

```bash
./scripts/bootstrap.sh      # sets up local env and runs health checks
```

## Repo layout

```
order-service/
├── src/
│   ├── api/          # REST API service
│   └── worker/       # background order processor
├── tests/            # unit/integration tests
├── scripts/           # bash automation (bootstrap, helpers)
├── docker/            # Dockerfiles + docker-compose
├── k8s/
│   ├── base/           # raw Kubernetes manifests
│   └── helm/            # Helm chart
├── terraform/
│   ├── modules/         # reusable infra modules
│   └── environments/    # dev / prod stacks (remote state per env)
├── .github/workflows/   # CI/CD pipelines
├── monitoring/
│   ├── dashboards/       # Grafana dashboard JSON
│   └── alerts/           # Prometheus alerting rules
└── docs/
    └── postmortems/      # incident write-ups from Phase 7
```
