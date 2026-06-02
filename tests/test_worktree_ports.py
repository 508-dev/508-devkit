from __future__ import annotations

import importlib.util
from pathlib import Path


def load_worktree_ports_module():
    path = Path(__file__).resolve().parents[1] / "scripts" / "worktree-ports.py"
    spec = importlib.util.spec_from_file_location("worktree_ports", path)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_port_block_is_stable_for_same_path() -> None:
    module = load_worktree_ports_module()
    root = Path("/tmp/example-worktree")

    assert module.port_block(root) == module.port_block(root)


def test_ports_for_base_uses_expected_offsets() -> None:
    module = load_worktree_ports_module()

    ports = module.ports_for_base(8700)

    assert ports["API_PORT"] == 8720
    assert ports["WEB_PORT"] == 8730
    assert ports["POSTGRES_HOST_PORT"] == 8740
    assert ports["REDIS_HOST_PORT"] == 8750
    assert ports["MINIO_API_HOST_PORT"] == 8760
    assert ports["OTEL_HTTP_PORT"] == 8780


def test_chrome_safe_port_skips_restricted_ports() -> None:
    module = load_worktree_ports_module()

    assert module.chrome_safe_port(6000) == 6001
    assert module.chrome_safe_port(8730) == 8730
