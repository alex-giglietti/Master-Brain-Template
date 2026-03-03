#!/usr/bin/env bash
# =============================================================================
# scripts/decrypt.sh — Decrypt content using per-client envelope encryption
#
# KEY RESOLUTION ORDER:
#   0. Dev key:       .brain-config/.dev-key (local testing, skips all other steps)
#   1. Personal key:  .client-key + .client-name
#   2. Envelope:      Fetch wrapped keyfile from git remote → cached → local
#   3. Unwrap:        Decrypt content key using personal key
#   4. Key server:    .brain-config/.customer-id → keys.multiplyinc.com (fallback)
#
# Then:
#   5. Verify content key fingerprint against .manifest.json
#   6. Use the content key to decrypt all .enc files
#
# If all key resolution fails → subscription disabled → show locked message
# If step 5 fails → content key mismatch → admin must re-encrypt
# =============================================================================

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KEY_FILE="$BRAIN_DIR/.client-key"
NAME_FILE="$BRAIN_DIR/.client-name"
CACHED_KEYFILE="$BRAIN_DIR/.cached-keyfile"
MANIFEST_FILE="$BRAIN_DIR/.manifest.json"
DEV_KEY_FILE="$BRAIN_DIR/.brain-config/.dev-key"
CUSTOMER_ID_FILE="$BRAIN_DIR/.brain-config/.customer-id"
KEY_SERVER_BASE="https://keys.multiplyinc.com/api/keys"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[DECRYPT]${NC} $1"; }
ok()    { echo -e "${GREEN}[DECRYPT]${NC} $1"; }
warn()  { echo -e "${YELLOW}[DECRYPT]${NC} $1"; }
err()   { echo -e "${RED}[DECRYPT]${NC} $1"; }

# ─── Temp files + cleanup ────────────────────────────────────────────────

UNWRAP_TMPFILE=$(mktemp)
FETCHED_KEYFILE=$(mktemp)
PASS_TMPFILE=$(mktemp)
trap "rm -f '$UNWRAP_TMPFILE' '$FETCHED_KEYFILE' '$PASS_TMPFILE'" EXIT

# ─── Step 0: Check for dev key (local testing shortcut) ──────────────────

if [ -f "$DEV_KEY_FILE" ]; then
    DEV_KEY=$(tr -d '[:space:]' < "$DEV_KEY_FILE")
    if echo "$DEV_KEY" | grep -qE '^[a-f0-9]{64}$'; then
        ok "Using dev key from .brain-config/.dev-key"
        CONTENT_KEY="$DEV_KEY"
        # Skip all key resolution — jump straight to decryption
    else
        warn ".dev-key exists but doesn't contain a valid 64-char hex key. Ignoring."
    fi
fi

# ─── Step 1: Load personal key ───────────────────────────────────────────

if [ -z "${CONTENT_KEY:-}" ] && [ ! -f "$KEY_FILE" ]; then
    err "No personal key found. Run: ./scripts/client-setup.sh \"Your Name\" YOUR_KEY"
    exit 1
fi

PERSONAL_KEY=""
if [ -z "${CONTENT_KEY:-}" ] && [ -f "$KEY_FILE" ]; then
    PERSONAL_KEY=$(tr -d '[:space:]' < "$KEY_FILE")
    [ -z "$PERSONAL_KEY" ] && { err "Key file is empty."; exit 1; }

    # Write key to temp file so openssl can read via -pass file: (avoids ps exposure)
    printf '%s' "$PERSONAL_KEY" > "$PASS_TMPFILE"
    chmod 600 "$PASS_TMPFILE"
fi

# ─── Step 2: Load client name ────────────────────────────────────────────

CLIENT_NAME=""
if [ -f "$NAME_FILE" ]; then
    CLIENT_NAME=$(tr -d '\n\r' < "$NAME_FILE")
fi

# Migration: if no .client-name exists but local keyfiles do, discover identity.
# Also sets CONTENT_KEY directly to avoid a redundant re-unwrap.
# (Skip if content key already resolved via dev key or key server)
if [ -z "${CONTENT_KEY:-}" ] && [ -z "$CLIENT_NAME" ] && [ -n "$PERSONAL_KEY" ] && [ -d "$BRAIN_DIR/client-keys" ]; then
    info "No client name on file. Identifying from local keyfiles..."

    for keyfile in "$BRAIN_DIR/client-keys"/*.key.enc; do
        [ -f "$keyfile" ] || continue

        if openssl enc -aes-256-cbc -md sha256 -d -salt -pbkdf2 -iter 100000 \
            -in "$keyfile" -out "$UNWRAP_TMPFILE" \
            -pass "file:$PASS_TMPFILE" 2>/dev/null; then

            disc_candidate=$(tr -d '[:space:]' < "$UNWRAP_TMPFILE")
            if echo "$disc_candidate" | grep -qE '^[a-f0-9]{64}$'; then
                CLIENT_NAME=$(basename "$keyfile" .key.enc)
                CONTENT_KEY="$disc_candidate"
                printf '%s' "$CLIENT_NAME" > "$NAME_FILE"
                chmod 600 "$NAME_FILE"
                # Cache the keyfile for future use (after sparse checkout removes local)
                cp "$keyfile" "$CACHED_KEYFILE"
                chmod 600 "$CACHED_KEYFILE"
                ok "Identified as: $CLIENT_NAME"
                break
            fi
        fi
    done
fi

# Client name is required for envelope key resolution, but not for dev-key or key-server paths
if [ -z "${CONTENT_KEY:-}" ] && [ -z "$CLIENT_NAME" ]; then
    err "No client name found. Run: ./scripts/client-setup.sh \"Your Name\" YOUR_KEY"
    exit 1
fi

# ─── Step 3: Fetch wrapped keyfile ───────────────────────────────────────

# CONTENT_KEY may already be set from migration discovery above
CONTENT_KEY="${CONTENT_KEY:-}"

# Attempt to unwrap a keyfile. Tries -md sha256 first, then without for
# backward compatibility with keyfiles wrapped before the -md flag was added.
try_unwrap() {
    local keyfile="$1"
    [ -f "$keyfile" ] || return 1

    local candidate

    # Try with explicit -md sha256 (current standard)
    if openssl enc -aes-256-cbc -md sha256 -d -salt -pbkdf2 -iter 100000 \
        -in "$keyfile" -out "$UNWRAP_TMPFILE" \
        -pass "file:$PASS_TMPFILE" 2>/dev/null; then

        candidate=$(tr -d '[:space:]' < "$UNWRAP_TMPFILE")
        if echo "$candidate" | grep -qE '^[a-f0-9]{64}$'; then
            CONTENT_KEY="$candidate"
            return 0
        fi
        # -md sha256 decrypted successfully but output isn't a valid key.
        # Do NOT try the fallback — this means the keyfile contents are wrong.
        return 1
    fi

    # Fallback: try without -md flag (only if -md sha256 decrypt itself FAILED)
    if openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter 100000 \
        -in "$keyfile" -out "$UNWRAP_TMPFILE" \
        -pass "file:$PASS_TMPFILE" 2>/dev/null; then

        candidate=$(tr -d '[:space:]' < "$UNWRAP_TMPFILE")
        if echo "$candidate" | grep -qE '^[a-f0-9]{64}$'; then
            CONTENT_KEY="$candidate"
            return 0
        fi
    fi

    return 1
}

# Skip remote fetch if we already have the key from migration
if [ -z "$CONTENT_KEY" ]; then
    # Detect default branch
    DEFAULT_BRANCH=$(cd "$BRAIN_DIR" && git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    DEFAULT_BRANCH="${DEFAULT_BRANCH:-master}"

    info "Fetching your keyfile..."
    if cd "$BRAIN_DIR" && git fetch origin "$DEFAULT_BRANCH" --quiet 2>/dev/null; then
        if git show "origin/${DEFAULT_BRANCH}:client-keys/${CLIENT_NAME}.key.enc" > "$FETCHED_KEYFILE" 2>/dev/null; then
            if try_unwrap "$FETCHED_KEYFILE"; then
                cp "$FETCHED_KEYFILE" "$CACHED_KEYFILE"
                chmod 600 "$CACHED_KEYFILE"
                ok "Keyfile fetched and verified."
            fi
        else
            warn "Keyfile not found on remote — subscription may be disabled."
        fi
    else
        warn "Could not reach remote. Trying cached keyfile..."
    fi
fi

# Fall back to cached keyfile if remote fetch didn't work
if [ -z "$CONTENT_KEY" ] && [ -f "$CACHED_KEYFILE" ]; then
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

# Fall back to remote key server (keys.multiplyinc.com)
if [ -z "$CONTENT_KEY" ] && [ -f "$CUSTOMER_ID_FILE" ]; then
    CUSTOMER_ID=$(tr -d '[:space:]' < "$CUSTOMER_ID_FILE")
    if [ -n "$CUSTOMER_ID" ]; then
        info "Trying key server..."
        KEY_SERVER_URL="${KEY_SERVER_BASE}/${CUSTOMER_ID}"
        SERVER_RESPONSE=$(curl -sS --max-time 5 "$KEY_SERVER_URL" 2>/dev/null) || SERVER_RESPONSE=""
        if [ -n "$SERVER_RESPONSE" ]; then
            # Try to extract key from JSON response ({"key": "..."} or {"content_key": "..."})
            if command -v jq &>/dev/null; then
                SERVER_KEY=$(echo "$SERVER_RESPONSE" | jq -r '.key // .content_key // empty' 2>/dev/null | tr -d '[:space:]')
            else
                # Fallback: try raw response as hex key
                SERVER_KEY=$(echo "$SERVER_RESPONSE" | tr -d '[:space:]"{}:keycontnt_')
            fi
            # If jq extraction failed, try raw response
            [ -z "$SERVER_KEY" ] && SERVER_KEY=$(echo "$SERVER_RESPONSE" | tr -d '[:space:]')
            if echo "$SERVER_KEY" | grep -qE '^[a-f0-9]{64}$'; then
                CONTENT_KEY="$SERVER_KEY"
                ok "Key retrieved from server."
            fi
        fi
    fi
fi

# ─── Step 4: Decrypt or lock ─────────────────────────────────────────────

if [ -z "$CONTENT_KEY" ]; then
    warn "Could not unwrap content key."
    warn "Your subscription may be disabled or your key may be invalid."
    echo ""

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

# ─── Step 5: Verify content key fingerprint ──────────────────────────────

ok "Content key unwrapped successfully."

if [ -f "$MANIFEST_FILE" ]; then
    if command -v jq &>/dev/null; then
        EXPECTED_FP=$(jq -r '.key_fingerprint // empty' "$MANIFEST_FILE" 2>/dev/null)
        if [ -n "$EXPECTED_FP" ]; then
            ACTUAL_FP=$(printf '%s' "$CONTENT_KEY" | openssl dgst -sha256 2>/dev/null | awk '{print $NF}' | cut -c1-16)
            if [ "$EXPECTED_FP" != "$ACTUAL_FP" ]; then
                err ""
                err "CONTENT KEY MISMATCH DETECTED"
                err ""
                err "Your keyfile was wrapped with a different content key than"
                err "what was used to encrypt the content files."
                err ""
                err "This usually means the admin ran encrypt.sh and manage-keys.sh"
                err "with different keys.json files (e.g. on different machines)."
                err ""
                err "The admin needs to re-run on a SINGLE machine:"
                err "  1. ./admin/manage-keys.sh init    (or use existing keys.json)"
                err "  2. ./admin/encrypt.sh              (re-encrypt content)"
                err "  3. Re-add all clients with manage-keys.sh add"
                err "  4. git add -A && git commit && git push"
                err ""
                err "Key fingerprint in manifest:  $EXPECTED_FP"
                err "Key fingerprint from keyfile: $ACTUAL_FP"
                exit 1
            fi
        fi
    else
        warn "jq not installed — skipping key fingerprint verification."
        warn "Install jq for automatic key mismatch detection."
    fi
fi

# ─── Step 6: Decrypt all content ─────────────────────────────────────────

# Write content key to temp file for -pass file: (avoids ps exposure)
CONTENT_PASS_TMPFILE=$(mktemp)
trap "rm -f '$UNWRAP_TMPFILE' '$FETCHED_KEYFILE' '$PASS_TMPFILE' '$CONTENT_PASS_TMPFILE'" EXIT
printf '%s' "$CONTENT_KEY" > "$CONTENT_PASS_TMPFILE"
chmod 600 "$CONTENT_PASS_TMPFILE"

# Track results via temp file (avoids subshell variable scope issue)
RESULTS_FILE=$(mktemp)
trap "rm -f '$UNWRAP_TMPFILE' '$FETCHED_KEYFILE' '$PASS_TMPFILE' '$CONTENT_PASS_TMPFILE' '$RESULTS_FILE'" EXIT

find "$BRAIN_DIR" -name "*.enc" -type f \
    -not -path "*/client-keys/*" \
    -not -path "*/.git/*" | sort | while IFS= read -r enc_file; do

    dec_file="${enc_file%.enc}"

    # Skip if already decrypted and newer than .enc
    if [ -f "$dec_file" ] && [ "$dec_file" -nt "$enc_file" ]; then
        echo "skip" >> "$RESULTS_FILE"
        continue
    fi

    # Try with -md sha256 first (current standard), then without (backward compat)
    if openssl enc -aes-256-cbc -md sha256 -d -salt -pbkdf2 -iter 100000 \
        -in "$enc_file" -out "$dec_file" \
        -pass "file:$CONTENT_PASS_TMPFILE" 2>/dev/null; then
        ok "${dec_file#$BRAIN_DIR/}"
        echo "ok" >> "$RESULTS_FILE"
    elif openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter 100000 \
        -in "$enc_file" -out "$dec_file" \
        -pass "file:$CONTENT_PASS_TMPFILE" 2>/dev/null; then
        ok "${dec_file#$BRAIN_DIR/} (legacy)"
        echo "ok" >> "$RESULTS_FILE"
    else
        rm -f "$dec_file"
        warn "FAILED: ${enc_file#$BRAIN_DIR/}"
        echo "fail" >> "$RESULTS_FILE"
    fi
done

echo ""

# Count results
TOTAL_ENC=$(find "$BRAIN_DIR" -name "*.enc" -type f \
    -not -path "*/client-keys/*" \
    -not -path "*/.git/*" | wc -l | tr -d ' ')
TOTAL_OK=$(grep -c '^ok$' "$RESULTS_FILE" 2>/dev/null || echo 0)
TOTAL_FAIL=$(grep -c '^fail$' "$RESULTS_FILE" 2>/dev/null || echo 0)
TOTAL_SKIP=$(grep -c '^skip$' "$RESULTS_FILE" 2>/dev/null || echo 0)

if [ "$TOTAL_FAIL" -gt 0 ] && [ "$TOTAL_OK" -eq 0 ] && [ "$TOTAL_SKIP" -eq 0 ]; then
    err ""
    err "ALL $TOTAL_ENC files failed to decrypt."
    err ""
    err "Your keyfile unwrapped successfully, but the content key does not"
    err "match the encrypted files. This is a key mismatch on the admin side."
    err ""
    err "ADMIN: Re-encrypt content and re-wrap keyfiles from the SAME keys.json."
    err "  1. Ensure admin/keys.json has the correct content_key"
    err "  2. Run: ./admin/encrypt.sh"
    err "  3. Re-add clients: ./admin/manage-keys.sh add <name> <email>"
    err "  4. Commit and push"
    exit 1
else
    ok "Decryption complete. ($((TOTAL_OK + TOTAL_SKIP))/$TOTAL_ENC files)"
fi
