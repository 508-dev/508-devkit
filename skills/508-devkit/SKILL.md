# 508 Devkit

Use this skill when creating or normalizing a 508.dev repository.

## Workflow

1. Inspect the target repo first:
   - `AGENTS.md`, `CLAUDE.md`, Cursor rules.
   - `pyproject.toml`, `uv.lock`.
   - `package.json`, `bun.lock`, `pnpm-lock.yaml`, `bunfig.toml`, `pnpm-workspace.yaml`.
   - Compose files.
   - `.github/workflows`.
   - `.env.example`.
   - `scripts/`.
2. Decide which devkit pieces apply:
   - Bun default for new JS projects.
   - pnpm alternate for large JS workspaces.
   - Python `uv` workspace when backend, worker, or scripts exist.
   - Docker Compose for Postgres/Redis infra.
   - Worktree ports for local parallel worktrees.
   - `.worktreeinclude` for ignored local config copied into sibling worktrees.
   - `.dockerignore` for small, secret-safe Docker build contexts.
   - Pydantic settings and Alembic for Python service data.
   - Drizzle for TypeScript service data.
   - Optional SOPS only when encrypted repo files are needed.
3. Copy or adapt files from the `508-devkit` repository.
4. Update names, package scopes, ports, and docs to fit the target project.
5. Run the narrowest relevant checks.

## Worktree And Docker Files

Keep `.worktreeinclude` as a short allowlist. Good examples are `.env`, `.env.local`, `.env.development.local`, and `.sops.yaml`. Do not include generated state such as `.venv`, `node_modules`, caches, local databases, screenshots, or logs.

Keep `.dockerignore` broad enough to exclude `.git`, `.context`, local secrets, dependency directories, caches, logs, and build outputs. Preserve explicit exceptions for committed templates such as `.env.example`.

## Source Of Truth

The canonical files live in the `508-devkit` repository. Do not recreate large snippets from memory when the repo is available locally.
