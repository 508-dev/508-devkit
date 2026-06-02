# Repository Layout

This repository uses an app/package split:

- `apps/api`: minimal Python app/shared-package wiring.
- `apps/web`: framework-neutral TypeScript conventions.
- `packages/shared`: shared settings, clients, schemas, queue helpers, and pure business logic.
- `scripts`: deterministic project entrypoints used by humans, CI, and agents.
- `docs`: durable user-facing or contributor-facing documentation.
- `.context`: operational memory for humans and agents.

Treat `apps/*` here as reference wiring, not product code. Keep service-specific behavior in its service when applying the devkit to a real repo. Put shared contracts and pure helpers in `packages/shared`.
