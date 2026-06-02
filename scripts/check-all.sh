#!/usr/bin/env sh
set -eu

./scripts/lint.sh
uv run ruff format --check apps packages
./scripts/typecheck.sh
./scripts/test.sh
bun run build
