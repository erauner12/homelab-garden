#!/usr/bin/env python3
"""Tiny lab-safe demo API for delivery and observability exercises."""

from __future__ import annotations

import json
import os
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Lock
from typing import Any
from urllib.parse import parse_qs, urlparse

APP_NAME = "demo-api"
DEFAULT_TEXT = "homelab-garden demo-api ok"
VERSION = os.environ.get("DEMO_API_VERSION", "0.1.0")
MAX_LATENCY_MS = 2000
DEFAULT_LATENCY_MS = 250
MODES = ("healthy", "degraded", "failing", "latency")
BUCKETS = (0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0)


class AppState:
    def __init__(self) -> None:
        self.lock = Lock()
        self.mode = "healthy"
        self.latency_ms = 0
        self.requests: dict[tuple[str, str, int], int] = {}
        self.error_total = 0
        self.duration_buckets = {bucket: 0 for bucket in BUCKETS}
        self.duration_count = 0
        self.duration_sum = 0.0

    def snapshot(self) -> dict[str, Any]:
        with self.lock:
            return {"mode": self.mode, "latency_ms": self.latency_ms}

    def configure(self, mode: str, latency_ms: int | None = None) -> dict[str, Any]:
        if mode not in MODES:
            raise ValueError(f"mode must be one of {', '.join(MODES)}")
        if mode == "latency":
            if latency_ms is None:
                latency_ms = DEFAULT_LATENCY_MS
            latency_ms = max(0, min(MAX_LATENCY_MS, latency_ms))
        else:
            latency_ms = 0
        with self.lock:
            self.mode = mode
            self.latency_ms = latency_ms
            return {"mode": self.mode, "latency_ms": self.latency_ms}

    def reset(self) -> dict[str, Any]:
        return self.configure("healthy", 0)

    def record(self, method: str, path: str, status: int, duration: float) -> None:
        with self.lock:
            self.requests[(method, path, status)] = self.requests.get((method, path, status), 0) + 1
            if status >= 500:
                self.error_total += 1
            self.duration_count += 1
            self.duration_sum += duration
            for bucket in BUCKETS:
                if duration <= bucket:
                    self.duration_buckets[bucket] += 1

    def metrics(self) -> str:
        with self.lock:
            lines = [
                "# HELP demo_api_requests_total HTTP requests by method, path, and response code.",
                "# TYPE demo_api_requests_total counter",
            ]
            for (method, path, status), count in sorted(self.requests.items()):
                lines.append(
                    f'demo_api_requests_total{{method="{method}",path="{path}",code="{status}"}} {count}'
                )
            lines.extend(
                [
                    "# HELP demo_api_errors_total HTTP 5xx responses.",
                    "# TYPE demo_api_errors_total counter",
                    f"demo_api_errors_total {self.error_total}",
                    "# HELP demo_api_request_duration_seconds HTTP request duration histogram.",
                    "# TYPE demo_api_request_duration_seconds histogram",
                ]
            )
            for bucket in BUCKETS:
                lines.append(f'demo_api_request_duration_seconds_bucket{{le="{bucket:g}"}} {self.duration_buckets[bucket]}')
            lines.append(f'demo_api_request_duration_seconds_bucket{{le="+Inf"}} {self.duration_count}')
            lines.append(f"demo_api_request_duration_seconds_sum {self.duration_sum:.6f}")
            lines.append(f"demo_api_request_duration_seconds_count {self.duration_count}")
            lines.extend(
                [
                    "# HELP demo_api_simulation_mode Active simulation mode; active mode is 1, others are 0.",
                    "# TYPE demo_api_simulation_mode gauge",
                ]
            )
            for mode in MODES:
                value = 1 if mode == self.mode else 0
                lines.append(f'demo_api_simulation_mode{{mode="{mode}"}} {value}')
            lines.extend(
                [
                    "# HELP demo_api_simulation_latency_ms Configured latency injection in milliseconds.",
                    "# TYPE demo_api_simulation_latency_ms gauge",
                    f"demo_api_simulation_latency_ms {self.latency_ms}",
                ]
            )
        return "\n".join(lines) + "\n"


def json_body(payload: dict[str, Any]) -> bytes:
    return (json.dumps(payload, sort_keys=True) + "\n").encode("utf-8")


def simulation_delay(state: AppState) -> None:
    snapshot = state.snapshot()
    if snapshot["mode"] == "latency" and snapshot["latency_ms"] > 0:
        time.sleep(snapshot["latency_ms"] / 1000)


def make_handler(state: AppState) -> type[BaseHTTPRequestHandler]:
    class DemoAPIHandler(BaseHTTPRequestHandler):
        server_version = "demo-api/" + VERSION

        def do_GET(self) -> None:  # noqa: N802 - stdlib handler API
            self._handle("GET")

        def do_POST(self) -> None:  # noqa: N802 - stdlib handler API
            self._handle("POST")

        def log_message(self, fmt: str, *args: Any) -> None:
            print(f"{self.address_string()} - {fmt % args}", flush=True)

        def _handle(self, method: str) -> None:
            started = time.monotonic()
            parsed = urlparse(self.path)
            path = parsed.path
            status = 404
            content_type = "text/plain; charset=utf-8"
            body = b"not found\n"
            try:
                status, content_type, body = self._route(method, path, parsed.query)
            except ValueError as err:
                status = 400
                content_type = "application/json"
                body = json_body({"error": str(err)})
            except Exception as err:  # pragma: no cover - defensive handler boundary
                status = 500
                content_type = "application/json"
                body = json_body({"error": "internal server error", "detail": err.__class__.__name__})
            duration = time.monotonic() - started
            state.record(method, path, status, duration)
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _route(self, method: str, path: str, query: str) -> tuple[int, str, bytes]:
            if method == "GET" and path == "/":
                simulation_delay(state)
                snapshot = state.snapshot()
                if snapshot["mode"] == "failing":
                    return 503, "text/plain; charset=utf-8", b"homelab-garden demo-api failing\n"
                if snapshot["mode"] == "degraded":
                    return 200, "text/plain; charset=utf-8", b"homelab-garden demo-api degraded\n"
                return 200, "text/plain; charset=utf-8", (DEFAULT_TEXT + "\n").encode("utf-8")

            if method == "GET" and path == "/healthz":
                simulation_delay(state)
                snapshot = state.snapshot()
                if snapshot["mode"] == "failing":
                    return 500, "application/json", json_body({"status": "failing", "healthy": False, **snapshot})
                status = "degraded" if snapshot["mode"] == "degraded" else "ok"
                return 200, "application/json", json_body({"status": status, "healthy": True, **snapshot})

            if method == "GET" and path == "/readyz":
                simulation_delay(state)
                snapshot = state.snapshot()
                if snapshot["mode"] == "failing":
                    return 503, "application/json", json_body({"status": "not_ready", "ready": False, **snapshot})
                status = "degraded" if snapshot["mode"] == "degraded" else "ready"
                return 200, "application/json", json_body({"status": status, "ready": True, **snapshot})

            if method == "GET" and path == "/version":
                return 200, "application/json", json_body({"app": APP_NAME, "version": VERSION})

            if method == "GET" and path == "/metrics":
                return 200, "text/plain; version=0.0.4; charset=utf-8", state.metrics().encode("utf-8")

            if method == "GET" and path == "/simulate":
                return 200, "application/json", json_body(state.snapshot())

            if method == "POST" and path == "/simulate/reset":
                return 200, "application/json", json_body({"status": "reset", **state.reset()})

            if method == "POST" and path == "/simulate":
                params = parse_qs(query)
                length = int(self.headers.get("Content-Length", "0") or 0)
                if length:
                    body_params = parse_qs(self.rfile.read(length).decode("utf-8"))
                    params.update(body_params)
                mode = params.get("mode", [""])[0]
                if mode == "reset":
                    return 200, "application/json", json_body({"status": "reset", **state.reset()})
                latency_ms = None
                if "latency_ms" in params:
                    latency_ms = int(params["latency_ms"][0])
                configured = state.configure(mode, latency_ms)
                return 200, "application/json", json_body({"status": "configured", **configured})

            return 404, "text/plain; charset=utf-8", b"not found\n"

    return DemoAPIHandler


def serve() -> None:
    port = int(os.environ.get("PORT", "8080"))
    state = AppState()
    server = ThreadingHTTPServer(("0.0.0.0", port), make_handler(state))
    print(f"demo-api listening on :{port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    serve()
