#!/usr/bin/env bash
# =============================================================================
# scripts/client-setup.sh — Save client name + personal key, then decrypt
#
# Usage: ./scripts/client-setup.sh "Your Name" YOUR_PERSONAL_KEY
# =============================================================================

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLIENT_NAME="${1:-}"
PERSONAL_KEY="${2:-}"

if [ -z "$CLIENT_NAME" ] || [ -z "$PERSONAL_KEY" ]; then
    echo -e "\033[0;31m[ERROR]\033[0m Usage: ./scripts/client-setup.sh \"Your Name\" YOUR_PERSONAL_KEY"
    exit 1
fi

# Save client name (printf avoids trailing newline)
printf '%s' "$CLIENT_NAME" > "$BRAIN_DIR/.client-name"
chmod 600 "$BRAIN_DIR/.client-name"

# Save personal key
printf '%s' "$PERSONAL_KEY" > "$BRAIN_DIR/.client-key"
chmod 600 "$BRAIN_DIR/.client-key"

# Clear cached keyfile and stale decrypted files so decrypt starts fresh
rm -f "$BRAIN_DIR/.cached-keyfile"
find "$BRAIN_DIR" -name "*.enc" -type f \
    -not -path "*/client-keys/*" \
    -not -path "*/.git/*" | while IFS= read -r enc_file; do
    rm -f "${enc_file%.enc}"
done

echo -e "\033[0;32m[OK]\033[0m Key saved for $CLIENT_NAME. Decrypting..."
bash "$BRAIN_DIR/scripts/decrypt.sh"
