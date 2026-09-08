# Dependency Supply-Chain Policy

## Bun

Shown first for JavaScript projects because it is fast and simple. This is an
example preference, not a universal requirement.

`bunfig.toml`:

```toml
[install]
minimumReleaseAge = 604800
minimumReleaseAgeExcludes = ["@types/bun", "typescript"]
linker = "isolated"
```

`minimumReleaseAge` is in seconds.

## uv

Use this when a project selects the Python stack or otherwise has a Python workspace.

Relative dependency cooldowns require uv `0.9.17` or newer. Before adding
`exclude-newer = "P7D"` to a downstream repo, agents should run:

```bash
uv --no-config --version
```

Use `--no-config` for the version check because a broken user-level
`~/.config/uv/uv.toml` can otherwise fail before the project is inspected.

If uv is older than `0.9.17`, ask the user whether they want to upgrade uv. Do
not write relative values such as `P7D` or `7 days` into `pyproject.toml`,
`uv.toml`, or `~/.config/uv/uv.toml` until the installed uv supports them. Older
uv releases parse those strings as dates and fail during settings discovery.

Optional `pyproject.toml` cooldown for compatible uv clients:

```toml
[tool.uv]
exclude-newer = "P7D"

[tool.uv.pip]
exclude-newer = "P7D"
```

The Python stack does not commit this relative cooldown by default because
older uv clients parse persistent config during settings discovery and fail
before they can run a locked install. Regenerate `uv.lock` with a compatible
`uv` version after adding the setting so the lock records
`exclude-newer-span = "P7D"`. Older `uv` releases and Docker images must be
upgraded before using this relative cooldown.

If the user declines an upgrade, leave the relative cooldown out of persistent
uv config and document the exception. An absolute RFC 3339 timestamp is
compatible with older uv, but it is a fixed cutoff, not a rolling seven-day
cooldown.

## pnpm

Use when the team prefers pnpm, the repo already uses pnpm, or the workspace
needs pnpm-specific monorepo behavior.

`pnpm-workspace.yaml`:

```yaml
minimumReleaseAge: 10080
minimumReleaseAgeExclude:
  - "@types/node"
  - "typescript"
```

`minimumReleaseAge` is in minutes.

## Ruby and Bundler

Use this when a project selects the Ruby stack or otherwise has a `Gemfile`.

Bundler cooldowns require Bundler `4.0.13` or newer. Before adding cooldown to
a downstream repo, check:

```bash
bundle --version
```

If Bundler is older than `4.0.13`, update Bundler and pin the same version in
`Gemfile.lock` so local development and CI resolve dependencies with the same
client behavior:

```bash
gem install bundler -v 4.0.13
bundle lock --bundler=4.0.13
```

Then prefer a committed per-source cooldown in `Gemfile`:

```ruby
source "https://rubygems.org", cooldown: 7
```

This policy is intentionally committed with the dependency source instead of
living only in a developer's local Bundler config. It gives fresh public gem
releases time to be vetted while keeping private or internal gem sources free to
declare their own policy.

Use `cooldown: 0`, `bundle install --cooldown 0`, or `BUNDLE_COOLDOWN=0` only
for intentional exceptions such as emergency security fixes. Document the
exception in the PR or release note.

## Gradle (Android)

Use this when a project selects the Android stack (`stacks/android`).

Gradle has no package-manager-level cooldown flag comparable to Bun/uv/pnpm/
Bundler. Renovate is the whole mechanism: it natively understands Gradle
version catalogs and opens PRs against `gradle/libs.versions.toml` on the
repo's normal `minimumReleaseAge`, no extra Renovate config required. Don't
hand-edit dependency versions in that file opportunistically outside of a
Renovate PR unless fixing something broken.

Verify Gradle wrapper integrity via `distributionSha256Sum` in
`gradle/wrapper/gradle-wrapper.properties`, and update both together when
bumping the wrapper version. CI should build against the committed wrapper
only — never a floating Gradle version.

## CI

Use frozen or locked installs:

```bash
bun install --frozen-lockfile
uv sync --locked
pnpm install --frozen-lockfile
BUNDLE_DEPLOYMENT=true BUNDLE_FROZEN=true bundle install
```

Renovate should use `minimumReleaseAge = "7 days"` so dependency PRs do not fight package-manager cooldowns.

Security workflows are opt-in extras:

- Add `extras/github/gitleaks.yml.example` only when maintainers want CI history
  scanning for secrets and have a plan to handle baseline findings.
- Add `extras/github/dependency-review.yml.example` only after confirming the
  target repo uses GitHub's dependency graph and wants known-vulnerability,
  license, or dependency-change reporting.

Cooldowns, locked installs, committed lockfiles, and least-privilege CI remain
the default supply-chain defenses.
