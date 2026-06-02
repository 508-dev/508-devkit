#!/usr/bin/env sh
set -eu

uv run mypy
bun run typecheck
