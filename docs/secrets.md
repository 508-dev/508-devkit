# Secrets

Most repos should use environment variables and CI secrets.

SOPS is optional. Add it only when the repository needs encrypted files checked into Git, such as shared non-production config or deploy manifests.

If SOPS is adopted:

1. Copy `.sops.yaml.example` to `.sops.yaml`.
2. Replace the example Age recipient.
3. Store encrypted files under `secrets/`.
4. Document decrypt/edit commands in this file.

Do not commit plaintext secrets.
