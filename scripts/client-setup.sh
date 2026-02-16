#!/usr/bin/env bash
# =============================================================================
# scripts/client-setup.sh — Save personal key and decrypt
#
# Usage: ./scripts/client-setup.sh YOUR_PERSONAL_KEY
# =============================================================================

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PERSONAL_KEY="${1:-}"

if [ -z "$PERSONAL_KEY" ]; then
    echo -e "\033[0;31m[ERROR]\033[0m Usage: ./scripts/client-setup.sh YOUR_PERSONAL_KEY"
    exit 1
fi

echo "$PERSONAL_KEY" > "$BRAIN_DIR/.client-key"
chmod 600 "$BRAIN_DIR/.client-key"

# Clear cached client name so decrypt re-discovers it
rm -f "$BRAIN_DIR/.client-name"

echo -e "\033[0;32m[OK]\033[0m Key saved. Decrypting..."
bash "$BRAIN_DIR/scripts/decrypt.sh"
