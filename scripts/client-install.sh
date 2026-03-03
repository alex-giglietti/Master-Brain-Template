#!/usr/bin/env bash
# =============================================================================
# scripts/client-install.sh — One-line installer for clients
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/alex-giglietti/Master-Brain-Template/master/scripts/client-install.sh | bash -s -- YOUR_PERSONAL_KEY
#
# The client_id is derived automatically from the personal key.
# =============================================================================

set -euo pipefail

PERSONAL_KEY="${1:-}"
REPO_URL="${BRAIN_REPO_URL:-https://github.com/alex-giglietti/Master-Brain-Template.git}"
BRAIN_DIR="${BRAIN_DIR:-$HOME/.openclaw/workspace/brain}"
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[BRAIN]${NC} $1"; }
ok()    { echo -e "${GREEN}[BRAIN]${NC} $1"; }
warn()  { echo -e "${YELLOW}[BRAIN]${NC} $1"; }
err()   { echo -e "${RED}[BRAIN]${NC} $1"; }

echo ""
echo -e "${BOLD}🧠 AI Brain Installer${NC}"
echo "═══════════════════════════════════════"
echo ""

if [ -z "$PERSONAL_KEY" ]; then
    err "Missing personal key."
    echo "Usage: curl -sSL .../client-install.sh | bash -s -- YOUR_PERSONAL_KEY"
    echo "Get your key from your AI Monetizations admin."
    exit 1
fi

# Validate key format (64-char hex)
if ! echo "$PERSONAL_KEY" | grep -qE '^[a-fA-F0-9]{64}$'; then
    err "Invalid key format. Key must be a 64-character hex string."
    exit 1
fi

for cmd in git openssl; do
    command -v "$cmd" &>/dev/null || {
        err "$cmd is required."
        exit 1
    }
done

# Derive client_id from personal key (SHA256 hash, first 12 chars)
CLIENT_ID=$(printf '%s' "$PERSONAL_KEY" | openssl dgst -sha256 2>/dev/null | awk '{print $NF}' | cut -c1-12)

# Detect default branch name (master or main)
detect_branch() {
    local dir="$1"
    local branch
    branch=$(cd "$dir" && git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    echo "${branch:-master}"
}

# Clone or pull (sparse checkout excludes admin/ and client-keys/)
if [ -d "$BRAIN_DIR/.git" ]; then
    info "Brain already installed. Updating..."
    cd "$BRAIN_DIR"
    BRANCH=$(detect_branch "$BRAIN_DIR")
    git pull --ff-only origin "$BRANCH" 2>/dev/null || {
        warn "Fast-forward failed. Fetching fresh..."
        git fetch origin "$BRANCH"
        git reset --hard "origin/$BRANCH"
    }
else
    info "Installing brain to $BRAIN_DIR..."
    mkdir -p "$(dirname "$BRAIN_DIR")"
    git clone "$REPO_URL" "$BRAIN_DIR"
    cd "$BRAIN_DIR"

    # Enable sparse checkout to exclude admin tools and client keyfiles
    git sparse-checkout init --no-cone 2>/dev/null || git config core.sparseCheckout true
    if git sparse-checkout set '/*' '!/admin/' '!/client-keys/' 2>/dev/null; then
        : # Modern git sparse-checkout worked
    else
        # Fallback for older git versions
        mkdir -p .git/info
        cat > .git/info/sparse-checkout << 'SPARSE'
/*
!/admin/
!/client-keys/
SPARSE
        git read-tree -mu HEAD
    fi

    ok "Cloned (admin and client-keys excluded)."
fi

# Save personal key
printf '%s' "$PERSONAL_KEY" > "$BRAIN_DIR/.client-key"
chmod 600 "$BRAIN_DIR/.client-key"

# Save client_id
mkdir -p "$BRAIN_DIR/.brain-config"
printf '%s' "$CLIENT_ID" > "$BRAIN_DIR/.brain-config/.customer-id"
chmod 600 "$BRAIN_DIR/.brain-config/.customer-id"
ok "Key saved. Client ID: $CLIENT_ID"

# Decrypt
info "Decrypting content with your key..."
bash "$BRAIN_DIR/scripts/decrypt.sh"

# Install OpenClaw decrypt-brain hook
HOOKS_DIR="$OPENCLAW_HOME/hooks/decrypt-brain"
if [ -d "$BRAIN_DIR/hooks/decrypt-brain" ]; then
    mkdir -p "$HOOKS_DIR"
    cp -r "$BRAIN_DIR/hooks/decrypt-brain/"* "$HOOKS_DIR/"
    ok "Installed decrypt-brain hook to $HOOKS_DIR"
fi

# Set up OpenClaw integration (symlinks, SKILL.md, BOOT.md)
info "Wiring into OpenClaw..."
bash "$BRAIN_DIR/scripts/setup-openclaw-hook.sh" 2>/dev/null || true

# Auto-update cron (daily 4am)
CRON_CMD="cd '$BRAIN_DIR' && bash scripts/client-update.sh >> /tmp/brain-update.log 2>&1"
(crontab -l 2>/dev/null | grep -v "brain.*client-update" ; echo "0 4 * * * $CRON_CMD") | crontab - 2>/dev/null || {
    warn "Couldn't set up auto-update cron. Update manually:"
    echo "  cd $BRAIN_DIR && ./scripts/client-update.sh"
}

echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   🧠 Brain installed successfully!${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Location:${NC}  $BRAIN_DIR"
echo -e "  ${BOLD}Update:${NC}    cd $BRAIN_DIR && ./scripts/client-update.sh"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo "  1. Fill out brand/ and vision/ with your business info"
echo "  2. Read START-HERE.md for the full guide"
echo "  3. Talk to your AI — it's ready!"
echo ""
echo -e "  ${BOLD}Uninstall:${NC} bash $BRAIN_DIR/scripts/uninstall.sh"
echo ""
