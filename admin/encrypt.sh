#!/usr/bin/env bash
# =============================================================================
# admin/encrypt.sh — Encrypt source content with the internal content key
#
# This encrypts .source/ files → .enc files using the content key from keys.json.
# The content key itself is wrapped per-client in admin/client-keys/.
#
# Usage: ./admin/encrypt.sh
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/.source"
KEYS_FILE="$REPO_ROOT/admin/keys.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }

for cmd in openssl jq; do
    command -v "$cmd" &>/dev/null || { err "$cmd required."; exit 1; }
done

[ -f "$KEYS_FILE" ] || { err "No keys.json. Run: ./admin/manage-keys.sh init"; exit 1; }
[ -d "$SOURCE_DIR" ] || { err "No .source/ directory."; exit 1; }

CONTENT_KEY=$(jq -r '.content_key // empty' "$KEYS_FILE")
[ -z "$CONTENT_KEY" ] && { err "No content_key in keys.json."; exit 1; }

info "Encrypting source files with content key (AES-256-CBC)..."

# Remove old .enc files (not in .source or .git)
find "$REPO_ROOT" -name "*.enc" -type f \
    -not -path "*/.source/*" \
    -not -path "*/.git/*" \
    -not -path "*/client-keys/*" \
    -delete 2>/dev/null || true

count=0
find "$SOURCE_DIR" -name "*.md" -type f | sort | while IFS= read -r src; do
    rel_path="${src#$SOURCE_DIR/}"
    
    if [ "$rel_path" = "AGENTS.md" ]; then
        dest="$REPO_ROOT/AGENTS.md.enc"
    else
        dest="$REPO_ROOT/${rel_path}.enc"
    fi
    
    mkdir -p "$(dirname "$dest")"
    
    openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 \
        -in "$src" -out "$dest" \
        -pass "pass:$CONTENT_KEY" 2>/dev/null
    
    ok "$rel_path"
done

count=$(find "$REPO_ROOT" -name "*.enc" -type f \
    -not -path "*/.source/*" \
    -not -path "*/.git/*" \
    -not -path "*/client-keys/*" | wc -l | tr -d ' ')

# Update manifest
cat > "$REPO_ROOT/.manifest.json" << EOF
{
  "version": "$(date +%Y.%m.%d)",
  "updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "file_count": $count
}
EOF

echo ""
ok "Encrypted $count files."
echo ""
echo "Next: git add -A && git commit -m 'Update content' && git push"
echo ""
info "Active clients with keyfiles:"
ls -1 "$REPO_ROOT/admin/client-keys/"*.key.enc 2>/dev/null | while read -r f; do
    echo "  ● $(basename "$f" .key.enc)"
done || echo "  (none)"
