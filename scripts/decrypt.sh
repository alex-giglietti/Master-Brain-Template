#!/usr/bin/env bash
# =============================================================================
# scripts/decrypt.sh — Decrypt content using per-client envelope encryption
#
# FLOW:
#   1. Read client's personal key from .client-key
#   2. Find their wrapped keyfile in admin/client-keys/<name>.key.enc
#   3. Unwrap (decrypt) the content key using their personal key
#   4. Use the content key to decrypt all .enc files
#
# If step 2-3 fail → subscription is disabled → show locked message
# =============================================================================

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KEY_FILE="$BRAIN_DIR/.client-key"
NAME_FILE="$BRAIN_DIR/.client-name"
CLIENT_KEYS_DIR="$BRAIN_DIR/admin/client-keys"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[DECRYPT]${NC} $1"; }
ok()    { echo -e "${GREEN}[DECRYPT]${NC} $1"; }
warn()  { echo -e "${YELLOW}[DECRYPT]${NC} $1"; }
err()   { echo -e "${RED}[DECRYPT]${NC} $1"; }

# ─── Step 1: Load personal key ───────────────────────────────────────────

if [ ! -f "$KEY_FILE" ]; then
    err "No personal key found. Run: ./scripts/client-setup.sh YOUR_KEY"
    exit 1
fi

PERSONAL_KEY=$(tr -d '[:space:]' < "$KEY_FILE")
[ -z "$PERSONAL_KEY" ] && { err "Key file is empty."; exit 1; }

# ─── Step 2: Find client's wrapped keyfile ────────────────────────────────

CLIENT_NAME=""
if [ -f "$NAME_FILE" ]; then
    CLIENT_NAME=$(tr -d '[:space:]' < "$NAME_FILE")
fi

CONTENT_KEY=""
UNWRAP_TMPFILE=$(mktemp)
trap "rm -f $UNWRAP_TMPFILE" EXIT

# Attempt to unwrap a keyfile. Returns 0 on success (sets CONTENT_KEY).
try_unwrap() {
    local keyfile="$1"
    [ -f "$keyfile" ] || return 1
    
    if openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter 100000 \
        -in "$keyfile" \
        -out "$UNWRAP_TMPFILE" \
        -pass "pass:$PERSONAL_KEY" 2>/dev/null; then
        
        # Validate: content key should be 64 hex chars
        local candidate
        candidate=$(cat "$UNWRAP_TMPFILE" | tr -d '[:space:]')
        if echo "$candidate" | grep -qE '^[a-f0-9]{64}$'; then
            CONTENT_KEY="$candidate"
            return 0
        fi
    fi
    return 1
}

# Try by name first
if [ -n "$CLIENT_NAME" ] && try_unwrap "$CLIENT_KEYS_DIR/${CLIENT_NAME}.key.enc"; then
    : # success, CONTENT_KEY is set
fi

# If that didn't work, try ALL keyfiles (client may not know their name)
if [ -z "$CONTENT_KEY" ]; then
    for keyfile in "$CLIENT_KEYS_DIR"/*.key.enc; do
        [ -f "$keyfile" ] || continue
        
        if try_unwrap "$keyfile"; then
            CLIENT_NAME=$(basename "$keyfile" .key.enc)
            echo "$CLIENT_NAME" > "$NAME_FILE"
            chmod 600 "$NAME_FILE"
            ok "Identified as: $CLIENT_NAME"
            break
        fi
    done
fi

# ─── Step 3: Decrypt or lock ─────────────────────────────────────────────

if [ -z "$CONTENT_KEY" ]; then
    warn "Could not unwrap content key."
    warn "Your subscription may be disabled or your key may be invalid."
    echo ""
    
    # Write locked placeholders for all .enc files
    find "$BRAIN_DIR" -name "*.enc" -type f \
        -not -path "*/client-keys/*" \
        -not -path "*/.git/*" | sort | while IFS= read -r enc_file; do
        
        dec_file="${enc_file%.enc}"
        cat > "$dec_file" << 'LOCKED'
# 🔒 Content Locked

This content requires an active subscription.

Your encryption key is either invalid, expired, or your subscription has been paused.

**To fix this:**
1. Contact your AI Monetizations admin
2. Get your updated personal key
3. Run: `cd ~/.openclaw/workspace/brain && ./scripts/client-setup.sh YOUR_NEW_KEY`

Your brand, vision, memory, and custom playbooks are still fully accessible.
LOCKED
        warn "LOCKED: ${dec_file#$BRAIN_DIR/}"
    done
    
    echo ""
    warn "All encrypted content is locked. Client-owned files (brand, vision, memory) still work."
    exit 0
fi

# ─── Step 4: Decrypt all content ─────────────────────────────────────────

ok "Content key unwrapped successfully."

success=0
failed=0

find "$BRAIN_DIR" -name "*.enc" -type f \
    -not -path "*/client-keys/*" \
    -not -path "*/.git/*" | sort | while IFS= read -r enc_file; do
    
    dec_file="${enc_file%.enc}"
    
    # Skip if already decrypted and newer than .enc
    if [ -f "$dec_file" ] && [ "$dec_file" -nt "$enc_file" ]; then
        continue
    fi
    
    if openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter 100000 \
        -in "$enc_file" -out "$dec_file" \
        -pass "pass:$CONTENT_KEY" 2>/dev/null; then
        ok "${dec_file#$BRAIN_DIR/}"
    else
        warn "FAILED: ${enc_file#$BRAIN_DIR/}"
    fi
done

echo ""
ok "Decryption complete."
