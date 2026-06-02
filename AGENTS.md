# AI Agent Development Guide

## Environment

- Only `python3` is guaranteed. Do not assume `python` exists.
- Prefer `uv run`, `bun run`, and scripts in `scripts/` over raw commands.
- Treat install, dev, and test commands as executable code. Inspect manifests, package scripts, lockfiles, Docker files, and setup scripts before running them in unfamiliar repos.

## Dependency Supply-Chain Safety

- Bun: keep `bunfig.toml` with `minimumReleaseAge = 604800`.
- uv: keep `exclude-newer = "7 days"`.
- pnpm fallback: keep `minimumReleaseAge: 10080` in `pnpm-workspace.yaml`.
- CI should use locked installs:
  - `bun install --frozen-lockfile`
  - `uv sync --locked`
  - `pnpm install --frozen-lockfile` when pnpm is used.
- Commit lockfiles.

## Repository Shape

- `apps/api`: Python HTTP API.
- `apps/web`: framework-neutral Bun/TypeScript workspace for web-side conventions.
- `apps/worker`: Python background jobs.
- `packages/shared`: shared Python settings, schemas, and helpers.
- `scripts`: stable project entrypoints.
- `docs`: contributor-facing documentation.
- `.context`: operational memory for humans and agents.

## Development Workflow

- Run infrastructure with Docker Compose.
- Run app services on the host for reload speed and debuggability.
- Use `./scripts/worktree-ports.py env` to inspect local ports.
- Use `./scripts/docker-compose.sh` instead of raw `docker compose` for local worktree-safe infra.
- Use `./scripts/dev.sh` for host-run app services.
- Do not assume a frontend framework from this devkit. Choose Next.js, Vite, TanStack Start, Astro, Expo, or no frontend based on the target project.
- Keep `.worktreeinclude` as a short allowlist of ignored local config to copy into sibling worktrees, such as `.env`, `.env.local`, and `.sops.yaml`.
- Keep `.dockerignore` in sync with the repo shape so Docker build contexts exclude secrets, local dependencies, caches, `.context/`, and generated outputs.

## Editing Rules

- Read target files, callers, exports, tests, and obvious shared utilities before editing.
- Keep edits surgical.
- Do not reformat unrelated files.
- Add or update tests when behavior changes.
- Update `.env.example` when adding configuration.
- Update docs when changing developer workflows.
- Use Pydantic for Python settings and boundary schemas.
- Use Alembic for Python database migrations.
- Use Drizzle for TypeScript database access.
- Keep secrets in environment variables or SOPS-managed files, never in code.

## `.context/`

Use `.context/` for concise operational memory:

- `.context/architecture/`: system structure and integration patterns.
- `.context/decisions/`: durable tradeoffs and decisions.
- `.context/failures/`: known bad paths and failed approaches.
- `.context/runbooks/`: operational procedures.
- `.context/summaries/`: synthesized project history.

Do not dump raw transcripts, logs, screenshots, or secrets into `.context/`.

## Validation

Before calling work complete, run the narrowest relevant checks:

```bash
./scripts/lint.sh
./scripts/typecheck.sh
./scripts/test.sh
```

For broader changes, run:

```bash
./scripts/check-all.sh
```
