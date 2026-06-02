from __future__ import annotations

from example_shared.settings import Settings


def test_worker_settings_default_queue() -> None:
    settings = Settings()

    assert settings.redis_queue_name == "jobs.default"
