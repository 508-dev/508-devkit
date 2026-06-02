#!/usr/bin/env sh
set -eu

uv run pytest
bun run test
