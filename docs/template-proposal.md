# AI-First Repository Template Proposal

## Design Goal

This template captures recurring conventions from existing repositories so coding agents can create project-specific files on demand without needing a scaffolding CLI.

It is optimized for:

- Codex: `AGENTS.md`, `.context/`, explicit scripts, surgical edit guidance.
- Claude Code: `CLAUDE.md` as a short pointer to canonical rules.
- Cursor: `.cursor/rules/repo-conventions.mdc`.
- Future agents: documented boundaries, deterministic commands, and machine-readable structure.

## Default Shape

```text
.
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── .context/
│   ├── architecture/
│   ├── decisions/
│   └── runbooks/
├── .cursor/rules/
├── .github/workflows/
├── apps/
│   ├── api/
│   ├── web/
│   └── worker/
├── packages/
│   └── shared/
├── docs/
└── scripts/
```

## Defaults

- Python: `uv`, Ruff, MyPy, Pytest.
- JavaScript: Bun, Biome, TypeScript, Vitest.
- Infra: Docker Compose for Postgres and Redis.
- Local dev: host-run app services with Docker-managed infra.
- Ports: stable worktree-derived allocations.
- CI: frozen installs, area-aware checks, lint/type/test parity.
- Env: `.env.example` as the runtime contract.

## Alternative Paths

- For very large JS monorepos, pnpm is still an acceptable fallback.
- For static sites, drop `apps/api`, `apps/worker`, Postgres, and Redis.
- For Python-only repos, drop pnpm workspace files and web CI.
- For product repos with browser UI, add Playwright after the first interactive flow exists.
- For LLM features, add deterministic eval fixtures before live model evals.

## Non-Goals

- No CLI generator.
- No mandatory deployment platform.
- No full app implementation.
- No secret management opinion beyond environment-variable contracts and CI secret boundaries.
