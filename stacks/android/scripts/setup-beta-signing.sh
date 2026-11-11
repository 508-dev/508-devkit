#!/usr/bin/env bash
# Generate the dedicated beta signing key used by per-branch beta builds, and
# (with --repo) install its four BETA_* secrets into GitHub Actions.
#
#   setup-beta-signing.sh <app-slug> [--repo <owner/repo>]
#
# Creates:
#   ~/.config/<app-slug>-beta/beta.jks   PKCS12 keystore, RSA 4096, valid 10000
#                                        days, alias <app-slug>-beta
#   ~/.config/<app-slug>-beta/password   32 random alphanumeric characters
#
# Both files are reused verbatim when they already exist — never overwrite a key
# that beta users already trust. The beta key is deliberately separate from the
# release key: the beta workflow runs on arbitrary branches and must never hold
# the release signing material. See stacks/android/README.md -> "Beta Builds".
#
# With --repo, sets BETA_KEYSTORE_BASE64, BETA_KEYSTORE_PASSWORD, BETA_KEY_ALIAS,
# and BETA_KEY_PASSWORD using `gh secret set -R <owner/repo>`. Values are fed
# through stdin or files, never echoed and never passed as process arguments
# (where they would show up in `ps`).
set -euo pipefail

# Anything this script writes (the keystore and its password) is secret by
# nature, so default to owner-only permissions from the first byte.
umask 077

usage() {
    cat >&2 <<EOF
usage: ${BASH_SOURCE[0]##*/} <app-slug> [--repo <owner/repo>]

  <app-slug>          lowercase slug used to name the key, alias, and config dir
                      (e.g. "myapp" -> ~/.config/myapp-beta/)
  --repo <owner/repo> also set the four BETA_* secrets with \`gh secret set -R\`
EOF
    exit 2
}

[ "$#" -ge 1 ] || usage
slug=$1
shift

repo=
while [ "$#" -gt 0 ]; do
    case $1 in
        --repo)
            [ "$#" -ge 2 ] || usage
            repo=$2
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# The slug becomes a path component, a keytool alias, and (upper-cased) part of
# the env var prefix, so keep it to lowercase letters, digits, and hyphens.
[[ $slug =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
    echo "error: app-slug must match [a-z0-9][a-z0-9-]* (lowercase), got '$slug'" >&2
    exit 2
}

# keytool lives in the JDK, which may not be on PATH when only JAVA_HOME is set.
if command -v keytool >/dev/null 2>&1; then
    keytool=keytool
elif [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/keytool" ]; then
    keytool="$JAVA_HOME/bin/keytool"
else
    echo "error: keytool not found on PATH or under \$JAVA_HOME/bin" >&2
    exit 1
fi

conf_dir="$HOME/.config/${slug}-beta"
keystore="$conf_dir/beta.jks"
password_file="$conf_dir/password"
alias="${slug}-beta"

if [ -f "$keystore" ] && [ -f "$password_file" ]; then
    echo "==> reusing existing key at $keystore"
else
    mkdir -p "$conf_dir"
    chmod 700 "$conf_dir"

    # 32 random alphanumeric characters. `|| true` absorbs the SIGPIPE that
    # `head` sends `tr` once it has the bytes it needs.
    password=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 || true)
    [ "${#password}" -eq 32 ] || { echo "error: failed to generate a password" >&2; exit 1; }
    printf '%s' "$password" > "$password_file"
    chmod 600 "$password_file"

    # Pass the password through the environment so it never appears in `ps`.
    KEYSTORE_PASS="$password" "$keytool" -genkeypair -noprompt \
        -keystore "$keystore" \
        -storetype PKCS12 \
        -alias "$alias" \
        -keyalg RSA -keysize 4096 \
        -validity 10000 \
        -dname "CN=${slug} beta, O=508.dev" \
        -storepass:env KEYSTORE_PASS \
        -keypass:env KEYSTORE_PASS
    chmod 600 "$keystore"
    echo "==> generated $keystore (RSA 4096, alias $alias)"
fi

password=$(cat "$password_file")

# --- GitHub secrets (optional) ----------------------------------------------
if [ -n "$repo" ]; then
    command -v gh >/dev/null 2>&1 || { echo "error: gh not found on PATH" >&2; exit 1; }

    echo "==> setting BETA_* secrets on $repo"
    # Keystore as base64, via stdin so the value never reaches process args.
    base64 -w0 "$keystore" | gh secret set BETA_KEYSTORE_BASE64 -R "$repo"
    # PKCS12 keystores have a single password for both the store and the key, so
    # set the same value under the two names the workflow reads.
    gh secret set BETA_KEYSTORE_PASSWORD -R "$repo" < "$password_file"
    gh secret set BETA_KEY_PASSWORD -R "$repo" < "$password_file"
    printf '%s' "$alias" | gh secret set BETA_KEY_ALIAS -R "$repo"
    echo "==> set BETA_KEYSTORE_BASE64 BETA_KEYSTORE_PASSWORD BETA_KEY_ALIAS BETA_KEY_PASSWORD"
else
    echo "==> run again with --repo <owner/repo> to set the four BETA_* GitHub secrets"
fi

# --- fingerprint -------------------------------------------------------------
# The certificate's SHA-256 fingerprint is this key's stable public identity;
# print it so it can be recorded without ever touching the private key.
fingerprint=$(
    KEYSTORE_PASS="$password" "$keytool" -list -v \
        -keystore "$keystore" \
        -storepass:env KEYSTORE_PASS \
        -alias "$alias" 2>/dev/null |
        sed -nE 's/^[[:space:]]*SHA256:[[:space:]]*([0-9A-Fa-f:]+)$/\1/p' || true
)
if [ -n "$fingerprint" ]; then
    echo "==> SHA-256 fingerprint: $fingerprint"
else
    echo "warning: could not read the certificate fingerprint" >&2
fi
