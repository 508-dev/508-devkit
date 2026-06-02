# AI-First Repository Template Proposal

## Design Goal

This template captures recurring conventions from existing repositories so coding agents can create project-specific files on demand without needing a scaffolding CLI.

It is optimized for:

- Codex: `AGENTS.md`, `.context/`, explicit scripts, surgical edit guidance.
- Conductor: gitignored `.context/` for workspace-local agent scratch.
- Claude Code: `CLAUDE.md` as a short pointer to canonical rules.
- Cursor: `.cursor/rules/repo-conventions.mdc`.
- Future agents: documented boundaries, deterministic commands, and machine-readable structure.

## Default Shape

```text
.
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── .cursor/rules/
├── .github/workflows/
├── stacks/
│   ├── python/
│   ├── typescript/
│   ├── go/
│   └── rust/
├── extras/
├── docs/
└── scripts/
```

## Defaults

- Repository tooling: Bun, Biome, TypeScript, Vitest.
- Optional Python stack: `uv`, Ruff, MyPy, Pytest.
- Infra: Docker Compose examples for local databases, caches, or similar
  services.
- Local dev: host-run app services with Docker-managed infra.
- Ports: stable worktree-derived allocations.
- CI: frozen installs, area-aware checks, lint/type/test parity.
- Env: `.env.example` as the runtime contract.

## Alternative Paths

- For Python APIs, workers, or shared packages, copy `stacks/python/`.
- For Go, Rust, or other runtimes, add matching `stacks/<runtime>/` directories instead of changing the root base.
- For very large JS monorepos, pnpm is a first-class option.
- For static sites, drop database and cache services.
- For product repos with browser UI, add Playwright after the first interactive flow exists.
- For LLM features, add deterministic eval fixtures before live model evals.

## Non-Goals

- No CLI generator.
- No mandatory deployment platform.
- No full app implementation.
- No secret management opinion beyond environment-variable contracts and CI secret boundaries.
