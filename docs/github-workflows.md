# GitHub Workflows

508 Devkit separates common GitHub hygiene from team-specific automation.

## Default Files

Root `.github/` files are meant to be safe defaults for most repositories:

- `.github/PULL_REQUEST_TEMPLATE.md`: prompts for summary, validation, risk, and screenshots.
- `.github/ISSUE_TEMPLATE/bug_report.yml`: captures reproducible defects.
- `.github/ISSUE_TEMPLATE/feature_request.yml`: captures product or workflow requests.
- `.github/ISSUE_TEMPLATE/docs_request.yml`: captures documentation gaps.
- `.github/ISSUE_TEMPLATE/config.yml`: keeps blank issues allowed and documents where to add discussion links.
- `.github/workflows/ci.yml`: runs the baseline Python, web, and Compose checks.
- `.github/workflows/security.yml`: runs secret scanning and dependency review.

Keep these templates short. They should improve issue and PR quality without making lightweight collaboration feel bureaucratic.

Workflows pin third-party actions to commit SHAs and use `harden-runner` in audit mode. When applying this devkit, update pinned SHAs intentionally rather than floating back to moving tags.

## CODEOWNERS

Do not enable CODEOWNERS with placeholders. Copy `alternates/github/CODEOWNERS.example` to `.github/CODEOWNERS` only after replacing owners with real GitHub users or teams.

Start broad, then make ownership more specific as code ownership becomes real. CODEOWNERS can affect required reviews and branch protection, so stale entries create workflow friction.

## Discussions

Use `alternates/github/community/DISCUSSION_TEMPLATE/questions.yml` only when the repository uses GitHub Discussions for support or product feedback.

Discussion templates should be lighter than issue templates. Ask for the question, context, and a minimal example; avoid long pledges or community rules unless the project has an explicit support policy.

## TODO To Issue Automation

Use `alternates/todo-to-issue/` only as an opt-in workflow. It can be useful for codebase maintenance, but it grants write permissions and can create issue noise.

Prefer manual runs first. Promote to scheduled or merge-triggered runs only after the team agrees on identifiers, labels, ownership, and whether source files should receive issue links.
