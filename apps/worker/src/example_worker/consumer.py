from __future__ import annotations

import time

from example_shared.settings import get_settings


def main() -> None:
    settings = get_settings()
    print(f"worker ready queue={settings.redis_queue_name}")
    while True:
        time.sleep(60)
