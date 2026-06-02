#!/usr/bin/env sh
set -eu

uv run ruff format apps packages tests
bun run format
