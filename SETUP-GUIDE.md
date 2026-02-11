# AIM Brain Sync — Client Setup Guide

## What This Does

Your AI bot's "brain" lives in a GitHub repository. This system:
- **First time:** Downloads the entire brain (playbooks, brand, config, everything)
- **Updates:** When we push improvements, your bot pulls them automatically
- **Protects your stuff:** Your brand voice, vision, and memories are NEVER overwritten

### What Gets Updated vs Protected

| Your Customizations (SAFE) | Our Updates (AUTO-SYNCED) |
|---|---|
| `brand/` — your brand voice | `playbooks/` — sales scripts |
| `vision/` — your mission & goals | `config/` — system config |
| `memory/` — bot's history | `execution/` — SOPs |
| `USER.md` — who you are | `setup/` — integration guides |
| `IDENTITY.md` — bot personality | `_master/` — system scripts |

---

## Prerequisites

- [ ] OpenClaw installed and running
- [ ] Git installed (`git --version`)
- [ ] Python 3 installed (`python3 --version`)

---

## Step 1: Get the Sync Script

```bash
mkdir -p ~/.openclaw/workspace/_master/scripts
curl -o ~/.openclaw/workspace/_master/scripts/brain_sync.py \
  https://raw.githubusercontent.com/alex-giglietti/Master-Brain-Template/main/_master/scripts/brain_sync.py
chmod +x ~/.openclaw/workspace/_master/scripts/brain_sync.py
```

## Step 2: Configure

Set environment variables (add to `~/.bashrc` or `~/.zshrc`):

```bash
export BRAIN_REPO="alex-giglietti/Master-Brain-Template"
export BRAIN_BRANCH="main"
export GITHUB_TOKEN="ghp_your_token_here"  # Only for private repos
```

## Step 3: First Sync

```bash
python3 ~/.openclaw/workspace/_master/scripts/brain_sync.py
```

You'll see all folders being installed, including brand/vision/memory defaults.

## Step 4: Customize Your Protected Folders

Edit these — they'll never be overwritten by updates:

* `~/.openclaw/workspace/brand/` — Your brand voice and guidelines
* `~/.openclaw/workspace/vision/` — Your company mission and goals
* `~/.openclaw/workspace/USER.md` — Who you are, how bot should address you

## Step 5: Set Up Auto-Sync

### Option A: On bot startup (recommended)

Add to BOOT.md:

```
- [ ] Run brain sync: `python3 ~/.openclaw/workspace/_master/scripts/brain_sync.py`
```

### Option B: Cron (hourly)

```bash
crontab -e
# Add:
0 * * * * python3 ~/.openclaw/workspace/_master/scripts/brain_sync.py >> ~/.openclaw/brain_sync.log 2>&1
```

### Option C: Manual

```bash
python3 ~/.openclaw/workspace/_master/scripts/brain_sync.py          # Sync
python3 ~/.openclaw/workspace/_master/scripts/brain_sync.py --check  # Check only
```

---

## Commands

| Command | What It Does |
|---|---|
| `brain_sync.py` | Normal sync |
| `brain_sync.py --check` | Check for updates |
| `brain_sync.py --force` | Force re-sync (still protects folders) |
| `brain_sync.py --fresh` | Full reinstall (overwrites everything) |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Git clone failed | Check internet, verify repo URL, check `GITHUB_TOKEN` |
| Already up to date (but shouldn't be) | Use `--force` |
| Brand/vision got overwritten | Only happens with `--fresh` — restore from git |
| Bot not using brain content | Check `ls ~/.openclaw/workspace/`, restart gateway |
