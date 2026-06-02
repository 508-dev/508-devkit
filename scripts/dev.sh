#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

eval "$(python3 scripts/worktree-ports.py export)"
export API_HOST="${API_HOST:-127.0.0.1}"
export WEB_HOST="${WEB_HOST:-127.0.0.1}"
export PYTHONPATH="${PYTHONPATH:-apps/api/src:packages/shared/src}"

echo "508 Devkit local stack"
echo "  API: http://${API_HOST}:${API_PORT}"
echo "  Web: framework-neutral TypeScript watcher; reserve WEB_PORT=${WEB_PORT} for your chosen web framework"
echo "  Postgres: 127.0.0.1:${POSTGRES_HOST_PORT}"
echo "  Redis: 127.0.0.1:${REDIS_HOST_PORT}"
echo

./scripts/docker-compose.sh up -d postgres redis

cleanup() {
  if [ -n "${API_PID:-}" ]; then kill "$API_PID" 2>/dev/null || true; fi
  if [ -n "${WEB_PID:-}" ]; then kill "$WEB_PID" 2>/dev/null || true; fi
}
trap cleanup INT TERM EXIT

uv run --package example-api uvicorn example_api.main:create_app \
  --factory \
  --host "$API_HOST" \
  --port "$API_PORT" \
  --reload \
  --reload-dir apps/api/src \
  --reload-dir packages/shared/src &
API_PID=$!

bun run --cwd apps/web dev &
WEB_PID=$!

wait "$API_PID" "$WEB_PID"
