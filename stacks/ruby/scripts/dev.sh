#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

eval "$(./scripts/worktree-ports.sh export)"
export WEB_HOST="${WEB_HOST:-127.0.0.1}"
export PORT="${PORT:-$WEB_PORT}"
export RACK_ENV="${RACK_ENV:-development}"
export RAILS_ENV="${RAILS_ENV:-development}"

echo "508 Devkit Ruby stack"
echo "  Web: http://${WEB_HOST}:${PORT}"
echo "  Postgres: 127.0.0.1:${POSTGRES_HOST_PORT}"
echo "  Redis: 127.0.0.1:${REDIS_HOST_PORT}"
echo

if [ -x bin/dev ]; then
  exec bin/dev
fi

if [ -x bin/rails ]; then
  exec bundle exec rails server --binding "$WEB_HOST" --port "$PORT"
fi

if [ -f config.ru ]; then
  exec bundle exec rackup --host "$WEB_HOST" --port "$PORT"
fi

echo "No Ruby dev entrypoint found. Add bin/dev, bin/rails, or config.ru." >&2
exit 1
