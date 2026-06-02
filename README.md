# 508 Devkit

Opinionated sane defaults and conventions for 508.dev projects.

This is not a scaffolding CLI. It is a reference repo that gives agents and humans a shared baseline for how new projects should be shaped: repository layout, local development, dependency safety, CI, agent instructions, operational memory, and documentation.

Point an agent at this repo when starting or normalizing a project. The agent should inspect the target repo, ask clarifying questions when the product or stack is ambiguous, and then copy or adapt only the conventions that fit.

## What It Captures

- Agent-native instructions for Codex, Claude Code, Cursor, and future agents.
- `.context/` operational memory conventions.
- Bun as the default JavaScript package manager for new projects.
- `uv` for Python.
- Dependency cooldowns for Bun, pnpm fallback, and uv.
- Host-run development services.
- Docker Compose for Postgres, Redis, and optional MinIO.
- Deterministic worktree ports.
- `.worktreeinclude` for copying local-only env files into sibling worktrees.
- `.dockerignore` for small, secret-safe Docker build contexts.
- Pydantic settings and schemas.
- Alembic migrations for Python services.
- Drizzle ORM for TypeScript services.
- Ruff, MyPy, Pytest, Biome, and Vitest.
- Optional SOPS documentation without forcing SOPS into every repo.

## Quickstart

Use the repo directly:

```text
Use /path/to/508-devkit as the project bootstrap reference.
Inspect my target repo, ask any necessary questions, then apply the relevant conventions.
```

Or install/use the bundled agent skill:

```text
Install the skill from skills/508-devkit/SKILL.md.
Run it as /508-devkit, /bootstrap-project, or whatever command name your agent client assigns.
```

Expected agent behavior:

- Inspect the target repo before editing.
- Ask about product shape, deployment target, data stores, and language/runtime choices when those are unclear.
- Automatically pick up existing conventions when the repo already has them.
- Prefer the devkit defaults for new projects unless there is a clear reason to choose an alternate.
- Run the narrowest relevant checks before calling the bootstrap complete.

For this repo itself:

```bash
uv sync
bun install --frozen-lockfile
./scripts/check-all.sh
./scripts/dev.sh
```

## Layout

```text
apps/api        Python HTTP API, Pydantic settings, SQLAlchemy/Alembic
apps/web        Bun TypeScript app, Drizzle, Biome, Vitest
apps/worker     Python background worker
packages/shared Shared Python contracts and helpers
scripts         Stable human/agent entrypoints
docs            Durable project documentation
.context        Operational memory
```

## Read Next

1. Read `docs/pattern-report.md`.
2. Read `docs/template-proposal.md`.
3. Copy `.env.example` to `.env`.
4. Run `./scripts/worktree-ports.py env`.
5. Run `./scripts/docker-compose.sh up -d postgres redis`.
6. Run `./scripts/dev.sh`.

## Worktree And Docker Hygiene

Keep `.worktreeinclude` as a short allowlist of ignored local files that should follow a developer into new sibling worktrees. Typical entries are `.env`, `.env.local`, and `.sops.yaml`; never include generated directories or large state.

Keep `.dockerignore` broad enough to exclude VCS metadata, agent scratch state, dependencies, caches, logs, and secrets from Docker build contexts. Make exceptions only for committed templates such as `.env.example`.

## Package Manager Policy

Bun is the default for new JavaScript projects.

pnpm remains documented as a fallback for larger JS workspaces. If switching to pnpm, add `pnpm-workspace.yaml`, set `minimumReleaseAge: 10080`, and change CI install commands to `pnpm install --frozen-lockfile`.

## Pick-And-Choose Alternates

This repository intentionally includes files that conflict with each other. It is a starter template, not an installable preset.

- `alternates/pnpm/`: pnpm root files and CI fragment.
- `alternates/dev-scripts/`: JS-first script variants for repos that do not want Python helpers.
- `.sops.yaml.example`: optional SOPS starter only for repos that need encrypted files.

Keep root defaults for most new projects: Bun, `uv`, shell wrappers, Python worktree ports, and Compose-managed infra.

## Skill Interface

The repository is the source of truth. The downloadable skill in `skills/508-devkit/SKILL.md` is the agent-facing interface that explains how to apply these files to a target repo.
