#!/usr/bin/env bash
# =============================================================================
# setup-repo.sh — Push Master-Brain-Template to your GitHub repo
#
# Run with Claude Code:
#   bash setup-repo.sh
#
# This will:
#   1. Initialize git repo
#   2. Set up .gitignore to protect secrets
#   3. Commit all files (encrypted content + templates)
#   4. Push to your GitHub remote
#
# BEFORE RUNNING:
#   - Create a repo on GitHub (e.g., Master-Brain-Template)
#   - Have git configured with your credentials
# =============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}🧠 Master Brain Template — GitHub Setup${NC}"
echo "═══════════════════════════════════════"
echo ""

# Check git
if ! command -v git &>/dev/null; then
    echo -e "${RED}git not found. Install it first.${NC}"
    exit 1
fi

# Init repo if needed
if [ ! -d .git ]; then
    git init
    echo -e "${GREEN}[OK]${NC} Git initialized"
fi

# Set main branch
git checkout -b main 2>/dev/null || git checkout main 2>/dev/null || true

# Ensure secrets aren't committed
echo -e "${CYAN}[INFO]${NC} Verifying .gitignore protects secrets..."
for secret in ".client-key" "admin/keys.json" ".source/"; do
    if ! grep -q "$secret" .gitignore 2>/dev/null; then
        echo "$secret" >> .gitignore
        echo -e "${YELLOW}[WARN]${NC} Added $secret to .gitignore"
    fi
done

# Stage everything
git add -A

# Show what's being committed
echo ""
echo -e "${BOLD}Files to commit:${NC}"
git status --short | head -40
TOTAL=$(git status --short | wc -l)
echo "  ($TOTAL files total)"

# Commit
git commit -m "Initial brain template: 26 encrypted playbooks, execution, factory + client templates" 2>/dev/null || {
    echo -e "${YELLOW}Nothing to commit (already up to date)${NC}"
}

echo ""
echo -e "${BOLD}Ready to push!${NC}"
echo ""
echo "Add your remote and push:"
echo "  git remote add origin https://github.com/YOUR_ORG/Master-Brain-Template.git"
echo "  git push -u origin main"
echo ""
echo "Or if remote already exists:"
echo "  git push origin main"
echo ""
echo -e "${BOLD}After pushing, clients install with:${NC}"
echo "  curl -sSL https://raw.githubusercontent.com/YOUR_ORG/Master-Brain-Template/main/scripts/client-install.sh | bash -s -- CLIENT_KEY"
