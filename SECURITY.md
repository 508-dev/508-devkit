# Security Policy

## Reporting Vulnerabilities

Do not open public issues for vulnerabilities or leaked secrets.

Report security concerns to the project maintainers through the private channel configured for the target repository. When applying this devkit to a new repository, replace this paragraph with the real reporting address or process.

## Secret Handling

- Keep secrets in environment variables or encrypted files.
- Never commit real `.env` files, tokens, private keys, credentials, or production data.
- Use `.env.example` for documented configuration only.
- Use `.sops.yaml.example` as a starting point when a repository needs encrypted files.

## Dependency Policy

This devkit uses dependency cooldowns and locked installs:

- Bun: `minimumReleaseAge = 604800`.
- uv: `exclude-newer = "7 days"`.
- Renovate: `minimumReleaseAge = "7 days"`.
- CI should use frozen or locked installs.

## GitHub Actions

Workflows should use least-privilege permissions, pinned action SHAs, `persist-credentials: false` where practical, and `harden-runner` in audit or block mode.
