---
name: brain-sync
description: "Auto-sync the Master Brain from GitHub. Checks for updates and applies them while protecting user-customized folders (memory, brand, vision)."
metadata:
  openclaw:
    emoji: "🧠"
    requires:
      bins: ["git", "python3"]
---

# Brain Sync Skill

Keeps the OpenClaw workspace in sync with the AIM Master Brain GitHub repo.

## What It Does

1. Checks if a new brain version is available on GitHub
2. Downloads and applies updates to the workspace
3. **Protects** user-customized folders (`memory/`, `brand/`, `vision/`) — NEVER overwritten after first install
4. Updates everything else (playbooks, config, execution, setup, scripts)

## Manual Sync

```bash
python3 {baseDir}/../../scripts/brain_sync.py --workspace ~/.openclaw/workspace
```

## Check for Updates

```bash
python3 {baseDir}/../../scripts/brain_sync.py --check
```

## On Bot Startup (BOOT.md)

Add to BOOT.md:

```
- [ ] Run brain sync: `python3 ~/.openclaw/workspace/_master/scripts/brain_sync.py`
```

## Via Heartbeat

Add to HEARTBEAT.md:

```
- [ ] If more than 24h since last brain sync, run: `python3 ~/.openclaw/workspace/_master/scripts/brain_sync.py`
```

## Protected vs Updated

| Folder | First Install | Updates |
|---|---|---|
| `memory/` | Seeded | Never touched |
| `brand/` | Seeded | Never touched |
| `vision/` | Seeded | Never touched |
| `USER.md` | Seeded | Never touched |
| `IDENTITY.md` | Seeded | Never touched |
| `playbooks/` | Installed | Always updated |
| `config/` | Installed | Always updated |
| `execution/` | Installed | Always updated |
| `setup/` | Installed | Always updated |
| `_master/` | Installed | Always updated |

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `BRAIN_REPO` | GitHub repo (user/repo) | Set in script |
| `BRAIN_BRANCH` | Branch to sync | `main` |
| `GITHUB_TOKEN` | Token for private repos | None |
| `OPENCLAW_WORKSPACE` | Workspace path | `~/.openclaw/workspace` |
