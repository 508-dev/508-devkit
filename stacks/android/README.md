# Android Stack

Use this stack when the target project is a native Android app (Kotlin +
Jetpack Compose), especially one aimed at F-Droid, Google Play, or both.

Unlike `stacks/typescript` or `stacks/python`, an Android app has no
server-side "run the dev server" shape and no package-manager cooldown
mechanism — the reusable part isn't local dev tooling, it's the release and
publishing pipeline. This stack is a convention pack for that: how versioning
works, how CI ships signed builds to GitHub Releases / Google Play / F-Droid,
and the architecture decisions that keep coming up across 508.dev's Android
apps. It was distilled from two sibling apps built on this pattern —
`soundboard` (the more complete one; it has the full release pipeline) and
`emotion-tracker` (the first one; it set the baseline Gradle/Compose
conventions). Where they differ, the reasons are called out below.

## Contains

- `README.md`: this file.
- `scripts/sync-version.sh`: derives `versionCode` and store release notes
  from `version.txt`.
- `scripts/fdroid-publish.sh`: publishes a signed APK to a self-hosted F-Droid
  repository on `gh-pages`.
- `github/release.yml.example`, `github/pr-title.yml.example`: the release
  pipeline and the PR-title gate it depends on.
- `release-please-config.json.example`: release-please config for a
  single-package Android repo.
- `version.txt.example`: seed version file.
- `keystore.properties.example`: local release-signing config, mirrored by
  the CI environment variables in `release.yml`.
- `fastlane/metadata/android/en-US/`: the one place store copy is written —
  Play, the self-hosted F-Droid repo, and the f-droid.org submission all read
  from it.
- `fdroid/config.yml.example`, `fdroid/metadata/*.yml.example`: self-hosted
  F-Droid repo config.
- `fdroid/fdroiddata/`: the one-time f-droid.org submission payload plus a
  README explaining its unusual constraints.

This stack does not include an app scaffold (no `MainActivity`, no
`build.gradle.kts`). Android app structure is too product-specific to
template usefully; what's reusable is the release machinery and the decisions
below.

## Apply

Every example file below uses the package `dev.co508.example`, app slug
`example`, and env var prefix `EXAMPLE_` as placeholders. Replace all three
consistently when copying files in:

```bash
mkdir -p scripts fastlane/metadata/android/en-US/changelogs fdroid/metadata fdroid/fdroiddata .github/workflows
cp stacks/android/scripts/*.sh scripts/
cp stacks/android/version.txt.example version.txt
cp stacks/android/release-please-config.json.example .release-please-config.json
cp stacks/android/keystore.properties.example .
cp stacks/android/github/release.yml.example .github/workflows/release.yml
cp stacks/android/github/pr-title.yml.example .github/workflows/pr-title.yml
cp -r stacks/android/fastlane .
cp stacks/android/fdroid/config.yml.example fdroid/config.yml
cp stacks/android/fdroid/metadata/dev.co508.example.yml.example \
   fdroid/metadata/<your.real.package>.yml
cp -r stacks/android/fdroid/fdroiddata fdroid/
```

Then, in every copied file:

1. Replace `dev.co508.example` with the app's real application ID. See
   "Application ID" below before picking one.
2. Replace the `example` app slug (artifact file names, F-Droid repo paths)
   with the app's real short name.
3. Replace `EXAMPLE_` (the `SOUNDBOARD_KEYSTORE_*`-style env var prefix in
   `release.yml` / `keystore.properties.example`) with the app's slug,
   upper-cased.
4. Fill in `fastlane/metadata/android/en-US/{title,short_description,
   full_description}.txt` with real store copy.
5. Rewrite `.release-please-config.json`'s `package-name` to match.

Then read "Release & Versioning" below, set up the repository and secrets it
describes (`docs/deployment.md` in the target repo should carry a copy of
that section once adapted — see "Docs To Write" at the end of this file), and
bake the version:

```bash
git tag v0.1.0 && git push origin v0.1.0
```

## Recurring Architecture Decisions

These are the calls that were open on the first Android app under this
pattern and stayed closed on the second. Treat them as defaults, and write a
`DECISIONS.md` entry in the target repo (not here) when the target app
deviates — that's what both source apps did.

- **Jetpack Compose over Views.** Both apps use Compose (Material 3)
  exclusively. It's the better fit for custom gesture-driven controls
  (`Canvas` + `pointerInput`), and there's no reason to introduce the View
  system alongside it.
- **No DI framework by default.** Two or three hand-constructed objects in
  the `Application` subclass, reached through a `CreationExtras` helper, is
  not a graph that earns Hilt's ceremony. Introduce Hilt (fully open source,
  no Play Services dependency — it still qualifies for F-Droid) only once the
  object graph actually outgrows manual wiring, and say so in `DECISIONS.md`
  when it happens.
- **GPL-3, targeting F-Droid, by default.** If the product goal includes
  F-Droid distribution, every shipped dependency — transitively — must itself
  be free software: AndroidX and Kotlin-stdlib-class libraries only. No
  Google Play Services, no Firebase, no closed-source SDKs. Compose's dynamic
  color API is a pure AndroidX API despite the "Material You" branding and is
  fine. `androidx.media3` is Apache-2.0 and qualifies. This constraint is
  specific to the F-Droid goal, not to Android generally — drop it if the
  target app has no F-Droid ambitions, but confirm that with the user first;
  don't assume.
- **Local storage: Room vs. a flatter store.** Default to Room when the data
  has real relations, queries, or history (journal entries, reminders). Reach
  for `DataStore<T>` with a `kotlinx.serialization` codec instead when the
  entire persisted state is one small ordered list or document with no
  queries — it avoids KSP, a schema directory, and migration tests for
  something that's naturally a single JSON blob. Revisit if the data model
  grows relations later.
- **SDK levels: `minSdk 26`, `targetSdk` one below `compileSdk`.** `minSdk
  26` (Android 8.0, Oreo) buys `java.time` without desugaring, native
  notification channels, and `AudioFocusRequest` — real simplifications, not
  just a floor pick. Keep `targetSdk` one below `compileSdk` until that API
  level's behavior changes have been reviewed. Check `gradle/libs.versions.toml`
  in the target repo (or a sibling app) for current values rather than
  trusting a number written here — these move.
- **Application ID: reverse-DNS, and Android's package-name rule is
  stricter than Kotlin's.** A leading-digit segment (`dev.508.app`) is
  invalid twice over: Kotlin/Java identifiers can't start with a digit, and
  even the underscore-prefixed workaround (`dev._508.app`) still fails,
  because Android's manifest package-name rule requires every segment to
  *start with a letter* — AAPT rejects `_508` outright. This is a hard build
  error discovered by actually running `./gradlew assembleDebug`, not by
  reading docs beforehand — verify a new namespace the same way, end to end,
  before treating it as settled. 508.dev's own apps use `dev.co508.<app>`.
  Treat the chosen application ID as permanent once a store listing exists
  under it (F-Droid and Play both key on it).
- **AGP 9+ has built-in Kotlin support — do not apply
  `org.jetbrains.kotlin.android` alongside it.** AGP 9.0+ compiles Kotlin
  itself; applying the `kotlin-android` plugin on top is a hard build error,
  not a warning. The `org.jetbrains.kotlin.plugin.compose` and
  `org.jetbrains.kotlin.plugin.serialization` sub-plugins are still applied
  normally — built-in Kotlin only subsumes the base Kotlin-Android plugin.
  JVM target comes from `android.compileOptions.targetCompatibility`
  directly. See
  <https://developer.android.com/build/migrate-to-built-in-kotlin>.
- **The OSS-licenses list is hand-maintained, not generated.** Google's
  OSS-licenses Gradle plugin is part of Play Services, which breaks the
  F-Droid goal outright. Write the licenses screen by hand instead, grouped
  by project rather than by Maven coordinate, and update it whenever
  `gradle/libs.versions.toml` changes — a stale list is a compliance problem,
  not a cosmetic one.
- **Renovate handles Gradle version bumps; don't hand-edit versions
  opportunistically.** Renovate natively understands Gradle version catalogs
  — no extra config needed for it to open PRs against
  `gradle/libs.versions.toml` on the repo's normal cooldown. Android Studio
  will flag newer AGP/Kotlin/Gradle releases as lint warnings before Renovate
  gets to them; that's expected, not a signal to bump early.
- **Gradle daemon JVM pin.** Pin the Gradle daemon's JVM in
  `gradle/gradle-daemon-jvm.properties` rather than assuming the system JDK
  matches what AGP requires. Android Studio's bundled JBR matches the pin
  automatically; from the CLI on a machine whose system JDK differs, invoke
  as `JAVA_HOME=/path/to/android-studio/jbr ./gradlew <task>`.
- **Deferred `androidTest` coverage is a legitimate default, not neglect.**
  Both apps ship JVM unit tests only (pure logic: persistence round-trips,
  domain math) and defer instrumented (`androidTest`) coverage for anything
  needing a real device or emulator (playback, foreground services, SAF
  permissions). That's fine for a first pass; add `androidTest` when the
  deferred surface next changes shape, not preemptively.

## Release & Versioning

The release model is: **merging to `main` only grooms a standing release PR;
merging *that* PR is what tags a version and publishes it.**

```
merge a PR to main
  -> release-please opens/updates "chore(main): release X.Y.Z"
     (version.txt + CHANGELOG.md, from Conventional Commit PR titles)
     -> CI tops the PR up with files derived from those
        (versionCode, versionName, store release notes)
  -> you merge the release PR when you want to ship
     -> release-please tags vX.Y.Z and creates the GitHub Release
        -> publish job: signed APK + AAB -> GitHub Release, Play, F-Droid
```

Why not release on every merge to `main`: that makes every merge a public
release with no way to batch commits into one version, and it needs CI to
push a version-bump commit directly to `main` — which means either leaving
`main` unprotected or granting a bot a branch-protection bypass. The
release-PR model needs neither: the bot only ever opens a PR, and the human
merge is the deliberate act.

**`release-please` and `publish` run as two jobs in one workflow run, on
purpose.** A tag or PR created with `GITHUB_TOKEN` does not trigger another
workflow run. A separate tag-triggered publish workflow is the obvious
design and will silently never fire. `github/release.yml.example` keeps both
jobs in one `on: push: branches: [main]` workflow for this reason.

PR titles are squash-merged into `main`'s commit subjects, and release-please
reads those subjects to decide the next version:

| PR title prefix | Effect |
| --- | --- |
| `feat: ...` | minor bump |
| `fix: ...`, `perf: ...` | patch bump |
| `feat!: ...`, or a `BREAKING CHANGE:` footer | minor bump pre-1.0 (`bump-minor-pre-major`), major after |
| `docs:`, `chore:`, `ci:`, `refactor:`, `test:`, `build:`, `style:` | no release on their own |

`github/pr-title.yml.example` enforces this shape on open PRs with one regex
— deliberately no third-party action, since a release-gating check is a bad
place to add a supply-chain dependency.

### `versionCode` is derived, and stays a literal

`version.txt` is the only source of truth for the version. Everything else —
`versionCode`, `versionName` in `app/build.gradle.kts`, and the store release
notes in `fastlane/metadata/android/*/changelogs/` — is derived from it by
`scripts/sync-version.sh`. Never hand-edit `versionCode`/`versionName`; run
the script after changing `version.txt` and commit what it writes. CI runs
`sync-version.sh --check` and fails the build on drift.

`versionCode` is computed as `major * 1000000 + minor * 1000 + patch`, never
chosen by hand. That keeps it strictly increasing across any semver bump —
which matters because **Play permanently rejects a `versionCode` it has
already seen for an app, including one from a deleted release.**

Both `versionCode` and `versionName` must stay plain literals on their own
line in `app/build.gradle.kts`, never an expression, however tidy. F-Droid's
own update bot regex-parses them straight out of that file to notice a new
version; an expression there silently ends automatic F-Droid releases with
no error anywhere.

## GitHub Actions

`github/release.yml.example` covers both jobs described above:
`release-please` (grooms/tags the release) and `publish` (builds signed
artifacts and ships them). Both declare a GitHub **Environment** (`Prod` in
the example) for their secrets rather than repo-level secrets — see
"Secrets" below for why that distinction matters.

`github/pr-title.yml.example` is a required check on PRs, gating the
Conventional Commit shape release-please depends on.

Adapt, don't skip, the following before relying on either:

- `concurrency: { group: release, cancel-in-progress: false }` — never let
  two releases interleave; they push to the same branches and the same
  F-Droid index. Queue, don't cancel — a cancelled publish leaves a tagged
  release with no artifacts.
- The `release-please` job checks out the release PR's branch (not `main`)
  with a token that has push access, purely to run `sync-version.sh` and
  commit the derived files back onto the PR before a human reviews it.
- The `publish` job builds from the **tag**, not whatever `main` has drifted
  to since the release PR was opened.
- "Work out what is configured" degrades gracefully: no signing key means
  the release is tagged with notes but nothing is published; no Play
  credentials means GitHub Releases and F-Droid still ship. Useful while
  store accounts are still being set up — don't turn this into a hard
  failure.

## Store Publishing

### Signing

There are up to three separate signatures in play, and they are not
interchangeable — Android refuses to update an installed app with a
differently-signed APK:

| Channel | Signed by |
| --- | --- |
| GitHub Release APK / self-hosted F-Droid repo | the app's own release key |
| Google Play | Play App Signing (unless the same key above was uploaded to it at app creation) |
| f-droid.org | F-Droid's own key, always — nothing else is interchangeable with it |

Upload the app's own key to **Play App Signing at app-creation time**, or
Google generates one instead and Play builds stop being interchangeable with
everything else. This choice is permanent. f-droid.org builds can never
match by design; F-Droid's
[reproducible builds](https://f-droid.org/docs/Reproducible_Builds/) process
is the eventual (optional) fix, not a prerequisite.

CI reads the keystore from `EXAMPLE_KEYSTORE_FILE` /
`EXAMPLE_KEYSTORE_PASSWORD` / `EXAMPLE_KEY_ALIAS` / `EXAMPLE_KEY_PASSWORD`
environment variables (see `keystore.properties.example` for the local
equivalent, read by `app/build.gradle.kts` when no env vars are set). With
neither source configured, a release build is simply unsigned — which is
exactly what f-droid.org's own build server wants, since it signs with its
own key regardless.

### Google Play

CI uploads the AAB to the **internal** track only and stops. Promotion to
production stays a manual Play Console step on purpose — a bad build should
never reach users automatically, and it avoids hitting Google's review queue
on every merge. Store graphics (icon, feature graphic, screenshots) aren't
uploaded by this pipeline; set them once in the Play Console UI, pasting text
from `fastlane/metadata/android/en-US/` so listings stay in step. Upload the
R8 mapping file too, or every Play crash report comes back as an unreadable
obfuscated stack trace.

The first Play release is unavoidably manual: the Play Developer API cannot
create an app or publish to a track that has never received one manual
upload.

### F-Droid: two independent paths

Run both — they solve different halves of the problem, not the same one.

- **Self-hosted repository (`scripts/fdroid-publish.sh`, automated).**
  Publishes to a git branch (typically `gh-pages`) served by GitHub Pages.
  Live within minutes of a release, but users must add the repo URL by hand.
  An F-Droid repository is cumulative — every version ever published stays
  in the index — so the script clones the existing branch and adds to it
  rather than deploying a fresh directory. The index is signed with the
  app's own release key; publish the resulting fingerprint next to the URL
  (see the generated `index.html`), since adding a repo without one is
  trust-on-first-use.
- **f-droid.org (one-time submission, then automatic).** Gives discovery —
  users find the app through search in the client they already have — but
  nothing can ever be pushed to it from CI. It builds and signs on its own
  infrastructure, on its own schedule, from a single merge request against
  [gitlab.com/fdroid/fdroiddata](https://gitlab.com/fdroid/fdroiddata). See
  `fdroid/fdroiddata/README.md` for the submission's unusual constraints —
  most importantly, **that file must carry no comments**, because
  fdroiddata's CI runs `fdroid rewritemeta` on any changed metadata file and
  fails the job on any diff it produces, and `rewritemeta` unconditionally
  strips every leading comment.

Both `fastlane/metadata/android/<locale>/` and the F-Droid-specific YAML
files read from the same store copy so Play, the self-hosted repo, and
f-droid.org never drift out of sync — keep it that way rather than
duplicating copy per store.

Two things worth checking before an f-droid.org submission, because both
fail only on their builder, never on CI:

- A pinned Gradle daemon JVM (`gradle/gradle-daemon-jvm.properties`) with a
  JDK F-Droid's builder can't fetch fails the build there while passing
  everywhere else — drop the pin before submitting if unsure.
- `./gradlew assembleRelease` must succeed from a clean checkout with no
  `keystore.properties` and no network beyond declared Gradle dependencies.

## Secrets

| Secret | Used for | Without it |
| --- | --- | --- |
| `RELEASE_KEYSTORE_BASE64` | app signing key, `base64 -w0` of the keystore | nothing is published; the release is still tagged |
| `RELEASE_KEYSTORE_PASSWORD` | keystore password | as above |
| `RELEASE_KEY_ALIAS` | key alias within the keystore | as above |
| `RELEASE_KEY_PASSWORD` | same value as the keystore password — PKCS12 keystores have no separate key password | as above |
| `PLAY_SERVICE_ACCOUNT_JSON` | Play Developer API service account, whole JSON file | Play upload is skipped; GitHub Releases and F-Droid still publish |
| `RELEASE_PLEASE_TOKEN` | fine-grained PAT so the release PR itself triggers CI | falls back to `GITHUB_TOKEN`; the release PR arrives unchecked |
| `FDROID_KEYSTORE`, `FDROID_KEY_ALIAS`, `FDROID_KEYSTORE_PASS`, `FDROID_KEY_PASS` | signs the self-hosted F-Droid index — same key as `RELEASE_KEYSTORE_*` | self-hosted F-Droid publish is skipped |

Add these under a GitHub **Environment** (e.g. `Prod`), not repo-level
Secrets, if the workflow declares `environment: Prod` on the jobs that need
them (the example does). A secret added to the wrong one of those two places
doesn't error — the job just runs with `secrets.WHATEVER` silently empty.

**The signing key cannot be rotated in practice.** Android refuses to update
an installed app with a differently-signed APK, so losing the keystore or its
password means every existing user has to uninstall and reinstall, losing
their local data. Back it up offline and off any development machine.

## Docs To Write In The Target Repo

This stack intentionally does not ship `docs/deployment.md`,
`docs/tooling.md`, or `docs/secrets.md` content — the target repo's copies of
those (from the devkit root) are meant to be *rewritten* for the app, not
appended to. Both source apps replaced the generic devkit versions outright:
`docs/deployment.md` became the pipeline diagram + versioning + signing +
Play + F-Droid walkthrough (essentially this section, made concrete with the
app's real name/package/secrets), `docs/tooling.md` became the Gradle
version-pin table plus the AGP-built-in-Kotlin gotcha, and `docs/secrets.md`
became just the signing-key table above (an Android app with no backend has
no `.env` contract to document). Do the same rewrite rather than leaving the
generic web-service-shaped versions in place.

## Agent Notes

- Do not copy this stack just because a repo happens to contain Kotlin.
  Select it only when the target is a native Android app.
- Treat the architecture decisions above as defaults to open a
  `DECISIONS.md` entry against, not silent requirements — write down *why*
  when the target app deviates, the same way both source apps did.
- Don't assume F-Droid targeting. Confirm the product's distribution goal
  before applying the GPL-3/free-software-dependency constraint or the
  F-Droid publishing pipeline; a Play-only app doesn't need either.
- Never hand-edit `versionCode`, `versionName`, or `CHANGELOG.md`. Both are
  generated from `version.txt` — change that, then run
  `scripts/sync-version.sh`.
- Do not turn the version literals in `app/build.gradle.kts` into an
  expression, or move them onto a shared line — F-Droid's bot parses them
  textually.
- Do not add publishing to a new store, or promote a Play upload past the
  internal track, without the maintainer asking. Release signing material
  and store submissions are deliberate human decisions.
- Never print keystore contents or echo a `EXAMPLE_KEYSTORE_*` /
  `FDROID_*` secret value in a workflow step.
