# Existing Repository Pattern Report

Generated from a read-only scan of repositories under `/Users/michaelwu/dev` on 2026-06-02.

## Scope

The scan found 32 Git repositories. The strongest repeated signals were:

| Pattern | Count | Notes |
| --- | ---: | --- |
| Python or `uv` project metadata | 13 | `pyproject.toml` plus `uv.lock` appears across backend, worker, pipeline, and agent/tooling repos. |
| Node package metadata | 17 | Large monorepos lean `pnpm`; smaller single-app repos frequently use Bun. |
| Docker Compose | 10 | Most Compose files provide infrastructure services first, especially Postgres and Redis. |
| GitHub Actions workflows | 20 | Common CI shape is lint, typecheck, test, and deploy workflows split by changed area. |
| Pre-commit config | 6 | Most Python-heavy repos use Ruff hooks; some also run MyPy through local scripts. |
| Agent instruction files | 14 | `AGENTS.md` is common for Codex. `CLAUDE.md` is present in several repos. |

Representative repositories inspected more deeply:

- `/Users/michaelwu/dev/508-workflows`
- `/Users/michaelwu/dev/asiatraveldeals`
- `/Users/michaelwu/dev/favorite-places`
- `/Users/michaelwu/dev/house-calendar`
- `/Users/michaelwu/dev/voy`
- `/Users/michaelwu/dev/w3df-bot`
- `/Users/michaelwu/dev/apollo`
- `/Users/michaelwu/dev/preview_neon_parent`

## Recurring Conventions

### Python

- Prefer `uv` for dependency installation and command execution.
- Use `python3` explicitly where raw Python is required.
- Use `pyproject.toml` for tool configuration.
- Common tools:
  - Ruff for lint and format.
  - MyPy for static checking.
  - Pytest for backend and worker tests.
  - Coverage for mature service repos.
- `508-workflows` uses a `uv` workspace with `apps/*` and `packages/shared`.
- Dependency cooldown appears in `508-workflows` through:
  - `[tool.uv] exclude-newer = "7 days"`
  - `[tool.uv.pip] exclude-newer = "7 days"`

### JavaScript and TypeScript

- Large app monorepos use `pnpm`, workspaces, Turbo, Biome, TypeScript, and Vitest.
- Smaller app repos often use Bun directly, especially Astro and compact Next.js projects.
- Biome is the dominant JS formatter/linter.
- Vitest is the dominant JS unit test runner.
- Common root scripts:
  - `dev`
  - `build`
  - `lint`
  - `format`
  - `typecheck`
  - `check`
  - `test`
  - `ports`

Template decision after user preference: default to Bun for new projects. Document pnpm as the fallback for very large workspaces that need its mature monorepo ergonomics.

### Docker Compose and Infra

Most Compose files are used for local infrastructure, not necessarily for every app process.

Common services:

- `postgres`
- `redis`
- Optional object storage, especially MinIO in `508-workflows`.
- Optional observability stacks in larger repos, such as HyperDX or OTEL endpoints.

Common Compose practices:

- Healthchecks on Postgres and Redis.
- Host ports controlled by environment variables.
- Fixed container ports with variable published host ports.
- Volumes for durable local data.
- `compose.yml` or `compose.yaml` as the canonical file, with occasional `docker-compose.yml` compatibility wrappers.

Template decision: include Postgres and Redis by default, plus optional MinIO behind a Compose profile.

### Local Development

The most important recurring development pattern is:

> Run infrastructure in Docker. Run app services on the host for fast reload and agent-friendly debugging.

Examples:

- `508-workflows` uses `scripts/dev.sh` and `scripts/dev_mux.py` for host-run API, worker, and Discord bot.
- `asiatraveldeals` uses `scripts/run-local.sh` to start Compose infra and host-run API/web services.
- `favorite-places`, `house-calendar`, `voy`, and `asiatraveldeals` include deterministic worktree port allocation.

Template decision: include dependency-free `scripts/worktree-ports.py`, `scripts/dev.sh`, and `scripts/docker-compose.sh`.

### Worktree Support and Ports

Recurring approach:

- Hash the absolute worktree path.
- Reserve the main checkout or default block where applicable.
- Derive stable port offsets for sibling worktrees.
- Avoid browser-restricted ports.
- Emit shell-friendly environment variables.

Common variable names:

- `API_PORT`
- `WEB_PORT`
- `POSTGRES_PORT`
- `REDIS_PORT`
- `*_HOST_PORT`
- `*_HOST_BIND`
- `DATABASE_URL`
- `POSTGRES_URL`
- `REDIS_URL`

Template decision: allocate a block of ports per worktree and emit API, web, worker health, Postgres, Redis, MinIO, and OTEL ports.

### GitHub Actions

Common workflow traits:

- Run on pull requests and `main` pushes.
- Use path filters in larger repos.
- Install `uv` through `astral-sh/setup-uv`.
- Install Bun through `oven-sh/setup-bun` where Bun is used.
- Install pnpm through `pnpm/action-setup` or project setup actions where pnpm is used.
- Split Python and web checks when the repo has both.
- Use frozen or locked installs in CI.
- Include deployment workflows separately from validation workflows.
- Use concurrency groups for larger deploy/preview workflows.

Template decision: include one CI workflow with changed-area detection and jobs for Python, web, and Compose smoke checks.

### Environment Variables

Repeated env conventions:

- `.env.example` is common in service repos.
- Secrets stay unset or clearly placeholdered.
- Shared runtime fields:
  - `ENVIRONMENT`
  - `LOG_LEVEL`
  - `SENTRY_DSN`
  - `OTEL_*`
  - `LANGFUSE_*`
- Infra fields:
  - `POSTGRES_URL` or `DATABASE_URL`
  - `POSTGRES_DB`
  - `POSTGRES_USER`
  - `POSTGRES_PASSWORD`
  - `REDIS_URL`
- API/service fields:
  - `API_SHARED_SECRET`
  - `WEB_HOST`
  - `WEB_PORT`
  - service-specific `*_BASE_URL`
- LLM fields:
  - `OPENAI_API_KEY`
  - `OPENAI_BASE_URL`
  - `OPENAI_MODEL`
  - optional direct provider fallbacks

Template decision: use `.env.example` as an agent-readable contract, with comments for local defaults versus production requirements.

### Deployment

Deployment varies by repo:

- Fly.io appears in `voy`, `apollo`, and preview workflows.
- Kamal appears in infra/deployment repos.
- Coolify/Compose deployment appears in `508-workflows`.
- GitHub Pages appears in static site repos.
- Several repos split production, staging, and preview workflows.

Template decision: do not bake in one deploy target. Add `docs/deployment.md` with a deploy decision record and placeholder workflow guidance.

### Logging and Observability

Recurring conventions:

- `LOG_LEVEL` and `ENVIRONMENT` are basic runtime defaults.
- `SENTRY_DSN` appears as optional error reporting.
- Larger repos include OTEL/HyperDX concepts.
- LLM-heavy repos include Langfuse.
- Human-triggered operational actions should be logged or audited best-effort.

Template decision: include standard env names and docs, but no mandatory observability backend.

### Testing

Common testing layers:

- Python unit and integration tests under `tests/` or app-local tests.
- Pytest markers for integration/browser/e2e tests.
- Vitest for frontend/package tests.
- Playwright appears for dashboard/UI flows where browser confidence matters.
- Evals are treated as product surface in LLM features, often gated by changed paths.

Template decision: include unit test placeholders, marker conventions, and docs for when to add Playwright or eval suites.

## Template Implications

The template should not be a generator. It should be a compact source of truth that agents can read, adapt, and extend:

- Agent docs at the root: `AGENTS.md`, `CLAUDE.md`, Cursor rules.
- Operational memory in `.context/`.
- Clear repo layout and boundaries.
- Minimal but real manifests and scripts.
- Locked-install and dependency-cooldown defaults.
- Deterministic worktree ports.
- Compose infra first.
- CI that mirrors local checks.
- Documentation that explains decisions and tradeoffs instead of only listing commands.
