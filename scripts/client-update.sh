#!/usr/bin/env bash
# =============================================================================
# scripts/client-update.sh — Pull latest + decrypt
#
# NEVER touches client-owned directories: brand/, vision/, memory/, custom-playbooks/
# =============================================================================

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCKFILE="$BRAIN_DIR/.update.lock"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[UPDATE]${NC} $1"; }
ok()    { echo -e "${GREEN}[UPDATE]${NC} $1"; }
warn()  { echo -e "${YELLOW}[UPDATE]${NC} $1"; }

# Prevent concurrent updates (cron + manual)
if [ -f "$LOCKFILE" ]; then
    LOCK_PID=$(cat "$LOCKFILE" 2>/dev/null)
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        warn "Another update is running (PID $LOCK_PID). Skipping."
        exit 0
    fi
    rm -f "$LOCKFILE"
fi
echo $$ > "$LOCKFILE"
trap "rm -f '$LOCKFILE'" EXIT

cd "$BRAIN_DIR"
info "Checking for updates..."

# Detect default branch
BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
BRANCH="${BRANCH:-master}"

# Backup client-owned content before any git operations
BACKUP=$(mktemp -d)
for dir in brand vision memory custom-playbooks; do
    [ -d "$BRAIN_DIR/$dir" ] && cp -r "$BRAIN_DIR/$dir" "$BACKUP/$dir"
done
cp "$BRAIN_DIR/.client-key" "$BACKUP/.client-key" 2>/dev/null || true
cp "$BRAIN_DIR/.client-name" "$BACKUP/.client-name" 2>/dev/null || true
cp "$BRAIN_DIR/.cached-keyfile" "$BACKUP/.cached-keyfile" 2>/dev/null || true

# Pull
if git pull --ff-only origin "$BRANCH" 2>/dev/null; then
    ok "Updated to latest."
else
    warn "Fast-forward failed. Resetting to remote..."
    git fetch origin "$BRANCH"
    git reset --hard "origin/$BRANCH"
fi

# Restore client-owned content
for dir in brand vision memory custom-playbooks; do
    if [ -d "$BACKUP/$dir" ]; then
        rm -rf "$BRAIN_DIR/$dir"
        cp -r "$BACKUP/$dir" "$BRAIN_DIR/$dir"
    fi
done
cp "$BACKUP/.client-key" "$BRAIN_DIR/.client-key" 2>/dev/null || true
cp "$BACKUP/.client-name" "$BRAIN_DIR/.client-name" 2>/dev/null || true
cp "$BACKUP/.cached-keyfile" "$BRAIN_DIR/.cached-keyfile" 2>/dev/null || true
rm -rf "$BACKUP"

# Decrypt new content
info "Decrypting..."
bash "$BRAIN_DIR/scripts/decrypt.sh"

# Set up sparse checkout if not configured (one-time migration)
if ! git config --get core.sparseCheckout &>/dev/null || [ "$(git config --get core.sparseCheckout)" != "true" ]; then
    info "Setting up sparse checkout (one-time migration)..."
    git sparse-checkout init --no-cone 2>/dev/null || git config core.sparseCheckout true
    if ! git sparse-checkout set '/*' '!/admin/' '!/client-keys/' 2>/dev/null; then
        mkdir -p .git/info
        cat > .git/info/sparse-checkout << 'SPARSE'
/*
!/admin/
!/client-keys/
SPARSE
        git read-tree -mu HEAD
    fi
    ok "Future updates will exclude admin tools and other clients' keyfiles."
fi

# Ensure OpenClaw hook is still wired
bash "$BRAIN_DIR/scripts/setup-openclaw-hook.sh" 2>/dev/null || true

echo ""
ok "Brain is up to date."
