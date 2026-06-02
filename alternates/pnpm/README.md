# pnpm Alternate

The root template is Bun-first. Use these files when a project needs pnpm instead, usually for a larger JavaScript workspace or a team that already standardizes on pnpm.

Copy these files over the root equivalents:

- `package.json`
- `pnpm-workspace.yaml`

Then update CI install commands from:

```bash
bun install --frozen-lockfile
```

to:

```bash
pnpm install --frozen-lockfile
```

Keep `bunfig.toml` out of pnpm projects unless Bun is still used for local scripts.
