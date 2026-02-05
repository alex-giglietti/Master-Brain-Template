# AIM Master Brain Template

> **A centralized knowledge base system for AI-powered business automation bots**

## What is the Master Brain?

The Master Brain is a GitHub-based knowledge repository that serves as the central "brain" for AI bots (specifically OpenClaw instances). It contains all the business logic, brand guidelines, operational procedures, and strategic playbooks that power intelligent automation agents.

### Why GitHub Instead of Google Drive?

1. **Version Control** - Track every change, roll back mistakes, see what improved performance
2. **Easy API Access** - Bots can fetch knowledge via simple HTTP requests
3. **Fork-able Templates** - Clients get their own copy without touching the original
4. **Collaborative** - Multiple team members can update safely with pull requests
5. **Always Available** - No authentication issues or permission problems for bots

## Repository Structure

### `/config/` - Core Business Configuration
- `vision.md` - Company overview, mission, values, and strategic direction
- `offers.md` - Product/service catalog with pricing and positioning
- `tech-stack.md` - Technology infrastructure and integrations

### `/brand/` - Brand Identity & Assets
- `brand.md` - Brand guidelines, voice, tone, messaging framework
- `social-bios.md` - Pre-written bios for all social platforms
- `assets/` - Logos, favicons, business cards, banners (all visual brand elements)

### `/playbooks/` - Customer Journey Automation
Organized by funnel stage:
- `attract/` - Lead generation, outreach, first contact procedures
- `convert/` - Sales qualification, objection handling, closing strategies
- `nurture/` - Follow-up sequences, relationship building, retention
- `deliver/` - Onboarding, service delivery, customer success protocols

### `/execution/` - Operations & Management
- `roles.md` - Team roles, responsibilities, and reporting structure
- `project-management.md` - Project workflows, milestone tracking, sprint planning
- `financials.md` - Budgets, pricing calculations, revenue tracking
- `reporting.md` - KPIs, dashboards, and reporting procedures

### `/setup/` - Technical Integration Guides
Step-by-step setup instructions for:
- `openclaw.md` - OpenClaw bot deployment and configuration
- `telegram.md` - Telegram bot integration
- `google-workspace.md` - Google Workspace automation
- `ghl.md` - GoHighLevel CRM setup
- `zapier.md` - Zapier workflow connections
- `api-connections.md` - API credentials and webhook configurations

### `/memory/` - Dynamic Conversation History
- Real-time storage for bot conversations and learned preferences
- Not committed to git (in .gitignore) - stored in separate database
- Can be synced back to GitHub for analysis/backup

## Quick Start for Clients

### 1. Fork This Repository
```bash
# Via GitHub UI: Click "Fork" button
# Or via CLI:
gh repo fork aim-master-brain-template --clone
```

### 2. Customize Your Brain
- Update `config/vision.md` with your company info
- Replace `brand/` assets with your logos and colors
- Modify `playbooks/` to match your sales process
- Configure `setup/api-connections.md` with your API keys

### 3. Connect to Your Bot
See [SETUP-GUIDE.md](SETUP-GUIDE.md) for detailed integration instructions.

## How Bots Use This Brain

Your OpenClaw bot (or any AI agent) reads from this repository in real-time:

```python
import requests

# Fetch a playbook
def get_playbook(repo_url, playbook_path):
    url = f"{repo_url}/main/{playbook_path}"
    response = requests.get(url)
    return response.text

# Example: Load sales objection handling
objections = get_playbook(
    "https://raw.githubusercontent.com/yourname/your-brain",
    "playbooks/convert/objection-handling.md"
)
```

The bot uses this knowledge to:
- Answer customer questions accurately
- Follow your specific sales scripts
- Apply your brand voice consistently
- Execute procedures exactly as documented
- Make decisions based on your strategic guidelines

## Keeping Your Brain Updated

### For Done-For-You Clients
Your AI implementation partner maintains your brain. They update playbooks based on performance data and evolving strategies.

### For Done-With-You Clients
You can update files directly:
1. Edit markdown files in GitHub web interface or locally
2. Commit changes with descriptive messages
3. Bot automatically pulls latest version within 5 minutes

### Version Control Best Practices
- Use clear commit messages: "Updated lead qualification criteria"
- Test changes in a staging bot before production
- Create branches for major rewrites
- Tag releases for rollback capability

## Advanced Features

### A/B Testing Playbooks
Create branches to test different approaches:
```bash
git checkout -b test-aggressive-sales-script
# Edit playbooks/convert/sales-script.md
git commit -m "Testing more aggressive close"
```
Point one bot instance to `main` branch, another to `test-aggressive-sales-script`, compare results.

### Multi-Bot Architecture
Different bots can read different sections:
- **Sales Bot** - Reads only `/playbooks/convert/`
- **Support Bot** - Reads only `/playbooks/deliver/`
- **Marketing Bot** - Reads only `/playbooks/attract/`

All sharing the same `/brand/` and `/config/` for consistency.

### RAG Integration
Use this repository as your vector store source:
1. Clone the repo
2. Chunk all markdown files
3. Generate embeddings
4. Store in Pinecone/Qdrant/Weaviate
5. Bot queries vector store for semantic search

## Support

For implementation help:
- **Technical Issues**: Open an issue in this repository
- **Strategic Guidance**: Contact your AI implementation partner
- **Documentation**: See [SETUP-GUIDE.md](SETUP-GUIDE.md)

## License

Proprietary - Licensed to [CLIENT NAME]
Unauthorized copying or distribution prohibited.

---

**Built by AIM** | Powered by AI | Maintained by Humans
