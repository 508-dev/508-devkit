#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."
WORKTREE_ROOT="$(pwd -P)"
cd "$WORKTREE_ROOT"

# Prefer developer-provided .env values, but keep .env.example as the baseline
# so Compose validation works before a local .env exists.
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  ENV_FILE=".env.example"
fi

load_port_reservations() {
  file="$1"
  if [ ! -f "$file" ]; then
    return 0
  fi

  # Read only the reservation inputs consumed by worktree-ports.sh. Avoid
  # sourcing the whole .env file because local env files are configuration, not
  # shell scripts.
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      WORKTREE_PORT_BLOCK_START=*|WORKTREE_PORT_BLOCK_SIZE=*|WORKTREE_PRIMARY_PORT=*|WORKTREE_PRIMARY_PORT_TARGET=*)
        key="${line%%=*}"
        value="${line#*=}"
        case "$value" in
          \"*\") value="${value#\"}"; value="${value%\"}" ;;
          \'*\') value="${value#\'}"; value="${value%\'}" ;;
        esac
        export "$key=$value"
        ;;
    esac
  done < "$file"
}

load_port_reservations "$ENV_FILE"

eval "$(./scripts/worktree-ports.sh export)"

PORT_ENV_FILE="$(mktemp)"
trap 'rm -f "$PORT_ENV_FILE"' EXIT HUP INT TERM
./scripts/worktree-ports.sh env > "$PORT_ENV_FILE"

reclaim_same_worktree_compose_containers() {
  command -v docker >/dev/null 2>&1 || return 0

  infra_ports=" ${POSTGRES_HOST_PORT} ${REDIS_HOST_PORT} "
  publishes_assigned_port() {
    port_list=$1
    for port in $infra_ports; do
      case "$port_list" in
        *":${port}->"*) return 0 ;;
      esac
    done
    return 1
  }

  compose_containers=$(
    docker ps -a \
      --format '{{.ID}}\t{{.Label "com.docker.compose.project"}}\t{{.Label "com.docker.compose.project.working_dir"}}\t{{.Ports}}\t{{.Names}}'
  )
  stale_containers=$(
    printf '%s\n' "$compose_containers" | while IFS="$(printf '\t')" read -r container_id project_name working_dir port_list container_name; do
      if [ "$project_name" = "$COMPOSE_PROJECT_NAME" ] || [ -z "$working_dir" ] || [ ! -d "$working_dir" ]; then
        continue
      fi

      working_dir_realpath=$(CDPATH= cd "$working_dir" 2>/dev/null && pwd -P)
      if [ "$working_dir_realpath" != "$WORKTREE_ROOT" ]; then
        continue
      fi

      if ! publishes_assigned_port "$port_list"; then
        continue
      fi

      printf '%s\t%s\t%s\t%s\n' "$container_id" "$project_name" "$container_name" "$working_dir"
    done
  )

  if [ -z "$stale_containers" ]; then
    return 0
  fi

  echo "Reclaiming stale same-worktree Docker Compose containers:"
  printf '%s\n' "$stale_containers" | while IFS="$(printf '\t')" read -r _container_id project_name container_name working_dir; do
    printf '  %s (%s, %s)\n' "$container_name" "$project_name" "$working_dir"
  done

  # Only stale same-realpath containers that publish this worktree's assigned
  # infra ports are reclaimed. One-shot helper containers without host ports are
  # harmless and are left alone.
  docker rm -f $(printf '%s\n' "$stale_containers" | awk '{ print $1 }') >/dev/null
}

case "${1:-}" in
  up)
    reclaim_same_worktree_compose_containers
    ;;
esac

# Env-file order is significant: examples provide defaults, generated ports
# make sibling worktrees safe, and .env has final local override authority.
if [ "$ENV_FILE" = ".env" ]; then
  exec docker compose -f compose.yml --env-file .env.example --env-file "$PORT_ENV_FILE" --env-file .env "$@"
fi

exec docker compose -f compose.yml --env-file .env.example --env-file "$PORT_ENV_FILE" "$@"
