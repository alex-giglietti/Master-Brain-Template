#!/usr/bin/env bash
# =============================================================================
# scripts/setup-openclaw-hook.sh — Wire brain into OpenClaw workspace
#
# This script ensures the brain is loaded by OpenClaw on every session.
# It does this by:
#   1. Symlinking key files into the OpenClaw workspace
#   2. Adding the brain as a skills directory in openclaw.json
#   3. Creating a BOOT.md hook that runs decrypt on gateway start
# =============================================================================

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
WORKSPACE="${OPENCLAW_WORKSPACE:-$OPENCLAW_HOME/workspace}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[HOOK]${NC} $1"; }
ok()    { echo -e "${GREEN}[HOOK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[HOOK]${NC} $1"; }

# ─── Method 1: Symlink AGENTS.md into workspace ───────────────────────────

# If the brain has a decrypted AGENTS.md, symlink it as the workspace AGENTS.md
BRAIN_AGENTS="$BRAIN_DIR/AGENTS.md"
WORKSPACE_AGENTS="$WORKSPACE/AGENTS.md"

if [ -f "$BRAIN_AGENTS" ] && [ ! -L "$WORKSPACE_AGENTS" ]; then
    # Backup existing AGENTS.md if it exists and isn't already our symlink
    if [ -f "$WORKSPACE_AGENTS" ]; then
        cp "$WORKSPACE_AGENTS" "${WORKSPACE_AGENTS}.backup.$(date +%s)"
        warn "Backed up existing AGENTS.md"
    fi
    ln -sf "$BRAIN_AGENTS" "$WORKSPACE_AGENTS"
    ok "Linked AGENTS.md → workspace"
elif [ -L "$WORKSPACE_AGENTS" ]; then
    ok "AGENTS.md already linked"
fi

# ─── Method 2: Add brain as skills directory ──────────────────────────────

# Create a skill manifest in the brain root
SKILL_FILE="$BRAIN_DIR/SKILL.md"
if [ ! -f "$SKILL_FILE" ]; then
    cat > "$SKILL_FILE" << 'EOF'
---
name: ai-brain
description: "Complete AI Chief of Staff operating system. Contains playbooks for ATTRACT/CONVERT/NURTURE marketing, execution systems, factory setup guides, brand voice, business vision, and memory. ALWAYS consult this brain before executing any marketing task, building funnels, writing content, or making business decisions. This is the primary knowledge base."
metadata:
  openclaw:
    emoji: "🧠"
---

# AI Chief of Staff Brain

This skill directory contains everything your AI needs to operate as a Chief of Staff:

## What's Here

- **brand/** — Voice, tone, identity (READ before writing ANY content)
- **vision/** — Business plan, offers, customer avatar (READ before ANY strategy)
- **playbooks/** — Step-by-step guides for marketing execution
  - ATTRACT/ — Paid ads, inbound, outbound, partnerships
  - CONVERT/ — Funnels (page, call, event), workflows
  - NURTURE/ — Email, conversation, community
- **execution/** — Project management, financials, reporting, roles
- **factory/** — Tech stack, API connections, setup guides
- **custom-playbooks/** — Client-specific playbooks and SOPs
- **memory/** — Daily AI memory logs

## How to Use

1. **Before ANY task:** Read vision/ and brand/ for context
2. **For marketing tasks:** Find the right playbook in playbooks/
3. **For operations:** Check execution/
4. **For setup/tech:** Check factory/
5. **Always log** important context to memory/

## Critical Rule

If vision/ or brand/ docs are empty, ASK the owner to complete them before executing marketing tasks. You cannot write in their voice if you don't know their voice.
EOF
    ok "Created SKILL.md for OpenClaw discovery"
fi

# ─── Method 3: Symlink into workspace skills ─────────────────────────────

SKILLS_DIR="$WORKSPACE/skills"
mkdir -p "$SKILLS_DIR"

BRAIN_SKILL_LINK="$SKILLS_DIR/ai-brain"
if [ ! -L "$BRAIN_SKILL_LINK" ]; then
    ln -sf "$BRAIN_DIR" "$BRAIN_SKILL_LINK"
    ok "Linked brain → workspace/skills/ai-brain"
elif [ -L "$BRAIN_SKILL_LINK" ]; then
    ok "Brain skill link already exists"
fi

# ─── Method 4: Create BOOT.md hook for auto-decrypt ──────────────────────

BOOT_FILE="$WORKSPACE/BOOT.md"
BOOT_MARKER="# AI Brain Auto-Decrypt"

# Only add if not already present
if [ -f "$BOOT_FILE" ] && grep -q "$BOOT_MARKER" "$BOOT_FILE" 2>/dev/null; then
    ok "BOOT.md hook already configured"
else
    cat >> "$BOOT_FILE" << EOF

$BOOT_MARKER
On gateway startup, ensure the AI Brain is decrypted and ready:
- Run: \`bash $BRAIN_DIR/scripts/decrypt.sh\`
- Read the brain's SKILL.md to understand the full system
- Check memory/ for recent context
EOF
    ok "Added decrypt hook to BOOT.md"
fi

# ─── Method 5: Create/update the workspace TOOLS.md reference ────────────

TOOLS_FILE="$WORKSPACE/TOOLS.md"
TOOLS_MARKER="## AI Brain Reference"

if [ -f "$TOOLS_FILE" ] && grep -q "$TOOLS_MARKER" "$TOOLS_FILE" 2>/dev/null; then
    ok "TOOLS.md reference already exists"
else
    cat >> "$TOOLS_FILE" << EOF

$TOOLS_MARKER
The AI Brain is loaded from: $BRAIN_DIR
It contains playbooks, brand docs, vision, execution systems, and memory.
Always read the brain's files before executing marketing or business tasks.
Key directories: brand/, vision/, playbooks/, execution/, factory/, memory/
EOF
    ok "Added brain reference to TOOLS.md"
fi

echo ""
ok "OpenClaw integration complete!"
echo -e "  Brain loads automatically on every session via:"
echo -e "  • AGENTS.md (symlinked to workspace)"
echo -e "  • skills/ai-brain/ (skill directory)"
echo -e "  • BOOT.md (auto-decrypt on restart)"
