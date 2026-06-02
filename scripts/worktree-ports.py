#!/usr/bin/env python3
"""Emit stable local development ports for this git worktree."""

from __future__ import annotations

import hashlib
import os
import subprocess
import sys
from pathlib import Path


BASE_PORT = 8700
SPAN = 1000
PORT_BLOCK_SIZE = 100
OFFSETS = {
    "API_PORT": 20,
    "WEB_PORT": 30,
    "WORKER_HEALTH_PORT": 35,
    "POSTGRES_HOST_PORT": 40,
    "REDIS_HOST_PORT": 50,
    "MINIO_API_HOST_PORT": 60,
    "MINIO_CONSOLE_HOST_PORT": 61,
    "OTEL_HTTP_PORT": 80,
}
WEB_RESTRICTED_PORTS = frozenset(
    {
        1,
        7,
        9,
        11,
        13,
        15,
        17,
        19,
        20,
        21,
        22,
        23,
        25,
        37,
        42,
        43,
        53,
        69,
        77,
        79,
        87,
        95,
        101,
        102,
        103,
        104,
        109,
        110,
        111,
        113,
        115,
        117,
        119,
        123,
        135,
        137,
        139,
        143,
        161,
        179,
        389,
        427,
        465,
        512,
        513,
        514,
        515,
        526,
        530,
        531,
        532,
        540,
        548,
        554,
        556,
        563,
        587,
        601,
        636,
        989,
        990,
        993,
        995,
        1719,
        1720,
        1723,
        2049,
        3659,
        4045,
        5060,
        5061,
        6000,
        6566,
        6665,
        6666,
        6667,
        6668,
        6669,
        6697,
        10080,
    }
)


def worktree_root() -> Path:
    try:
        output = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        return Path(output)
    except Exception:
        return Path.cwd().resolve()


def port_block(root: Path) -> int:
    digest = hashlib.sha256(str(root.resolve()).encode("utf-8")).hexdigest()
    return BASE_PORT + ((int(digest[:8], 16) % (SPAN // PORT_BLOCK_SIZE)) * PORT_BLOCK_SIZE)


def chrome_safe_port(port: int) -> int:
    while port in WEB_RESTRICTED_PORTS:
        port += 1
    return port


def ports_for_base(base: int) -> dict[str, int]:
    values = {name: base + offset for name, offset in OFFSETS.items()}
    values["WEB_PORT"] = chrome_safe_port(values["WEB_PORT"])
    values["API_PORT"] = chrome_safe_port(values["API_PORT"])
    return values


def env_values() -> dict[str, str]:
    values = ports_for_base(port_block(worktree_root()))
    postgres = values["POSTGRES_HOST_PORT"]
    redis = values["REDIS_HOST_PORT"]
    api = values["API_PORT"]
    minio = values["MINIO_API_HOST_PORT"]
    env = {name: str(port) for name, port in values.items()}
    env.update(
        {
            "POSTGRES_URL": f"postgresql://app:app@127.0.0.1:{postgres}/app",
            "DATABASE_URL": f"postgresql://app:app@127.0.0.1:{postgres}/app",
            "REDIS_URL": f"redis://127.0.0.1:{redis}/0",
            "MINIO_ENDPOINT": f"http://127.0.0.1:{minio}",
            "WEB_API_BASE_URL": f"http://127.0.0.1:{api}",
            "OTEL_EXPORTER_OTLP_ENDPOINT": f"http://127.0.0.1:{values['OTEL_HTTP_PORT']}",
        }
    )
    return env


def print_env(export: bool = False) -> None:
    for key, value in env_values().items():
        prefix = "export " if export else ""
        print(f"{prefix}{key}={value}")


def run_with_env(args: list[str]) -> int:
    if not args:
        print("usage: worktree-ports.py exec [KEY=VALUE ...] -- <command> [args...]", file=sys.stderr)
        return 2

    env = os.environ.copy()
    env.update(env_values())

    index = 0
    while index < len(args):
        token = args[index]
        if "=" not in token or token.startswith("-"):
            break
        key, value = token.split("=", 1)
        env[key] = value
        index += 1

    if index >= len(args) or args[index] != "--":
        print("usage: worktree-ports.py exec [KEY=VALUE ...] -- <command> [args...]", file=sys.stderr)
        return 2

    command = args[index + 1 :]
    if not command:
        print("usage: worktree-ports.py exec [KEY=VALUE ...] -- <command> [args...]", file=sys.stderr)
        return 2

    return subprocess.run(command, env=env, check=False).returncode


def main() -> int:
    command = sys.argv[1] if len(sys.argv) > 1 else "env"
    if command == "env":
        print_env()
        return 0
    if command == "export":
        print_env(export=True)
        return 0
    if command == "exec":
        return run_with_env(sys.argv[2:])
    print("usage: worktree-ports.py [env|export|exec [KEY=VALUE ...] -- <command>]", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
