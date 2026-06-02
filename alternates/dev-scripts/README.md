# Dev Script Alternates

The root template keeps shell wrappers as the canonical entrypoints:

- `scripts/dev.sh`
- `scripts/docker-compose.sh`
- `scripts/check-all.sh`

That is intentional. Shell wrappers are easy for humans, CI, and agents to discover, and they can delegate to Python or Bun where those tools are better.

Recommended split:

- Use `.sh` for stable top-level commands and process orchestration.
- Use Python for dependency-free deterministic logic that must work before JS dependencies are installed, such as worktree ports.
- Use `.mjs` or `.ts` for JS-only projects where the script directly interacts with Vite, Next.js, Drizzle, or TypeScript config.

This directory provides examples for JS-first repos that want to replace the Python port helper.
