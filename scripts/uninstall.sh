#!/usr/bin/env bash
# =============================================================================
# scripts/uninstall.sh — Clean removal of AI Brain + OpenClaw hooks
#
# Removes:
#   - The brain directory (~/.openclaw/workspace/brain or custom location)
#   - The OpenClaw decrypt-brain hook (~/.openclaw/hooks/decrypt-brain/)
#   - Workspace symlinks (AGENTS.md, skills/ai-brain)
#   - BOOT.md and TOOLS.md hook entries
#   - The daily update cron job
#
# Does NOT remove:
#   - OpenClaw itself
#   - Other hooks or skills
#
# Usage:
#   bash scripts/uninstall.sh              # from inside the brain directory
#   bash /path/to/brain/scripts/uninstall.sh   # from anywhere
# =============================================================================

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
WORKSPACE="${OPENCLAW_WORKSPACE:-$OPENCLAW_HOME/workspace}"
HOOKS_DIR="$OPENCLAW_HOME/hooks"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[UNINSTALL]${NC} $1"; }
ok()    { echo -e "${GREEN}[UNINSTALL]${NC} $1"; }
warn()  { echo -e "${YELLOW}[UNINSTALL]${NC} $1"; }

echo ""
echo -e "${BOLD}🧠 AI Brain Uninstaller${NC}"
echo "═══════════════════════════════════════"
echo ""

# ─── Confirm ──────────────────────────────────────────────────────────────

echo -e "This will remove the AI Brain from:"
echo -e "  ${BOLD}Brain:${NC}   $BRAIN_DIR"
echo -e "  ${BOLD}Hook:${NC}    $HOOKS_DIR/decrypt-brain/"
echo -e "  ${BOLD}Links:${NC}   $WORKSPACE/AGENTS.md, skills/ai-brain"
echo ""
echo -e "${YELLOW}Client-owned files (brand/, vision/, memory/, custom-playbooks/)${NC}"
echo -e "${YELLOW}will be backed up to ~/brain-backup/ before removal.${NC}"
echo ""
read -rp "Continue? (y/N): " confirm
[ "$confirm" = "y" ] || [ "$confirm" = "Y" ] || { info "Aborted."; exit 0; }

# ─── Backup client-owned content ──────────────────────────────────────────

BACKUP_DIR="$HOME/brain-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
BACKED_UP=0

for dir in brand vision memory custom-playbooks; do
    if [ -d "$BRAIN_DIR/$dir" ]; then
        cp -r "$BRAIN_DIR/$dir" "$BACKUP_DIR/$dir"
        BACKED_UP=1
    fi
done

if [ "$BACKED_UP" -eq 1 ]; then
    ok "Client files backed up to $BACKUP_DIR"
else
    rmdir "$BACKUP_DIR" 2>/dev/null || true
fi

# ─── Remove OpenClaw decrypt hook ────────────────────────────────────────

if [ -d "$HOOKS_DIR/decrypt-brain" ]; then
    rm -rf "$HOOKS_DIR/decrypt-brain"
    ok "Removed decrypt-brain hook"
else
    info "No decrypt-brain hook found (already clean)"
fi

# ─── Remove workspace symlinks ───────────────────────────────────────────

# AGENTS.md symlink
if [ -L "$WORKSPACE/AGENTS.md" ]; then
    rm -f "$WORKSPACE/AGENTS.md"
    ok "Removed AGENTS.md symlink"
fi

# skills/ai-brain symlink
if [ -L "$WORKSPACE/skills/ai-brain" ]; then
    rm -f "$WORKSPACE/skills/ai-brain"
    ok "Removed skills/ai-brain symlink"
fi

# ─── Clean BOOT.md entries ───────────────────────────────────────────────

BOOT_FILE="$WORKSPACE/BOOT.md"
if [ -f "$BOOT_FILE" ] && grep -q "AI Brain Auto-Decrypt" "$BOOT_FILE" 2>/dev/null; then
    # Remove the brain section from BOOT.md
    sed -i.bak '/# AI Brain Auto-Decrypt/,/^$/d' "$BOOT_FILE" 2>/dev/null || \
    sed -i '' '/# AI Brain Auto-Decrypt/,/^$/d' "$BOOT_FILE" 2>/dev/null || true
    rm -f "${BOOT_FILE}.bak"
    ok "Cleaned BOOT.md"
fi

# ─── Clean TOOLS.md entries ──────────────────────────────────────────────

TOOLS_FILE="$WORKSPACE/TOOLS.md"
if [ -f "$TOOLS_FILE" ] && grep -q "AI Brain Reference" "$TOOLS_FILE" 2>/dev/null; then
    sed -i.bak '/## AI Brain Reference/,/^$/d' "$TOOLS_FILE" 2>/dev/null || \
    sed -i '' '/## AI Brain Reference/,/^$/d' "$TOOLS_FILE" 2>/dev/null || true
    rm -f "${TOOLS_FILE}.bak"
    ok "Cleaned TOOLS.md"
fi

# ─── Remove cron job ─────────────────────────────────────────────────────

if crontab -l 2>/dev/null | grep -q "brain.*client-update"; then
    crontab -l 2>/dev/null | grep -v "brain.*client-update" | crontab - 2>/dev/null || true
    ok "Removed daily update cron job"
fi

# ─── Remove brain directory ──────────────────────────────────────────────

if [ -d "$BRAIN_DIR" ]; then
    rm -rf "$BRAIN_DIR"
    ok "Removed brain directory: $BRAIN_DIR"
fi

# ─── Done ─────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   🧠 Brain uninstalled successfully${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════${NC}"
echo ""
if [ "$BACKED_UP" -eq 1 ]; then
    echo -e "  ${BOLD}Backup:${NC} $BACKUP_DIR"
    echo "  Your brand, vision, memory, and custom playbooks are safe."
fi
echo ""
echo "  To reinstall later:"
echo "  curl -sSL .../scripts/client-install.sh | bash -s -- \"Your Name\" YOUR_KEY"
echo ""
