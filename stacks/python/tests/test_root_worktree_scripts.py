from __future__ import annotations

import os
import stat
import subprocess
from pathlib import Path

DEVKIT_ROOT = Path(__file__).resolve().parents[3]


def _run(
    command: list[str],
    *,
    cwd: Path,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )


def _env_output(stdout: str) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in stdout.splitlines():
        key, _, value = line.partition("=")
        values[key] = value
    return values


def _fake_docker(tmp_path: Path, body: str) -> Path:
    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()
    docker = fake_bin / "docker"
    docker.write_text(body, encoding="utf-8")
    docker.chmod(docker.stat().st_mode | stat.S_IXUSR)
    return fake_bin


def test_shell_worktree_ports_canonicalizes_symlinked_git_root(
    tmp_path: Path,
) -> None:
    alias_root = tmp_path / "devkit-alias"
    alias_root.symlink_to(DEVKIT_ROOT, target_is_directory=True)

    real = _run(
        [str(DEVKIT_ROOT / "scripts" / "worktree-ports.sh"), "env"],
        cwd=DEVKIT_ROOT,
    )
    alias = _run(
        [str(alias_root / "scripts" / "worktree-ports.sh"), "env"],
        cwd=alias_root,
    )

    real_env = _env_output(real.stdout)
    alias_env = _env_output(alias.stdout)

    assert alias_env["COMPOSE_PROJECT_NAME"] == real_env["COMPOSE_PROJECT_NAME"]
    assert alias_env["POSTGRES_HOST_PORT"] == real_env["POSTGRES_HOST_PORT"]
    assert alias_env["REDIS_HOST_PORT"] == real_env["REDIS_HOST_PORT"]


def test_docker_compose_wrapper_exports_canonical_project_for_symlink(
    tmp_path: Path,
) -> None:
    alias_root = tmp_path / "devkit-alias"
    alias_root.symlink_to(DEVKIT_ROOT, target_is_directory=True)
    fake_bin = _fake_docker(
        tmp_path,
        """#!/bin/sh
if [ "$1" = "compose" ]; then
  printf '%s\\n' "$COMPOSE_PROJECT_NAME"
  exit 0
fi
exit 2
""",
    )
    env = os.environ.copy()
    env["PATH"] = f"{fake_bin}:{env['PATH']}"

    real = _run(
        [str(DEVKIT_ROOT / "scripts" / "docker-compose.sh"), "config"],
        cwd=tmp_path,
        env=env,
    )
    alias = _run(
        [str(alias_root / "scripts" / "docker-compose.sh"), "config"],
        cwd=tmp_path,
        env=env,
    )

    assert alias.stdout == real.stdout


def test_docker_compose_wrapper_reclaims_only_same_realpath_stale_containers(
    tmp_path: Path,
) -> None:
    alias_root = tmp_path / "devkit-alias"
    alias_root.symlink_to(DEVKIT_ROOT, target_is_directory=True)
    sibling_root = tmp_path / "sibling-worktree"
    sibling_root.mkdir()
    log_path = tmp_path / "docker.log"
    fake_bin = _fake_docker(
        tmp_path,
        """#!/bin/sh
if [ "$1" = "ps" ]; then
  printf '%s\\n' "$FAKE_DOCKER_PS"
  exit 0
fi
if [ "$1" = "rm" ]; then
  printf 'rm %s\\n' "$*" >> "$FAKE_DOCKER_LOG"
  exit 0
fi
if [ "$1" = "compose" ]; then
  printf 'compose %s\\n' "$COMPOSE_PROJECT_NAME" >> "$FAKE_DOCKER_LOG"
  exit 0
fi
exit 2
""",
    )
    env = os.environ.copy()
    env["PATH"] = f"{fake_bin}:{env['PATH']}"
    env["FAKE_DOCKER_LOG"] = str(log_path)
    env["FAKE_DOCKER_PS"] = "\n".join(
        [
            f"same-port\told-project\t{alias_root}\t127.0.0.1:9540->5432/tcp\told-postgres",
            f"same-helper\told-project\t{alias_root}\t\told-init",
            f"sibling-port\told-project\t{sibling_root}\t127.0.0.1:9540->5432/tcp\tsibling-postgres",
        ]
    )

    _run(
        [str(alias_root / "scripts" / "docker-compose.sh"), "up", "-d", "postgres"],
        cwd=tmp_path,
        env=env,
    )

    log = log_path.read_text(encoding="utf-8")
    assert "same-port" in log
    assert "same-helper" not in log
    assert "sibling-port" not in log
