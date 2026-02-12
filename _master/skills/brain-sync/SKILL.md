---
name: brain-sync
description: "Pull the Master Brain from GitHub. Clones on first run, pulls updates on subsequent runs. Read-only — no push access."
metadata:
  openclaw:
    emoji: "🧠"
    requires:
      bins: ["git"]
---

# Brain Sync Skill

Pulls the AIM Master Brain into the local OpenClaw workspace.

## What It Does

1. **First run:** Clones the brain repo to `~/.openclaw/brain`
2. **Subsequent runs:** Pulls latest updates from GitHub
3. Local customizations (`brand/`, `vision/`, `memory/`) are never overwritten

## Pull the Brain

If the brain is already cloned, just pull. If not, the client's clone URL (with access token) is stored in the git remote after first clone.

```bash
BRAIN_DIR=~/.openclaw/brain

if [ -d "$BRAIN_DIR/.git" ]; then
  cd "$BRAIN_DIR" && git pull origin main
else
  echo "Brain not found. Run the clone command provided by your AIM partner first."
  echo "Example: git clone https://<TOKEN>@github.com/alex-giglietti/Master-Brain-Template.git ~/.openclaw/brain"
fi
```

## On Bot Startup (BOOT.md)

Add to BOOT.md:

```
- [ ] Pull the brain: sync from GitHub
```

## Via Heartbeat

Add to HEARTBEAT.md:

```
- [ ] If more than 24h since last brain pull, sync from GitHub
```

## What Gets Updated

| Folder | On Pull |
|---|---|
| `playbooks/` | Updated |
| `config/` | Updated |
| `execution/` | Updated |
| `setup/` | Updated |
| `scripts/` | Updated |
| `brand/` | Not tracked in repo — local only |
| `vision/` | Not tracked in repo — local only |
| `memory/` | Not tracked in repo — local only |
