"""
Order Service API

Exposes:
  POST /order   - accept an order, push it onto the queue for the worker
  GET  /health  - liveness/readiness check (also checks Redis connectivity)
  GET  /metrics - Prometheus metrics (wired up for real in Phase 6)

Logging is structured JSON on purpose - this is what later gets shipped to
whatever log aggregation you use, and it's what makes debugging a distributed
system possible.
"""

import json
import logging
import os
import time
import uuid
from typing import Dict

import redis
from fastapi import FastAPI, HTTPException
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from pydantic import BaseModel
from starlette.responses import Response

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger("order-api")

app = FastAPI(title="Order Service API")

REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))
QUEUE_NAME = "orders"

redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0, decode_responses=True)

# --- Metrics (RED method: Rate, Errors, Duration) ---
REQUEST_COUNT = Counter(
    "api_requests_total", "Total API requests", ["endpoint", "method", "status"]
)
REQUEST_LATENCY = Histogram(
    "api_request_latency_seconds", "Request latency in seconds", ["endpoint"]
)


class OrderRequest(BaseModel):
    item: str
    quantity: int


class OrderResponse(BaseModel):
    order_id: str
    status: str


def log_event(event: str, **fields) -> None:
    logger.info(json.dumps({"event": event, **fields}))


@app.get("/health")
def health() -> Dict[str, str]:
    """Readiness probe target - fails if Redis (our queue) is unreachable."""
    try:
        redis_client.ping()
        return {"status": "ok"}
    except redis.exceptions.ConnectionError as exc:
        log_event("health_check_failed", error=str(exc))
        raise HTTPException(status_code=503, detail="redis unavailable") from exc


@app.get("/metrics")
def metrics() -> Response:
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/order", response_model=OrderResponse)
def create_order(order: OrderRequest) -> OrderResponse:
    start = time.time()
    endpoint = "/order"
    try:
        if order.quantity <= 0:
            REQUEST_COUNT.labels(endpoint=endpoint, method="POST", status="400").inc()
            raise HTTPException(status_code=400, detail="quantity must be positive")

        order_id = str(uuid.uuid4())
        payload = {"order_id": order_id, "item": order.item, "quantity": order.quantity}
        redis_client.rpush(QUEUE_NAME, json.dumps(payload))

        log_event("order_created", order_id=order_id, item=order.item, quantity=order.quantity)
        REQUEST_COUNT.labels(endpoint=endpoint, method="POST", status="200").inc()
        return OrderResponse(order_id=order_id, status="queued")

    except HTTPException:
        raise
    except Exception as exc:
        REQUEST_COUNT.labels(endpoint=endpoint, method="POST", status="500").inc()
        log_event("order_failed", error=str(exc))
        raise HTTPException(status_code=500, detail="failed to queue order") from exc
    finally:
        REQUEST_LATENCY.labels(endpoint=endpoint).observe(time.time() - start)
