#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

eval "$(./scripts/worktree-ports.sh export)"
export WEB_HOST="${WEB_HOST:-127.0.0.1}"

# Root dev runs only language-neutral infra plus the TypeScript convention
# watcher. Runtime-specific services, such as the Python API, live in stacks and
# should be started from their stack scripts when selected for a target repo.
echo "508 Devkit local stack"
echo "Assigned worktree ports:"
./scripts/worktree-ports.sh env | sed 's/^/  /'
echo
echo "Starting services"
echo "  Web: ${WEB_URL} (framework-neutral TypeScript watcher)"
echo "  Postgres: 127.0.0.1:${POSTGRES_HOST_PORT}"
echo "  Redis: 127.0.0.1:${REDIS_HOST_PORT}"
echo

./scripts/docker-compose.sh up -d postgres redis

detect_js_runner() {
  if [ -n "${DEVKIT_JS_RUNNER:-}" ]; then
    printf '%s\n' "$DEVKIT_JS_RUNNER"
    return
  fi

  # Keep the root script usable when a repository chooses the pnpm stack
  # variant. The packageManager field is the strongest signal; lockfiles are a
  # fallback for copied templates where package.json has been edited.
  if grep -Eq '"packageManager"[[:space:]]*:[[:space:]]*"pnpm@' package.json 2>/dev/null; then
    printf '%s\n' pnpm
    return
  fi

  if grep -Eq '"packageManager"[[:space:]]*:[[:space:]]*"bun@' package.json 2>/dev/null; then
    printf '%s\n' bun
    return
  fi

  if [ -f pnpm-lock.yaml ]; then
    printf '%s\n' pnpm
    return
  fi

  printf '%s\n' bun
}

JS_RUNNER="$(detect_js_runner)"

cleanup() {
  if [ -n "${WEB_PID:-}" ]; then kill "$WEB_PID" 2>/dev/null || true; fi
}
trap cleanup INT TERM EXIT

case "$JS_RUNNER" in
  bun)
    bun run --cwd stacks/typescript dev &
    ;;
  pnpm)
    pnpm -C stacks/typescript run dev &
    ;;
  *)
    echo "Unsupported DEVKIT_JS_RUNNER=${JS_RUNNER}; expected bun or pnpm." >&2
    exit 1
    ;;
esac
WEB_PID=$!

wait "$WEB_PID"
