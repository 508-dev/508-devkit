# Agent Walkthrough

This walkthrough shows the expected judgment when using 508 Devkit on a target repository.

## Prompt

```text
Use /path/to/508-devkit as the project bootstrap reference.
Inspect my target repo, ask any necessary questions, then apply the relevant conventions.
```

## Expected Agent Flow

1. Inspect the target repo before editing.
2. Read existing `AGENTS.md`, package manifests, lockfiles, workflows, Compose files, scripts, and docs.
3. Decide which devkit conventions already exist.
4. Ask questions only when the product shape or stack cannot be inferred safely.
5. Apply the smallest useful set of files.
6. Run focused validation.
7. Summarize what was adopted, skipped, and why.

## Example Questions

- Is this a backend-only service, full-stack app, CLI, worker, mobile app, or docs site?
- Has the frontend framework already been chosen?
- Where will this deploy?
- Which database and queue are expected locally?
- Should this repo use encrypted files, or only environment variables?
- Should GitHub Discussions, CODEOWNERS, or TODO-to-issue automation be enabled?

## Example Decisions

If the target repo has no frontend framework, copy the framework-neutral `stacks/typescript` conventions but do not scaffold Next.js, Vite, or TanStack Start.

If the target repo already uses pnpm, use `stacks/typescript/pnpm/` instead of forcing Bun.

If the target repo has a deployment platform, update `docs/deployment.md`. If not, leave a decision record placeholder.

If the target repo is public or support-heavy, consider `extras/github/community/`. Otherwise keep discussion templates out.

If the target repo has no real GitHub teams yet, do not enable active CODEOWNERS.

If maintainers ask for secret scanning, prefer GitHub native secret scanning
and push protection when available. Add the Gitleaks extra only when CI scanning
is explicitly desired.

If maintainers ask for dependency visibility, explain that Dependency Review is
dependency graph-based reporting. Add the extra only after confirming the graph
is enabled and the repo wants that reporting.
