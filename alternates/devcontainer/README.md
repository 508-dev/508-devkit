# Dev Container Alternate

Use this alternate only when the team wants a containerized editor/runtime environment.

It is not a root default because many 508.dev repos prefer host-run app services for reload speed and agent debuggability.

Copy `devcontainer.json.example` to `.devcontainer/devcontainer.json` and adapt ports, extensions, and post-create commands for the target repo.
