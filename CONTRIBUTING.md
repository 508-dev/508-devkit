# Contributing

This repository is a reference scaffold. Changes should improve conventions that apply across many 508.dev projects without turning the repo into a product-specific app.

## Principles

- Prefer small, composable defaults over large generated frameworks.
- Keep root files broadly useful.
- Put team-specific, platform-specific, or workflow-heavy choices in `alternates/`.
- Preserve supply-chain cooldowns and committed lockfiles.
- Update agent-facing guidance when conventions change.

## Local Checks

Run the narrowest relevant checks while iterating:

```bash
./scripts/lint.sh
./scripts/typecheck.sh
./scripts/test.sh
```

Before opening or updating a PR, run:

```bash
./scripts/check-all.sh
```

## Pull Requests

Use the PR template. Include what changed, why it belongs in the devkit, and how it was validated.

Avoid committing local state such as `.venv`, `node_modules`, caches, raw logs, screenshots, and `.context/artifacts/`.
