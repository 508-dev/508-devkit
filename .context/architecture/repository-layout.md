# Repository Layout

This repository uses an app/package split:

- `apps/api`: HTTP API and API-owned migrations/routes.
- `apps/web`: browser UI.
- `apps/worker`: background jobs and queue consumers.
- `packages/shared`: shared settings, clients, schemas, queue helpers, and pure business logic.
- `scripts`: deterministic project entrypoints used by humans, CI, and agents.
- `docs`: durable user-facing or contributor-facing documentation.
- `.context`: operational memory for humans and agents.

Keep service-specific behavior in its service. Put shared contracts and pure helpers in `packages/shared`.
