from __future__ import annotations

from functools import lru_cache

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    environment: str = "local"
    log_level: str = "INFO"

    api_shared_secret: SecretStr | None = None

    postgres_url: str = "postgresql://app:app@127.0.0.1:8740/app"
    database_url: str = "postgresql://app:app@127.0.0.1:8740/app"
    redis_url: str = "redis://127.0.0.1:8750/0"
    redis_queue_name: str = "jobs.default"

    sentry_dsn: str | None = None
    otel_exporter_otlp_endpoint: str | None = None
    otel_service_name: str = "508-devkit"

    openai_api_key: SecretStr | None = None
    openai_base_url: str = "https://api.openai.com/v1"
    openai_model: str = Field(default="gpt-4.1-mini")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
