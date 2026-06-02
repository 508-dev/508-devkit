#!/usr/bin/env sh
set -eu

uv run ruff check apps packages
bun run lint
