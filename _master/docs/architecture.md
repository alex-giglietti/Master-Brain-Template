# Master Brain Architecture

## System Overview

The Master Brain system uses a dual-structure approach:

### Template Repository (This Repo)
- Contains master documentation (`/_master/`)
- Contains customizable template (`/template/`)
- Serves as source of truth for all client brains

### Client Fork (Each Client's Repo)
- Fork of this repository
- Customized `/template/` with client-specific content
- Pulls updates from `/_master/` without affecting customizations

## How Bots Access the Brain

```python
# Bot loads brain on startup
from _master.scripts.brain_loader import GitHubBrain

brain = GitHubBrain(
    repo="client-username/their-brain-fork",
    branch="main",
    token=os.getenv("GITHUB_TOKEN")
)

# Fetch specific knowledge
company_info = brain.fetch_file("template/config/vision.md")
sales_script = brain.fetch_playbook("convert", "discovery-call")

# System uses this to build prompts
system_prompt = f"""
You are an AI assistant for: {company_info}

When handling sales calls, follow this script:
{sales_script}
"""
```

## Data Flow

```
User Message
    |
Bot receives message
    |
Bot fetches relevant playbooks from GitHub
    |
Bot builds context-aware prompt
    |
Bot generates response
    |
Response sent to user
    |
Conversation logged to /memory/ (local DB, not GitHub)
```

## Update Mechanism

### Master Template Updates
```bash
# On master template repo
git commit -m "Improved objection handling framework"
git push origin main
```

### Client Pulls Updates
```bash
# On client fork
git remote add upstream https://github.com/original/master-brain-template
git fetch upstream
git merge upstream/main _master/  # Only merges _master/, not template/
```

Client's customized `/template/` content remains untouched.

## Caching Strategy

brain_loader caches files locally to reduce API calls:
- Cache duration: 5 minutes (configurable)
- Cache location: `/tmp/brain_cache/`
- Cache invalidation: Automatic after timeout or manual via `brain.sync_all()`

## Security

- GitHub tokens stored in environment variables
- Never committed to git
- Bot has read-only access to brain repository
- Separate token for each bot instance
