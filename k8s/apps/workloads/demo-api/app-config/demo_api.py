#!/usr/bin/env python3
"""Tiny lab-safe demo API for delivery and observability exercises."""

from __future__ import annotations

import json
import os
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any
from urllib.parse import parse_qs, urlparse

DEFAULT_TEXT = "homelab-garden demo-api ok"
VERSION = os.environ.get("DEMO_API_VERSION", "0.1.0")
MAX_LATENCY_MS = 2000
DEFAULT_LATENCY_MS = 250
MODES = ("healthy", "degraded", "failing", "latency")


class AppState:
    def __init__(self) -> None:
        self.mode = "healthy"
        self.latency_ms = 0
        self.request_total = 0
        self.error_total = 0
        self.duration_count = 0
        self.duration_sum = 0.0

    def snapshot(self) -> dict[str, Any]:
        return {"mode": self.mode, "latency_ms": self.latency_ms}

    def configure(self, mode: str, latency_ms: int | None = None) -> dict[str, Any]:
        if mode not in MODES:
            raise ValueError(f"mode must be one of {', '.join(MODES)}")
        self.mode = mode
        self.latency_ms = max(0, min(MAX_LATENCY_MS, latency_ms or DEFAULT_LATENCY_MS)) if mode == "latency" else 0
        return self.snapshot()

    def reset(self) -> dict[str, Any]:
        return self.configure("healthy", 0)

    def record(self, status: int, duration: float) -> None:
        self.request_total += 1
        if status >= 500:
            self.error_total += 1
        self.duration_count += 1
        self.duration_sum += duration

    def metrics(self) -> str:
        lines = [
            "# TYPE demo_api_requests_total counter",
            f"demo_api_requests_total {self.request_total}",
            "# TYPE demo_api_errors_total counter",
            f"demo_api_errors_total {self.error_total}",
            "# TYPE demo_api_request_duration_seconds summary",
            f"demo_api_request_duration_seconds_count {self.duration_count}",
            f"demo_api_request_duration_seconds_sum {self.duration_sum:.6f}",
            "# TYPE demo_api_simulation_mode gauge",
        ]
        lines.extend(f'demo_api_simulation_mode{{mode="{mode}"}} {1 if mode == self.mode else 0}' for mode in MODES)
        lines.extend(
            [
                "# TYPE demo_api_simulation_latency_ms gauge",
                f"demo_api_simulation_latency_ms {self.latency_ms}",
            ]
        )
        return "\n".join(lines) + "\n"


def json_body(payload: dict[str, Any]) -> bytes:
    return (json.dumps(payload, sort_keys=True) + "\n").encode("utf-8")


def simulation_delay(state: AppState) -> None:
    if state.mode == "latency" and state.latency_ms > 0:
        time.sleep(state.latency_ms / 1000)


def make_handler(state: AppState) -> type[BaseHTTPRequestHandler]:
    class DemoAPIHandler(BaseHTTPRequestHandler):
        def do_GET(self) -> None:  # noqa: N802 - stdlib handler API
            self._handle("GET")

        def do_POST(self) -> None:  # noqa: N802 - stdlib handler API
            self._handle("POST")

        def _handle(self, method: str) -> None:
            started = time.monotonic()
            parsed = urlparse(self.path)
            try:
                status, content_type, body = self._route(method, parsed.path, parsed.query)
            except ValueError as err:
                status, content_type, body = 400, "application/json", json_body({"error": str(err)})
            state.record(status, time.monotonic() - started)
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _route(self, method: str, path: str, query: str) -> tuple[int, str, bytes]:
            if method == "GET" and path == "/":
                simulation_delay(state)
                if state.mode == "failing":
                    return 503, "text/plain; charset=utf-8", b"homelab-garden demo-api failing\n"
                if state.mode == "degraded":
                    return 200, "text/plain; charset=utf-8", b"homelab-garden demo-api degraded\n"
                return 200, "text/plain; charset=utf-8", (DEFAULT_TEXT + "\n").encode("utf-8")

            if method == "GET" and path == "/healthz":
                simulation_delay(state)
                if state.mode == "failing":
                    return 500, "application/json", json_body({"status": "failing", "healthy": False, **state.snapshot()})
                status = "degraded" if state.mode == "degraded" else "ok"
                return 200, "application/json", json_body({"status": status, "healthy": True, **state.snapshot()})

            if method == "GET" and path == "/readyz":
                simulation_delay(state)
                if state.mode == "failing":
                    return 503, "application/json", json_body({"status": "not_ready", "ready": False, **state.snapshot()})
                status = "degraded" if state.mode == "degraded" else "ready"
                return 200, "application/json", json_body({"status": status, "ready": True, **state.snapshot()})

            if method == "GET" and path == "/version":
                return 200, "application/json", json_body({"app": "demo-api", "version": VERSION})

            if method == "GET" and path == "/metrics":
                return 200, "text/plain; version=0.0.4; charset=utf-8", state.metrics().encode("utf-8")

            if method == "POST" and path == "/simulate/reset":
                return 200, "application/json", json_body({"status": "reset", **state.reset()})

            if method == "POST" and path == "/simulate":
                params = parse_qs(query)
                mode = params.get("mode", [""])[0]
                latency_ms = int(params["latency_ms"][0]) if "latency_ms" in params else None
                return 200, "application/json", json_body({"status": "configured", **state.configure(mode, latency_ms)})

            return 404, "text/plain; charset=utf-8", b"not found\n"

    return DemoAPIHandler


def serve() -> None:
    port = int(os.environ.get("PORT", "8080"))
    server = HTTPServer(("0.0.0.0", port), make_handler(AppState()))
    print(f"demo-api listening on :{port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    serve()
