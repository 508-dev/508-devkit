# Dependency Supply-Chain Policy

## Bun

Default for new JavaScript projects.

`bunfig.toml`:

```toml
[install]
minimumReleaseAge = 604800
minimumReleaseAgeExcludes = ["@types/bun", "typescript"]
linker = "isolated"
```

`minimumReleaseAge` is in seconds.

## uv

`pyproject.toml`:

```toml
[tool.uv]
exclude-newer = "7 days"

[tool.uv.pip]
exclude-newer = "7 days"
```

## pnpm Fallback

Use only when the JS workspace grows large enough to justify switching away from Bun.

`pnpm-workspace.yaml`:

```yaml
minimumReleaseAge: 10080
minimumReleaseAgeExclude:
  - "@types/node"
  - "typescript"
```

`minimumReleaseAge` is in minutes.

## CI

Use frozen or locked installs:

```bash
bun install --frozen-lockfile
uv sync --locked
pnpm install --frozen-lockfile
```
