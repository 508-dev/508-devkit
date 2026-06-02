#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  ENV_FILE=".env.example"
fi

eval "$(python3 scripts/worktree-ports.py export)"

exec docker compose -f compose.yml --env-file "$ENV_FILE" "$@"
