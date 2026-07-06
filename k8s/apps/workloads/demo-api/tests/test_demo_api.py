import importlib.util
import json
import pathlib
import sys
import threading
import time
from http.server import HTTPServer
from urllib.error import HTTPError
from urllib.request import Request, urlopen

import pytest

sys.dont_write_bytecode = True

APP_PATH = pathlib.Path(__file__).resolve().parents[1] / "app-config/demo_api.py"
spec = importlib.util.spec_from_file_location("demo_api", APP_PATH)
demo_api = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(demo_api)


@pytest.fixture
def base_url():
    server = HTTPServer(("127.0.0.1", 0), demo_api.make_handler(demo_api.AppState()))
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield f"http://127.0.0.1:{server.server_address[1]}"
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)


def get(base_url, path):
    with urlopen(base_url + path, timeout=2) as response:
        return response.status, response.headers.get_content_type(), response.read().decode("utf-8")


def post(base_url, path):
    request = Request(base_url + path, method="POST")
    with urlopen(request, timeout=2) as response:
        return response.status, response.headers.get_content_type(), response.read().decode("utf-8")


def http_error(base_url, path, code, method="GET"):
    request = Request(base_url + path, method=method)
    with pytest.raises(HTTPError) as exc_info:
        urlopen(request, timeout=2)
    err = exc_info.value
    assert err.code == code
    body = err.read().decode("utf-8")
    err.close()
    return body


def test_default_observability_endpoints(base_url):
    status, content_type, body = get(base_url, "/")
    assert status == 200
    assert content_type == "text/plain"
    assert body == "homelab-garden demo-api ok\n"

    status, content_type, body = get(base_url, "/healthz")
    assert status == 200
    assert content_type == "application/json"
    assert json.loads(body)["status"] == "ok"

    status, _, body = get(base_url, "/readyz")
    assert status == 200
    assert json.loads(body)["ready"] is True

    status, _, body = get(base_url, "/version")
    assert status == 200
    assert json.loads(body)["app"] == "demo-api"

    status, content_type, body = get(base_url, "/metrics")
    assert status == 200
    assert content_type == "text/plain"
    assert "demo_api_requests_total" in body
    assert "demo_api_errors_total" in body
    assert "demo_api_request_duration_seconds_count" in body
    assert 'demo_api_simulation_mode{mode="healthy"} 1' in body


def test_degraded_failing_latency_and_reset_modes(base_url):
    status, _, body = post(base_url, "/simulate?mode=degraded")
    assert status == 200
    assert json.loads(body)["mode"] == "degraded"
    _, _, body = get(base_url, "/healthz")
    assert json.loads(body)["status"] == "degraded"

    status, _, body = post(base_url, "/simulate?mode=failing")
    assert status == 200
    assert json.loads(body)["mode"] == "failing"
    assert "failing" in http_error(base_url, "/healthz", 500)
    assert "not_ready" in http_error(base_url, "/readyz", 503)
    assert "failing" in http_error(base_url, "/", 503)
    _, _, metrics = get(base_url, "/metrics")
    assert 'demo_api_simulation_mode{mode="failing"} 1' in metrics

    status, _, body = post(base_url, "/simulate?mode=latency&latency_ms=25")
    assert status == 200
    assert json.loads(body)["latency_ms"] == 25
    started = time.monotonic()
    status, _, _ = get(base_url, "/readyz")
    assert status == 200
    assert time.monotonic() - started >= 0.02

    status, _, body = post(base_url, "/simulate/reset")
    assert status == 200
    assert json.loads(body)["mode"] == "healthy"
    _, _, body = get(base_url, "/")
    assert body == "homelab-garden demo-api ok\n"


def test_latency_is_bounded_and_invalid_modes_are_rejected(base_url):
    status, _, body = post(base_url, "/simulate?mode=latency&latency_ms=999999")
    assert status == 200
    assert json.loads(body)["latency_ms"] == demo_api.MAX_LATENCY_MS

    request = Request(base_url + "/simulate?mode=surprise", method="POST")
    with pytest.raises(HTTPError) as exc_info:
        urlopen(request, timeout=2)
    err = exc_info.value
    assert err.code == 400
    err.close()

    assert "mode must be" in http_error(base_url, "/simulate?mode=reset", 400, method="POST")
