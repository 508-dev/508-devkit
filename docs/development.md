# Development

Local development follows the pattern used across existing projects:

- Docker Compose owns infrastructure.
- App services run on the host.
- Ports are deterministic per worktree.

## Commands

```bash
./scripts/worktree-ports.sh env
./scripts/docker-compose.sh up -d postgres redis
./scripts/dev.sh
./scripts/check-all.sh
```

`worktree-ports.sh env` prints `WEB_URL` first, then `WEB_PORT`, then the
remaining assigned ports and derived connection strings. Keep that order when
adapting the helper so coding workspace tools discover the web surface before
API or infrastructure URLs.

## Worktree Port Reservations

`scripts/worktree-ports.sh` normally hashes the absolute git worktree path and
derives stable local ports from that hash. Some agent/worktree orchestrators
reserve ports for each workspace. Keep product-specific environment variable
names out of the helper and map them to these generic names in the run command
or wrapper script:

- `WORKTREE_PORT_BLOCK_START`: first port in a reserved block.
- `WORKTREE_PORT_BLOCK_SIZE`: size of the reserved block, default `10`.
- `WORKTREE_PRIMARY_PORT`: one reserved public port.
- `WORKTREE_PRIMARY_PORT_TARGET`: `WEB_PORT` or `API_PORT`, default `WEB_PORT`.

When a block is present, the helper uses compact offsets inside it for web, API,
worker health, database, cache, and OTEL example ports. When only one public port
is present, the helper assigns it to the selected primary target and keeps other
ports on the normal deterministic worktree allocation.

## Worktree Includes

Use `.worktreeinclude` to allowlist ignored local files that should be copied into new sibling worktrees. Treat entries as gitignore-style path patterns, not shell globs passed directly to `cp`.

Example:

```text
.env
.env.local
.env.development.local
.sops.yaml
```

Do not include generated state such as `.venv`, `node_modules`, caches, local databases, screenshots, or raw logs. Those should be recreated per worktree.

## Workspace Context

Do not commit `.context/`. Conductor creates it as workspace-local scratch for
agents. Durable runbooks and decisions belong in tracked docs such as this file,
`docs/tooling.md`, and `docs/pattern-report.md`.

## Docker Build Contexts

Keep `.dockerignore` in every repo that has Dockerfiles or Compose services. Exclude local secrets, dependency directories, caches, agent scratch state, and build outputs so Docker does not upload large or sensitive files into the build context.

Example:

```text
.git
.context
.env
.env.*
!.env.example
.venv
node_modules
**/node_modules
__pycache__
.pytest_cache
.mypy_cache
.ruff_cache
dist
build
```

## Why Host-Run Services

Host-run app services are faster for reload loops, easier for agents to inspect, and avoid rebuilding containers for normal code changes.

Use full-container Compose only when validating deployment parity.

## Agent Notes

- Keep root scripts as stable entrypoints. Change package-manager internals
  behind them when adapting a target repo.
- Use `./scripts/worktree-ports.sh env` before debugging port conflicts.
- Copy ignored local config through `.worktreeinclude`; do not commit copied
  `.env` files or generated workspace state.
