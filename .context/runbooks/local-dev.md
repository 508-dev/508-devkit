# Local Development Runbook

1. Copy `.env.example` to `.env` and fill required secrets.
2. Run `./scripts/worktree-ports.py env` to inspect derived ports.
3. Start local infrastructure with `./scripts/docker-compose.sh up -d`.
4. Start host services with `./scripts/dev.sh`.

When creating sibling worktrees, use `.worktreeinclude` to copy only ignored local config such as `.env` and `.sops.yaml`. Docker build contexts should use `.dockerignore` to exclude secrets, dependencies, caches, and `.context/` scratch state.
5. Run checks with `./scripts/check-all.sh`.

App services should run on the host for reload speed and easier debugging. Docker Compose should own infrastructure such as Postgres, Redis, and optional object storage.
