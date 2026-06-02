# Tooling Decisions

## Python

Use `uv` for installs and execution. Keep Python configuration in `pyproject.toml`.

Required checks:

- `uv run ruff check`
- `uv run ruff format --check`
- `uv run mypy`
- `uv run pytest`

## JavaScript and TypeScript

Use Bun for new projects. It matches the preferred default for greenfield work and keeps scripts fast and direct.

Use pnpm only when a workspace grows large enough that its monorepo tooling, workspace controls, or ecosystem compatibility clearly outweigh the simplicity of Bun.

Required checks:

- `pnpm lint`
- `pnpm format:check`
- `pnpm typecheck`
- `pnpm test`

## Dependency Safety

Use dependency cooldowns and frozen installs:

- `uv`: `exclude-newer = "7 days"`.
- Bun: `bunfig.toml` sets `minimumReleaseAge = 604800` seconds.
- pnpm: `pnpm-workspace.yaml` should set `minimumReleaseAge: 10080` minutes.
- CI should use locked or frozen installs.
