# [Service/Tool Name] Setup Guide

## Overview
[Brief description of what this service does and why it's part of the stack]

## Prerequisites
- [ ] [Account/access requirement]
- [ ] [Software requirement]
- [ ] [Credential requirement]

## Step 1: Create Account / Access
[Instructions for getting access]

## Step 2: Configure Settings
[Core configuration steps]

## Step 3: Generate API Credentials
[How to create API keys, tokens, or other credentials]

**Store these securely:**
- API Key: Store in `.env` as `[SERVICE]_API_KEY`
- Secret: Store in `.env` as `[SERVICE]_SECRET`

## Step 4: Integrate with OpenClaw
[How to connect this service to the bot]

```python
# Example integration code
import os
SERVICE_KEY = os.getenv("[SERVICE]_API_KEY")
```

## Step 5: Test the Integration
[How to verify everything works]

```bash
# Test command
curl -H "Authorization: Bearer $API_KEY" https://api.service.com/test
```

## Configuration Reference

| Setting | Value | Description |
|---------|-------|-------------|
| [Setting 1] | [Value] | [What it does] |
| [Setting 2] | [Value] | [What it does] |

## Webhook Configuration
- **Endpoint:** `https://your-bot.com/webhooks/[service]`
- **Events:** [List of webhook events to subscribe to]
- **Secret:** Store in `.env` as `[SERVICE]_WEBHOOK_SECRET`

## Troubleshooting

### [Common Issue 1]
**Solution:** [Fix]

### [Common Issue 2]
**Solution:** [Fix]

## Maintenance
- **Token rotation:** [Frequency]
- **Monitoring:** [What to watch]
- **Backup:** [What to back up]

---

*Last updated: [Date]*
