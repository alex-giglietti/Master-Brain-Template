#!/usr/bin/env bash
# =============================================================================
# scripts/client-setup.sh — Save personal key + re-decrypt
#
# Usage: ./scripts/client-setup.sh YOUR_PERSONAL_KEY
#
# Used when a client gets a new key (re-enabled, rotated, etc.)
# =============================================================================

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PERSONAL_KEY="${1:-}"

if [ -z "$PERSONAL_KEY" ]; then
    echo -e "\033[0;31m[ERROR]\033[0m Usage: ./scripts/client-setup.sh YOUR_PERSONAL_KEY"
    exit 1
fi

# Validate key format (64-char hex)
if ! echo "$PERSONAL_KEY" | grep -qE '^[a-fA-F0-9]{64}$'; then
    echo -e "\033[0;31m[ERROR]\033[0m Invalid key format. Key must be a 64-character hex string."
    exit 1
fi

# Save personal key
printf '%s' "$PERSONAL_KEY" > "$BRAIN_DIR/.client-key"
chmod 600 "$BRAIN_DIR/.client-key"

# Derive and save client_id
CLIENT_ID=$(printf '%s' "$PERSONAL_KEY" | openssl dgst -sha256 2>/dev/null | awk '{print $NF}' | cut -c1-12)
mkdir -p "$BRAIN_DIR/.brain-config"
printf '%s' "$CLIENT_ID" > "$BRAIN_DIR/.brain-config/.customer-id"
chmod 600 "$BRAIN_DIR/.brain-config/.customer-id"

# Clear cached keyfile and stale decrypted files so decrypt starts fresh
rm -f "$BRAIN_DIR/.cached-keyfile"
find "$BRAIN_DIR" -name "*.enc" -type f \
    -not -path "*/client-keys/*" \
    -not -path "*/.git/*" | while IFS= read -r enc_file; do
    rm -f "${enc_file%.enc}"
done

echo -e "\033[0;32m[OK]\033[0m Key saved (ID: $CLIENT_ID). Decrypting..."
bash "$BRAIN_DIR/scripts/decrypt.sh"
