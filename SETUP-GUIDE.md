# AIM Brain Sync — Client Setup Guide

## What This Does

Your AI bot's "brain" lives in a GitHub repository. This system:
- **First time:** Downloads the entire brain (playbooks, brand, config, everything)
- **Updates:** When we push improvements, your bot pulls them automatically
- **Protects your stuff:** Your brand voice, vision, and memories are NEVER overwritten
- **Licensed content:** Premium brain modules (playbooks, SOPs, etc.) are encrypted — your unique BRAIN_KEY unlocks them automatically

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
- [ ] OpenSSL installed (`openssl version`) — needed for content decryption
- [ ] Your **BRAIN_KEY** from AIM (provided when you sign up)

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
export BRAIN_KEY="your-brain-key-here"     # Required — provided by AIM
```

Then reload your shell:

```bash
source ~/.bashrc   # or source ~/.zshrc
```

> **Don't have a BRAIN_KEY?** Contact your AIM implementation partner. Without it, encrypted premium content (playbooks, SOPs, config) cannot be decrypted.

## Step 3: First Sync

```bash
python3 ~/.openclaw/workspace/_master/scripts/brain_sync.py
```

You'll see:
1. Repository being cloned
2. Encrypted modules being decrypted (playbooks, config, execution, setup, scripts)
3. Protected folders being seeded (brand, vision, memory)
4. Sync complete summary

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
0 * * * * BRAIN_KEY="your-key" python3 ~/.openclaw/workspace/_master/scripts/brain_sync.py >> ~/.openclaw/brain_sync.log 2>&1
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
| `brain_sync.py` | Normal sync (decrypt + update) |
| `brain_sync.py --check` | Check for updates |
| `brain_sync.py --force` | Force re-sync (still protects folders) |
| `brain_sync.py --fresh` | Full reinstall (overwrites everything) |
| `brain_sync.py --key <KEY>` | Use a specific key (instead of env var) |

---

## How Encryption Works

Your brain's premium content (playbooks, SOPs, config, integration guides) is stored **encrypted** in GitHub. This protects AIM's intellectual property and ensures only licensed clients can access it.

**What's encrypted:**
- `playbooks/` — Sales scripts, nurture sequences, delivery SOPs
- `config/` — Offers, tech stack, system configuration
- `execution/` — Financials, roles, reporting, project management
- `setup/` — Integration guides (OpenClaw, Telegram, GHL, etc.)
- `scripts/` — Utility scripts

**What's NOT encrypted (always readable):**
- `brand/` — Your brand customizations
- `vision/` — Your company vision
- `memory/` — Bot conversation history
- `_master/` — Sync scripts (need to be readable to bootstrap)
- `manifest.json` — Version info

**The encryption uses:**
- AES-256-CBC (military-grade encryption)
- PBKDF2 key derivation with 100,000 iterations
- OpenSSL (pre-installed on virtually every system)

You never interact with the encryption directly — `brain_sync.py` handles everything automatically when your `BRAIN_KEY` is set.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Git clone failed | Check internet, verify repo URL, check `GITHUB_TOKEN` |
| "BRAIN_KEY is required but not set" | Set `BRAIN_KEY` env var or use `--key` flag |
| "Decryption failed — invalid BRAIN_KEY" | Your key is wrong — contact AIM for a valid key |
| Already up to date (but shouldn't be) | Use `--force` |
| Brand/vision got overwritten | Only happens with `--fresh` — restore from git |
| Bot not using brain content | Check `ls ~/.openclaw/workspace/`, restart gateway |
| openssl not found | Install: `apt install openssl` or `brew install openssl` |
