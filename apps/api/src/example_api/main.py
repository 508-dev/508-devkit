from __future__ import annotations

import uvicorn
from fastapi import FastAPI

from example_shared.schemas import HealthResponse
from example_shared.settings import get_settings


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="508 Devkit API")

    @app.get("/health", response_model=HealthResponse)
    def health() -> HealthResponse:
        return HealthResponse(service=settings.otel_service_name, status="ok")

    return app


def main() -> None:
    uvicorn.run("example_api.main:create_app", factory=True, host="0.0.0.0", port=8720)


if __name__ == "__main__":
    main()
