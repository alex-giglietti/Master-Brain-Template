# OpenClaw Brain Integration - Complete Setup Guide

> **Exhaustive step-by-step instructions for connecting your GitHub Master Brain to your OpenClaw bot instance**

## Prerequisites

Before starting, ensure you have:
- [ ] Forked the `aim-master-brain-template` repository to your GitHub account
- [ ] OpenClaw bot deployed and running (see `setup/openclaw.md`)
- [ ] GitHub Personal Access Token (PAT) with `repo` scope
- [ ] Terminal/SSH access to your OpenClaw server
- [ ] Basic familiarity with docker and environment variables

**Time Required:** 30-45 minutes

---

## Part 1: Prepare Your GitHub Repository

### Step 1.1: Fork the Template
1. Go to the template repository URL
2. Click the "Fork" button in top right
3. Select your account as the destination
4. Wait for fork to complete (~30 seconds)

### Step 1.2: Customize Your Fork
1. In your forked repo, click on `config/vision.md`
2. Click the pencil icon (Edit this file)
3. Replace the template content with your actual company information
4. Scroll down and click "Commit changes"
5. Repeat for all files in `/config/`, `/brand/`, and `/playbooks/`

**Pro Tip:** You can bulk edit locally by cloning:
```bash
git clone https://github.com/YOUR_USERNAME/aim-master-brain-template.git
cd aim-master-brain-template
# Edit files with your preferred text editor
git add .
git commit -m "Customized brain for [Your Company]"
git push origin main
```

### Step 1.3: Generate GitHub Access Token
1. Go to https://github.com/settings/tokens
2. Click "Generate new token" -> "Generate new token (classic)"
3. Give it a name: `OpenClaw Bot Access`
4. Set expiration: `No expiration` (or 1 year if security policy requires)
5. Check the scope: `repo` (Full control of private repositories)
6. Scroll down and click "Generate token"
7. **CRITICAL:** Copy the token immediately (starts with `ghp_...`)
8. Save it in your password manager - you won't see it again!

---

## Part 2: Configure OpenClaw to Read from GitHub

### Step 2.1: SSH into Your OpenClaw Server
```bash
# Replace with your actual server IP/domain
ssh user@your-openclaw-server.com

# Navigate to OpenClaw directory
cd /opt/openclaw  # or wherever OpenClaw is installed
```

### Step 2.2: Update Environment Variables
Open the OpenClaw environment file:
```bash
nano .env  # or vi .env if you prefer vim
```

Add the following lines at the bottom:
```bash
# GitHub Brain Configuration
GITHUB_BRAIN_REPO=YOUR_USERNAME/aim-master-brain-template
GITHUB_BRAIN_BRANCH=main
GITHUB_ACCESS_TOKEN=ghp_YOUR_TOKEN_HERE
BRAIN_SYNC_INTERVAL=300  # Sync every 5 minutes (300 seconds)
```

**Replace:**
- `YOUR_USERNAME` with your actual GitHub username
- `ghp_YOUR_TOKEN_HERE` with the token you generated in Step 1.3

Save and exit:
- **Nano:** Press `Ctrl+X`, then `Y`, then `Enter`
- **Vim:** Press `Esc`, type `:wq`, press `Enter`

### Step 2.3: Install the Brain Loader
Copy the `scripts/brain_loader.py` file to your OpenClaw installation directory:
```bash
cp scripts/brain_loader.py /opt/openclaw/brain_loader.py
```

### Step 2.4: Integrate Brain Loader into OpenClaw
Open your OpenClaw agent configuration file:
```bash
nano agent_config.py  # or wherever your agent is configured
```

Add this import at the top:
```python
from brain_loader import brain
```

Now use the brain in your agent's system prompt or tools:
```python
# Example: Load brand voice for responses
brand_voice = brain.get_brand_voice()

# Example: Get specific playbook
lead_qualification = brain.fetch_playbook("convert", "lead-qualification")

# Example: Build system prompt with company context
company_overview = brain.get_company_overview()
system_prompt = f"""
You are an AI assistant for a company with the following background:

{company_overview}

Follow these brand guidelines:
{brand_voice}

Available offers:
{brain.get_offers()}
"""
```

### Step 2.5: Restart OpenClaw
```bash
# If using docker-compose:
docker-compose down
docker-compose up -d

# If using systemd service:
sudo systemctl restart openclaw

# Check logs to confirm brain loaded successfully:
docker logs openclaw-container --tail 50
# or
sudo journalctl -u openclaw -n 50
```

You should see log messages like:
```
INFO:brain_loader:Fetched and cached config/vision.md
INFO:brain_loader:Fetched and cached brand/brand.md
INFO:brain_loader:Using cached version of config/offers.md
```

---

## Part 3: Test the Integration

### Step 3.1: Manual Test
SSH into your OpenClaw server and run:
```bash
cd /opt/openclaw
python3 -c "
from brain_loader import brain
print('Testing brain connection...')
print(brain.get_company_overview()[:200])  # Print first 200 chars
print('Brain connection successful!')
"
```

Expected output: First 200 characters of your vision.md file

### Step 3.2: Test Bot Response
Send a test message to your bot (via Telegram/web interface):
```
"Tell me about your company"
```

The bot should respond with information from your `config/vision.md` file.

### Step 3.3: Test Playbook Usage
Send a sales-related query:
```
"I'm interested in your services, what do you offer?"
```

The bot should use content from `config/offers.md` and potentially `playbooks/convert/`.

---

## Part 4: Ongoing Maintenance

### Updating Your Brain
Whenever you update your GitHub repository, OpenClaw will automatically pull the latest version within 5 minutes (based on `BRAIN_SYNC_INTERVAL`).

To force immediate sync:
```bash
# SSH into server
cd /opt/openclaw
python3 -c "from brain_loader import brain; brain.sync_all()"
```

### Monitoring Brain Health
Add this cron job to check brain connectivity daily:
```bash
crontab -e
```

Add line:
```
0 9 * * * cd /opt/openclaw && python3 -c "from brain_loader import brain; brain.sync_all()" >> /var/log/brain_sync.log 2>&1
```

This runs every day at 9 AM and logs results to `/var/log/brain_sync.log`.

### Troubleshooting

**Problem: Bot gives generic responses instead of using brain**
- Check that brain_loader is imported in agent_config.py
- Verify system prompt includes brain content
- Check logs: `docker logs openclaw-container | grep brain`

**Problem: "Failed to fetch" errors in logs**
- Verify GitHub token is correct in .env
- Check repository is public OR token has `repo` scope
- Test manually: `curl -H "Authorization: token YOUR_TOKEN" https://raw.githubusercontent.com/YOUR_USERNAME/aim-master-brain-template/main/config/vision.md`

**Problem: Bot uses outdated information**
- Clear cache: `rm -rf /tmp/openclaw_brain/*`
- Restart bot: `docker-compose restart`
- Check `BRAIN_SYNC_INTERVAL` isn't too high

**Problem: Rate limiting from GitHub**
- GitHub allows 5,000 API requests/hour with authentication
- Check you're using token (unauthenticated is only 60/hour)
- Increase `BRAIN_SYNC_INTERVAL` if making too many requests

---

## Part 5: Advanced Configuration

### 5.1: Use Different Branches for Staging/Production
```bash
# In .env file:
GITHUB_BRAIN_BRANCH=staging  # For staging bot
GITHUB_BRAIN_BRANCH=main     # For production bot
```

This allows you to test changes in a staging environment before deploying to production.

### 5.2: Multi-Bot Setup (Different Bots, Same Brain)
If you have multiple bots (sales, support, marketing):

**Sales Bot:**
```python
# Only load convert playbooks
sales_scripts = brain.fetch_playbook("convert", "sales-script")
objection_handling = brain.fetch_playbook("convert", "objections")
```

**Support Bot:**
```python
# Only load deliver playbooks
onboarding = brain.fetch_playbook("deliver", "onboarding")
troubleshooting = brain.fetch_playbook("deliver", "troubleshooting")
```

All bots share the same `/brand/` and `/config/` for consistency.

### 5.3: RAG Integration (Advanced)
To use the brain with vector search:

```python
from brain_loader import brain
from langchain.text_splitter import MarkdownTextSplitter
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Qdrant

# Load all brain content
all_content = []
for stage in ["attract", "convert", "nurture", "deliver"]:
    # Fetch all markdown files in each stage
    # (Requires additional logic to list files)
    pass

# Split into chunks
splitter = MarkdownTextSplitter(chunk_size=1000, chunk_overlap=200)
chunks = splitter.split_documents(all_content)

# Create embeddings
embeddings = OpenAIEmbeddings()

# Store in vector database
vectorstore = Qdrant.from_documents(
    chunks,
    embeddings,
    url="localhost",
    collection_name="brain_knowledge"
)

# Now bot can query semantically
query = "How do I handle price objections?"
results = vectorstore.similarity_search(query, k=3)
```

---

## Part 6: Client Handoff Checklist

When delivering to a client, ensure:
- [ ] GitHub repository forked to client's account (or your agency account for DFY)
- [ ] All placeholder content replaced with client's actual info
- [ ] Brand assets uploaded to `/brand/assets/`
- [ ] API connections documented in `/setup/api-connections.md`
- [ ] Client has GitHub PAT saved securely
- [ ] OpenClaw `.env` file configured correctly
- [ ] Brain successfully loading (test with Part 3 steps)
- [ ] Client trained on how to update markdown files
- [ ] Backup scheduled (GitHub repos are auto-backed up, but consider additional backups)
- [ ] Support contact information provided

---

## Support

**Technical Issues:**
- Check OpenClaw logs: `docker logs openclaw-container`
- Review brain sync logs: `cat /var/log/brain_sync.log`
- Test GitHub connectivity: `curl https://raw.githubusercontent.com/YOUR_USERNAME/aim-master-brain-template/main/README.md`

**Strategic Questions:**
- Contact your AI implementation partner
- Refer to repository documentation
- Open GitHub issue in your brain repository

---

## Best Practices

1. **Never Commit Secrets**: Keep API keys in `.env`, never in GitHub
2. **Test in Staging First**: Use branches to test changes before production
3. **Document Everything**: Add comments to your playbooks explaining why decisions were made
4. **Version Major Changes**: Use git tags like `v1.0`, `v2.0` for major updates
5. **Regular Backups**: GitHub is reliable, but maintain external backups of critical content
6. **Monitor Performance**: Track which playbooks the bot uses most, optimize those first
7. **Iterate Based on Data**: Review conversation logs to improve playbooks

---

**Setup Complete!**

Your OpenClaw bot is now powered by your GitHub Master Brain and will automatically stay updated as you evolve your business strategy.
