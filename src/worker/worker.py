"""
Order Worker

Blocks on the Redis queue that the API pushes to, and "processes" each order
(simulated with a sleep for now). Handles SIGTERM/SIGINT gracefully so that
Kubernetes can shut it down cleanly during a rollout in Phase 3, instead of
killing it mid-order.

Exposes Prometheus metrics on :9100/metrics (Phase 6) - orders processed and
processing duration, the counterpart to the API's RED metrics.
"""

import json
import logging
import os
import signal
import time
from types import FrameType
from typing import Optional

import redis
from prometheus_client import Counter, Histogram, start_http_server

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger("order-worker")

REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))
QUEUE_NAME = "orders"
METRICS_PORT = int(os.environ.get("METRICS_PORT", "9100"))

_running = True

ORDERS_PROCESSED = Counter(
    "worker_orders_processed_total", "Total orders processed", ["status"]
)
ORDER_PROCESSING_DURATION = Histogram(
    "worker_order_processing_duration_seconds", "Time spent processing one order"
)


def log_event(event: str, **fields) -> None:
    logger.info(json.dumps({"event": event, **fields}))


def handle_shutdown(signum: int, frame: Optional[FrameType]) -> None:
    global _running
    log_event("shutdown_signal_received", signal=signum)
    _running = False


signal.signal(signal.SIGTERM, handle_shutdown)
signal.signal(signal.SIGINT, handle_shutdown)


def process_order(payload: dict) -> None:
    order_id = payload.get("order_id")
    log_event("processing_order", order_id=order_id, item=payload.get("item"))
    start = time.time()
    try:
        time.sleep(0.5)  # placeholder for real work (charge payment, update DB, etc.)
        log_event("order_completed", order_id=order_id)
        ORDERS_PROCESSED.labels(status="completed").inc()
    except Exception:
        ORDERS_PROCESSED.labels(status="failed").inc()
        raise
    finally:
        ORDER_PROCESSING_DURATION.observe(time.time() - start)


def main() -> None:
    start_http_server(METRICS_PORT)
    r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0, decode_responses=True)
    log_event("worker_started", queue=QUEUE_NAME, metrics_port=METRICS_PORT)

    while _running:
        item = r.blpop(QUEUE_NAME, timeout=2)
        if item is None:
            continue
        _, raw = item
        try:
            payload = json.loads(raw)
            process_order(payload)
        except json.JSONDecodeError:
            log_event("invalid_payload", raw=raw)

    log_event("worker_stopped")


if __name__ == "__main__":
    main()
