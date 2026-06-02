#!/usr/bin/env sh
set -eu

uv run ruff check apps packages tests
bun run lint
