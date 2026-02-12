# AIM Brain — Client Setup Guide

## What This Does

Your AI bot's "brain" lives in a GitHub repository. Your OpenClaw instance clones it directly onto its own machine for fast, local access. No keys, no tokens, no accounts needed.

- **First time:** Clone the brain — gets everything instantly
- **Updates:** Pull to get the latest playbooks, SOPs, and configs
- **Your stuff stays safe:** Brand, vision, and memory are local-only and never overwritten

## Step 1: Pull the Brain

Tell your OpenClaw bot:

> "Pull the brain"

Or run manually:

```bash
git clone https://github.com/alex-giglietti/Master-Brain-Template.git ~/.openclaw/brain
```

Done. The entire brain is now on your machine.

## Step 2: Get Updates

```bash
cd ~/.openclaw/brain && git pull origin main
```

Or just tell your bot to pull the brain again — it will update automatically.

## Step 3: Customize Your Stuff

These folders are yours. Edit them however you want — updates will never touch them:

| Folder | What It Is |
|---|---|
| `brand/` | Your brand voice, logos, guidelines |
| `vision/` | Your company mission and goals |
| `memory/` | Bot conversation history (local-only) |

## Step 4: Auto-Sync (Optional)

### On Bot Startup

Add to your BOOT.md:

```
- [ ] Pull latest brain: `cd ~/.openclaw/brain && git pull origin main`
```

### Hourly Cron

```bash
0 * * * * cd ~/.openclaw/brain && git pull origin main >> ~/.openclaw/brain_sync.log 2>&1
```

---

## What's in the Brain

| Folder | Contents | Updated by AIM? |
|---|---|---|
| `playbooks/` | Sales scripts, nurture sequences, delivery SOPs | Yes |
| `config/` | Offers, tech stack, system configuration | Yes |
| `execution/` | Financials, roles, reporting, project management | Yes |
| `setup/` | Integration guides (OpenClaw, Telegram, GHL, etc.) | Yes |
| `scripts/` | Utility scripts | Yes |
| `brand/` | Your brand customizations | No — yours |
| `vision/` | Your company vision | No — yours |
| `memory/` | Bot conversation history | No — local only |

## Troubleshooting

| Problem | Fix |
|---|---|
| `git clone` failed | Check internet connection, verify the repo URL |
| `git pull` has conflicts | You edited a file AIM also updated — run `git checkout -- <file>` to accept AIM's version, or merge manually |
| Bot not using brain content | Check `ls ~/.openclaw/brain/`, restart the bot |
| Want to reset everything | Delete and re-clone: `rm -rf ~/.openclaw/brain && git clone ...` |

## Important: Read-Only

This repo is **read-only** for clients. You can pull updates but cannot push changes back. This ensures all clients get consistent, tested content from AIM.

If you need something changed, contact your AIM implementation partner.
