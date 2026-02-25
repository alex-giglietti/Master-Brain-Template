#!/usr/bin/env bash
# =============================================================================
# scripts/decrypt.sh — Decrypt content using per-client envelope encryption
#
# FLOW:
#   1. Read client's personal key from .client-key
#   2. Read client name from .client-name
#   3. Fetch their wrapped keyfile from remote (git) or local cache
#   4. Unwrap (decrypt) the content key using their personal key
#   5. Use the content key to decrypt all .enc files
#
# If step 3-4 fail → subscription is disabled → show locked message
# =============================================================================

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KEY_FILE="$BRAIN_DIR/.client-key"
NAME_FILE="$BRAIN_DIR/.client-name"
CACHED_KEYFILE="$BRAIN_DIR/.cached-keyfile"

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
    err "No personal key found. Run: ./scripts/client-setup.sh \"Your Name\" YOUR_KEY"
    exit 1
fi

PERSONAL_KEY=$(tr -d '[:space:]' < "$KEY_FILE")
[ -z "$PERSONAL_KEY" ] && { err "Key file is empty."; exit 1; }

# ─── Step 2: Load client name ────────────────────────────────────────────

CLIENT_NAME=""
if [ -f "$NAME_FILE" ]; then
    CLIENT_NAME=$(cat "$NAME_FILE" | head -1)
fi

# Migration: if no .client-name exists but local keyfiles do, discover identity
if [ -z "$CLIENT_NAME" ] && [ -d "$BRAIN_DIR/client-keys" ]; then
    info "No client name on file. Identifying from local keyfiles..."

    UNWRAP_TMPFILE_DISC=$(mktemp)
    for keyfile in "$BRAIN_DIR/client-keys"/*.key.enc; do
        [ -f "$keyfile" ] || continue

        if openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter 100000 \
            -in "$keyfile" -out "$UNWRAP_TMPFILE_DISC" \
            -pass "pass:$PERSONAL_KEY" 2>/dev/null; then

            disc_candidate=$(tr -d '[:space:]' < "$UNWRAP_TMPFILE_DISC")
            if echo "$disc_candidate" | grep -qE '^[a-f0-9]{64}$'; then
                CLIENT_NAME=$(basename "$keyfile" .key.enc)
                echo "$CLIENT_NAME" > "$NAME_FILE"
                chmod 600 "$NAME_FILE"
                ok "Identified as: $CLIENT_NAME"
                break
            fi
        fi
    done
    rm -f "$UNWRAP_TMPFILE_DISC"
fi

if [ -z "$CLIENT_NAME" ]; then
    err "No client name found. Run: ./scripts/client-setup.sh \"Your Name\" YOUR_KEY"
    exit 1
fi

# ─── Step 3: Fetch wrapped keyfile ───────────────────────────────────────

CONTENT_KEY=""
UNWRAP_TMPFILE=$(mktemp)
trap "rm -f $UNWRAP_TMPFILE" EXIT

# Attempt to unwrap a keyfile from a given path. Sets CONTENT_KEY on success.
try_unwrap() {
    local keyfile="$1"
    [ -f "$keyfile" ] || return 1

    if openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter 100000 \
        -in "$keyfile" \
        -out "$UNWRAP_TMPFILE" \
        -pass "pass:$PERSONAL_KEY" 2>/dev/null; then

        # Validate: content key should be 64 hex chars
        local candidate
        candidate=$(tr -d '[:space:]' < "$UNWRAP_TMPFILE")
        if echo "$candidate" | grep -qE '^[a-f0-9]{64}$'; then
            CONTENT_KEY="$candidate"
            return 0
        fi
    fi
    return 1
}

FETCHED_KEYFILE=$(mktemp)
trap "rm -f $UNWRAP_TMPFILE $FETCHED_KEYFILE" EXIT

# Try fetching the client's keyfile from the remote repo via git
REMOTE_REACHABLE=false
info "Fetching your keyfile..."
if cd "$BRAIN_DIR" && git fetch origin main --quiet 2>/dev/null; then
    REMOTE_REACHABLE=true
    if git show "origin/main:client-keys/${CLIENT_NAME}.key.enc" > "$FETCHED_KEYFILE" 2>/dev/null; then
        if try_unwrap "$FETCHED_KEYFILE"; then
            # Cache the keyfile for offline use
            cp "$FETCHED_KEYFILE" "$CACHED_KEYFILE"
            chmod 600 "$CACHED_KEYFILE"
            ok "Keyfile fetched and verified."
        fi
    else
        warn "Keyfile not found on remote — subscription may be disabled."
        # Remote is reachable but keyfile is missing: delete cache to enforce lockout
        rm -f "$CACHED_KEYFILE"
    fi
else
    warn "Could not reach remote. Trying cached keyfile..."
fi

# Fall back to cached keyfile only if remote was unreachable
if [ -z "$CONTENT_KEY" ] && [ "$REMOTE_REACHABLE" = false ] && [ -f "$CACHED_KEYFILE" ]; then
    if try_unwrap "$CACHED_KEYFILE"; then
        ok "Using cached keyfile (offline mode)."
    fi
fi

# Fall back to local client-keys/ directory (admin/development use)
if [ -z "$CONTENT_KEY" ] && [ -d "$BRAIN_DIR/client-keys" ]; then
    local_keyfile="$BRAIN_DIR/client-keys/${CLIENT_NAME}.key.enc"
    if try_unwrap "$local_keyfile"; then
        ok "Using local keyfile."
    fi
fi

# ─── Step 4: Decrypt or lock ─────────────────────────────────────────────

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
3. Run: `cd ~/.openclaw/workspace/brain && ./scripts/client-setup.sh "Your Name" YOUR_NEW_KEY`

Your brand, vision, memory, and custom playbooks are still fully accessible.
LOCKED
        warn "LOCKED: ${dec_file#$BRAIN_DIR/}"
    done

    echo ""
    warn "All encrypted content is locked. Client-owned files (brand, vision, memory) still work."
    exit 0
fi

# ─── Step 5: Decrypt all content ─────────────────────────────────────────

ok "Content key unwrapped successfully."

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
