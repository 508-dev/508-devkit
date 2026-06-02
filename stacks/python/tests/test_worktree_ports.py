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
    assert ports["OTEL_HTTP_PORT"] == 8780


def test_reserved_block_uses_compact_offsets() -> None:
    module = load_worktree_ports_module()

    ports = module.ports_for_environment({"WORKTREE_PORT_BLOCK_START": "9000"})

    assert ports["WEB_PORT"] == 9000
    assert ports["API_PORT"] == 9001
    assert ports["WORKER_HEALTH_PORT"] == 9002
    assert ports["POSTGRES_HOST_PORT"] == 9003
    assert ports["REDIS_HOST_PORT"] == 9004
    assert ports["OTEL_HTTP_PORT"] == 9005


def test_reserved_block_skips_restricted_ports_without_collisions() -> None:
    module = load_worktree_ports_module()

    ports = module.ports_for_environment({"WORKTREE_PORT_BLOCK_START": "6000"})

    assert ports["WEB_PORT"] == 6001
    assert ports["API_PORT"] == 6002
    assert len(set(ports.values())) == len(ports)


def test_primary_port_can_target_api() -> None:
    module = load_worktree_ports_module()

    ports = module.ports_for_environment(
        {
            "WORKTREE_PRIMARY_PORT": "9100",
            "WORKTREE_PRIMARY_PORT_TARGET": "API_PORT",
        },
        root=Path("/tmp/example-worktree"),
    )

    assert ports["API_PORT"] == 9100


def test_primary_port_collision_raises_clear_error() -> None:
    module = load_worktree_ports_module()

    try:
        module.ports_for_environment(
            {
                "WORKTREE_PORT_BLOCK_START": "9000",
                "WORKTREE_PRIMARY_PORT": "9000",
                "WORKTREE_PRIMARY_PORT_TARGET": "API_PORT",
            }
        )
    except ValueError as error:
        assert "duplicate port 9000" in str(error)
    else:
        raise AssertionError("expected duplicate primary port to fail")


def test_chrome_safe_port_skips_restricted_ports() -> None:
    module = load_worktree_ports_module()

    assert module.chrome_safe_port(6000) == 6001
    assert module.chrome_safe_port(8730) == 8730
