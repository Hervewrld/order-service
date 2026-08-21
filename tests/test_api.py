"""
Tests for the Order API.

We swap in fakeredis instead of a real Redis instance so these run fast and
don't need any infrastructure - the point of Phase 0 is a solid, testable
app before we start containerizing or deploying anything.
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src", "api"))

import fakeredis  # noqa: E402
import app as api_app  # noqa: E402

api_app.redis_client = fakeredis.FakeStrictRedis(decode_responses=True)

from fastapi.testclient import TestClient  # noqa: E402

client = TestClient(api_app.app)


def test_health_ok():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_create_order_success():
    resp = client.post("/order", json={"item": "widget", "quantity": 3})
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "queued"
    assert "order_id" in body


def test_create_order_pushes_to_queue():
    api_app.redis_client.delete(api_app.QUEUE_NAME)
    client.post("/order", json={"item": "gadget", "quantity": 1})
    assert api_app.redis_client.llen(api_app.QUEUE_NAME) == 1


def test_create_order_rejects_non_positive_quantity():
    resp = client.post("/order", json={"item": "widget", "quantity": 0})
    assert resp.status_code == 400


def test_metrics_endpoint_exposes_counters():
    resp = client.get("/metrics")
    assert resp.status_code == 200
    assert b"api_requests_total" in resp.content
