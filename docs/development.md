# Development

Local development follows the pattern used across existing projects:

- Docker Compose owns infrastructure.
- App services run on the host.
- Ports are deterministic per worktree.

## Commands

```bash
./scripts/worktree-ports.py env
./scripts/docker-compose.sh up -d postgres redis
./scripts/dev.sh
```

## Worktree Includes

Use `.worktreeinclude` to allowlist ignored local files that should be copied into new sibling worktrees.

Example:

```text
.env
.env.local
.env.development.local
.sops.yaml
```

Do not include generated state such as `.venv`, `node_modules`, caches, local databases, screenshots, or raw logs. Those should be recreated per worktree.

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
