# AIM Master Brain

> **A centralized knowledge base for AI-powered business automation bots**

## What is the Master Brain?

The Master Brain is a GitHub repository that serves as the central "brain" for your OpenClaw AI bot. It contains all the business logic, brand guidelines, operational procedures, and strategic playbooks that power your intelligent automation agents.

### Why GitHub?

1. **Version Control** — Track every change, roll back mistakes, see what improved performance
2. **Easy API Access** — Bots can fetch knowledge via simple HTTP requests
3. **Always Available** — No authentication issues or permission problems for bots
4. **Simple Updates** — When AIM pushes improvements, your bot pulls them with one command

## For Clients: Getting the Brain

Your AIM partner will give you a one-line clone command with access built in. Just run it.

### Pull the Brain

```bash
git clone https://<ACCESS_TOKEN>@github.com/alex-giglietti/Master-Brain-Template.git ~/.openclaw/brain
```

> **Note:** Replace `<ACCESS_TOKEN>` with the token provided by your AIM partner. You only need it once — git remembers it after cloning.

That's it. Your bot now has the full brain locally.

### Get Updates

```bash
cd ~/.openclaw/brain && git pull origin main
```

Or tell your OpenClaw bot: **"Pull the brain"** — it knows what to do.

### What You Can Customize

After cloning, these folders are yours to edit locally:

- `brand/` — Your brand voice, logos, and guidelines
- `vision/` — Your company mission and goals
- `memory/` — Bot conversation history (local-only, not in repo)

These are never overwritten when you pull updates because they're your local files.

## Repository Structure

### `/config/` — Core Business Configuration
- `vision.md` — Company overview, mission, values, and strategic direction
- `offers.md` — Product/service catalog with pricing and positioning
- `tech-stack.md` — Technology infrastructure and integrations

### `/brand/` — Brand Identity & Assets
- `brand.md` — Brand guidelines, voice, tone, messaging framework
- `social-bios.md` — Pre-written bios for all social platforms
- `assets/` — Logos, favicons, business cards, banners

### `/playbooks/` — Customer Journey Automation
Organized by funnel stage:
- `attract/` — Lead generation, outreach, first contact procedures
- `convert/` — Sales qualification, objection handling, closing strategies
- `nurture/` — Follow-up sequences, relationship building, retention
- `deliver/` — Onboarding, service delivery, customer success protocols

### `/execution/` — Operations & Management
- `roles.md` — Team roles, responsibilities, and reporting structure
- `project-management.md` — Project workflows, milestone tracking, sprint planning
- `financials.md` — Budgets, pricing calculations, revenue tracking
- `reporting.md` — KPIs, dashboards, and reporting procedures

### `/setup/` — Technical Integration Guides
- `openclaw.md` — OpenClaw bot deployment and configuration
- `telegram.md` — Telegram bot integration
- `google-workspace.md` — Google Workspace automation
- `ghl.md` — GoHighLevel CRM setup
- `zapier.md` — Zapier workflow connections
- `api-connections.md` — API credentials and webhook configurations

### `/scripts/` — Utility Scripts
- `brain_loader.py` — Load brain content into bots
- `sync-from-drive.py` — Google Drive sync tool
- `validate-brain.py` — Content validation

### `/memory/` — Dynamic Conversation History
- Local-only storage for bot conversations and learned preferences
- Not tracked in git — each bot instance maintains its own

## How Bots Use This Brain

Your OpenClaw bot reads from its local clone:

```python
# Bot reads playbook from local brain
with open("~/.openclaw/brain/playbooks/convert/README.md") as f:
    sales_playbook = f.read()
```

The bot uses this knowledge to:
- Answer customer questions accurately
- Follow your specific sales scripts
- Apply your brand voice consistently
- Execute procedures exactly as documented

## Keeping the Brain Updated

### For Done-For-You Clients
Your AI implementation partner maintains the brain. They push improvements based on performance data and evolving strategies. Your bot picks them up on next pull.

### For Done-With-You Clients
You can suggest changes by contacting your AIM partner. The repo is read-only for clients to ensure consistency.

### Auto-Sync on Bot Startup

Add to your OpenClaw BOOT.md:

```
- [ ] Pull latest brain: `cd ~/.openclaw/brain && git pull origin main`
```

Or set up a cron job:

```bash
# Pull brain updates every hour
0 * * * * cd ~/.openclaw/brain && git pull origin main >> ~/.openclaw/brain_sync.log 2>&1
```

## Advanced Features

### Multi-Bot Architecture
Different bots can read different sections:
- **Sales Bot** — Reads `/playbooks/convert/`
- **Support Bot** — Reads `/playbooks/deliver/`
- **Marketing Bot** — Reads `/playbooks/attract/`

All sharing the same `/brand/` and `/config/` for consistency.

### RAG Integration
Use this repository as your vector store source:
1. Clone the brain
2. Chunk all markdown files
3. Generate embeddings
4. Store in Pinecone/Qdrant/Weaviate
5. Bot queries vector store for semantic search

## Support

- **Technical Issues**: Open an issue in this repository
- **Strategic Guidance**: Contact your AI implementation partner

---

**Built by AIM** | Powered by AI | Maintained by Humans
