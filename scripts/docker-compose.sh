#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  ENV_FILE=".env.example"
fi

PORT_ENV_FILE="$(mktemp)"
trap 'rm -f "$PORT_ENV_FILE"' EXIT HUP INT TERM
python3 scripts/worktree-ports.py env > "$PORT_ENV_FILE"

if [ "$ENV_FILE" = ".env" ]; then
  exec docker compose -f compose.yml --env-file .env.example --env-file "$PORT_ENV_FILE" --env-file .env "$@"
fi

exec docker compose -f compose.yml --env-file .env.example --env-file "$PORT_ENV_FILE" "$@"
