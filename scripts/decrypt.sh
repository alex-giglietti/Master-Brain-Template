#!/usr/bin/env bash
# =============================================================================
# scripts/decrypt.sh — Decrypt content using per-client envelope encryption
#
# KEY RESOLUTION ORDER:
#   0. Dev key:       .brain-config/.dev-key (local testing, skips all other steps)
#   1. Personal key:  .client-key
#   2. Client ID:     .brain-config/.customer-id (derived from personal key SHA256)
#   3. Envelope:      Fetch client-keys/<client_id>.key.enc from git remote → cache
#   4. Unwrap:        Decrypt content key using personal key
#   5. Key server:    .brain-config/.customer-id → keys.multiplyinc.com (fallback)
#
# Then:
#   6. Verify content key fingerprint against .manifest.json
#   7. Use the content key to decrypt all .enc files
#
# If all key resolution fails → subscription disabled → show locked message
# If step 6 fails → content key mismatch → admin must re-encrypt
# =============================================================================

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KEY_FILE="$BRAIN_DIR/.client-key"
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

CONTENT_KEY=""

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

PERSONAL_KEY=""
if [ -z "$CONTENT_KEY" ]; then
    if [ ! -f "$KEY_FILE" ]; then
        err "No personal key found."
        err "Run: curl -sSL .../client-install.sh | bash -s -- YOUR_KEY"
        exit 1
    fi

    PERSONAL_KEY=$(tr -d '[:space:]' < "$KEY_FILE")
    [ -z "$PERSONAL_KEY" ] && { err "Key file is empty."; exit 1; }

    # Write key to temp file so openssl can read via -pass file: (avoids ps exposure)
    printf '%s' "$PERSONAL_KEY" > "$PASS_TMPFILE"
    chmod 600 "$PASS_TMPFILE"
fi

# ─── Step 2: Derive or load client_id ─────────────────────────────────────

CLIENT_ID=""
if [ -f "$CUSTOMER_ID_FILE" ]; then
    CLIENT_ID=$(tr -d '[:space:]' < "$CUSTOMER_ID_FILE")
fi

# If no stored client_id but we have a personal key, derive it
if [ -z "$CLIENT_ID" ] && [ -n "$PERSONAL_KEY" ]; then
    CLIENT_ID=$(printf '%s' "$PERSONAL_KEY" | openssl dgst -sha256 2>/dev/null | awk '{print $NF}' | cut -c1-12)
    # Save for next time
    mkdir -p "$BRAIN_DIR/.brain-config"
    printf '%s' "$CLIENT_ID" > "$CUSTOMER_ID_FILE"
    chmod 600 "$CUSTOMER_ID_FILE"
fi

# ─── Step 3: Fetch wrapped keyfile ───────────────────────────────────────

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

# Skip if we already have the content key (dev mode)
if [ -z "$CONTENT_KEY" ] && [ -n "$CLIENT_ID" ]; then
    # Detect default branch (|| true prevents pipefail from killing the script)
    DEFAULT_BRANCH=$(cd "$BRAIN_DIR" && (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || true)
    DEFAULT_BRANCH="${DEFAULT_BRANCH:-master}"

    info "Fetching your keyfile..."
    if cd "$BRAIN_DIR" && git fetch origin "$DEFAULT_BRANCH" --quiet 2>/dev/null; then
        if git show "origin/${DEFAULT_BRANCH}:client-keys/${CLIENT_ID}.key.enc" > "$FETCHED_KEYFILE" 2>/dev/null; then
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
if [ -z "$CONTENT_KEY" ] && [ -n "$CLIENT_ID" ] && [ -d "$BRAIN_DIR/client-keys" ]; then
    local_keyfile="$BRAIN_DIR/client-keys/${CLIENT_ID}.key.enc"
    if try_unwrap "$local_keyfile"; then
        ok "Using local keyfile."
    fi
fi

# Migration fallback: try all local keyfiles (for old name-based keyfiles)
if [ -z "$CONTENT_KEY" ] && [ -n "$PERSONAL_KEY" ] && [ -d "$BRAIN_DIR/client-keys" ]; then
    for keyfile in "$BRAIN_DIR/client-keys"/*.key.enc; do
        [ -f "$keyfile" ] || continue
        if try_unwrap "$keyfile"; then
            cp "$keyfile" "$CACHED_KEYFILE"
            chmod 600 "$CACHED_KEYFILE"
            ok "Found matching keyfile: $(basename "$keyfile")"
            break
        fi
    done
fi

# Fall back to remote key server (keys.multiplyinc.com)
if [ -z "$CONTENT_KEY" ] && [ -n "$CLIENT_ID" ]; then
    info "Trying key server..."
    KEY_SERVER_URL="${KEY_SERVER_BASE}/${CLIENT_ID}"
    SERVER_RESPONSE=$(curl -sS --max-time 5 "$KEY_SERVER_URL" 2>/dev/null) || SERVER_RESPONSE=""
    if [ -n "$SERVER_RESPONSE" ]; then
        SERVER_KEY=""
        if command -v jq &>/dev/null; then
            SERVER_KEY=$(echo "$SERVER_RESPONSE" | jq -r '.key // .content_key // empty' 2>/dev/null | tr -d '[:space:]')
        fi
        [ -z "$SERVER_KEY" ] && SERVER_KEY=$(echo "$SERVER_RESPONSE" | tr -d '[:space:]')
        if echo "$SERVER_KEY" | grep -qE '^[a-f0-9]{64}$'; then
            CONTENT_KEY="$SERVER_KEY"
            ok "Key retrieved from server."
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
# Content Locked

This content requires an active subscription.

Your encryption key is either invalid, expired, or your subscription has been paused.

**To fix this:**
1. Contact your AI Monetizations admin
2. Get your updated personal key
3. Run: `curl -sSL .../client-install.sh | bash -s -- YOUR_NEW_KEY`

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
                err "The content key does not match the encrypted files."
                err "Contact your admin — they need to re-encrypt and re-issue keys."
                err ""
                err "Key fingerprint in manifest:  $EXPECTED_FP"
                err "Key fingerprint from keyfile: $ACTUAL_FP"
                exit 1
            fi
        fi
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
    -not -path "*/.git/*" -print | wc -l)
TOTAL_ENC=$(echo "$TOTAL_ENC" | tr -cd '0-9')
TOTAL_OK=0; [ -s "$RESULTS_FILE" ] && TOTAL_OK=$(grep -c '^ok$' "$RESULTS_FILE" || true)
TOTAL_FAIL=0; [ -s "$RESULTS_FILE" ] && TOTAL_FAIL=$(grep -c '^fail$' "$RESULTS_FILE" || true)
TOTAL_SKIP=0; [ -s "$RESULTS_FILE" ] && TOTAL_SKIP=$(grep -c '^skip$' "$RESULTS_FILE" || true)

if [ "$TOTAL_FAIL" -gt 0 ] && [ "$TOTAL_OK" -eq 0 ] && [ "$TOTAL_SKIP" -eq 0 ]; then
    err ""
    err "ALL $TOTAL_ENC files failed to decrypt."
    err ""
    err "Content key mismatch. Contact your admin."
    exit 1
else
    ok "Decryption complete. ($((TOTAL_OK + TOTAL_SKIP))/$TOTAL_ENC files)"
fi
