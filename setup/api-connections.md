# API Connections Reference

> Centralized documentation for all API credentials and integrations

## Security Warning

**NEVER store actual credentials in this file.**

This document serves as a reference for what credentials exist and how to use them. Actual values should be stored in:
- Environment variables
- Secrets manager (AWS Secrets Manager, HashiCorp Vault, etc.)
- Encrypted .env files (not committed to git)

## Credential Inventory

### LLM Providers

| Provider | Variable Name | Documentation |
|----------|---------------|---------------|
| OpenAI | `OPENAI_API_KEY` | [OpenAI Docs](https://platform.openai.com/docs) |
| Anthropic | `ANTHROPIC_API_KEY` | [Anthropic Docs](https://docs.anthropic.com) |

### Communication Platforms

| Platform | Variable Name | Documentation |
|----------|---------------|---------------|
| Telegram | `TELEGRAM_BOT_TOKEN` | [Telegram Bot API](https://core.telegram.org/bots/api) |
| Slack | `SLACK_BOT_TOKEN` | [Slack API](https://api.slack.com) |

### CRM & Marketing

| Platform | Variable Name | Documentation |
|----------|---------------|---------------|
| GoHighLevel | `GHL_API_KEY` | [GHL API](https://highlevel.stoplight.io/) |
| HubSpot | `HUBSPOT_API_KEY` | [HubSpot API](https://developers.hubspot.com) |

### Google Services

| Service | Credential Type | Variable/File |
|---------|-----------------|---------------|
| Gmail | OAuth 2.0 | `GOOGLE_CREDENTIALS_JSON` |
| Calendar | OAuth 2.0 | (same as Gmail) |
| Drive | OAuth 2.0 | (same as Gmail) |
| Sheets | OAuth 2.0 | (same as Gmail) |

### Automation

| Platform | Variable Name | Notes |
|----------|---------------|-------|
| Zapier | Webhook URLs | Per-zap basis |
| Make | `MAKE_API_KEY` | If using API |

### GitHub (Brain)

| Purpose | Variable Name |
|---------|---------------|
| Repository | `GITHUB_BRAIN_REPO` |
| Branch | `GITHUB_BRAIN_BRANCH` |
| Access Token | `GITHUB_ACCESS_TOKEN` |

## Environment File Template

```bash
# .env template - copy to .env and fill in values

# ===================
# LLM PROVIDERS
# ===================
OPENAI_API_KEY=
ANTHROPIC_API_KEY=

# ===================
# COMMUNICATION
# ===================
TELEGRAM_BOT_TOKEN=

# ===================
# CRM
# ===================
GHL_API_KEY=
GHL_LOCATION_ID=

# ===================
# GOOGLE
# ===================
# Path to credentials JSON file
GOOGLE_CREDENTIALS_PATH=./credentials/google-oauth.json

# ===================
# GITHUB BRAIN
# ===================
GITHUB_BRAIN_REPO=username/repo-name
GITHUB_BRAIN_BRANCH=main
GITHUB_ACCESS_TOKEN=

# ===================
# DATABASE
# ===================
DATABASE_URL=sqlite:///data/app.db

# ===================
# ZAPIER WEBHOOKS
# ===================
ZAPIER_NEW_LEAD_WEBHOOK=
ZAPIER_CONVERSATION_LOG_WEBHOOK=
```

## API Endpoint Reference

### Internal APIs

| Endpoint | Method | Purpose | Auth |
|----------|--------|---------|------|
| `/health` | GET | Health check | None |
| `/api/chat` | POST | Chat endpoint | API Key |
| `/api/webhook/ghl` | POST | GHL webhooks | Signature |
| `/api/webhook/zapier` | POST | Zapier webhooks | Secret |

### External APIs Used

| API | Base URL | Rate Limit |
|-----|----------|------------|
| OpenAI | `https://api.openai.com/v1` | Varies by tier |
| Anthropic | `https://api.anthropic.com/v1` | Varies by tier |
| Telegram | `https://api.telegram.org/bot{token}` | 30 msg/sec |
| GoHighLevel | `https://rest.gohighlevel.com/v1` | 100 req/min |
| GitHub Raw | `https://raw.githubusercontent.com` | 5000 req/hr |

## Webhook Configurations

### Incoming Webhooks (Our System Receives)

| Source | Endpoint | Events |
|--------|----------|--------|
| GoHighLevel | `/webhook/ghl` | contact.created, opportunity.updated |
| Zapier | `/webhook/zapier` | Various, per Zap |
| Stripe | `/webhook/stripe` | payment.succeeded, subscription.updated |

### Outgoing Webhooks (We Send)

| Destination | Events We Send |
|-------------|----------------|
| Zapier | new_lead, conversation_completed |
| Slack | alerts, daily_summary |
| GHL | contact_update, task_create |

## Credential Rotation Schedule

| Credential | Rotation Frequency | Last Rotated | Next Due |
|------------|-------------------|--------------|----------|
| OpenAI API Key | 90 days | [Date] | [Date] |
| GitHub PAT | 90 days | [Date] | [Date] |
| GHL API Key | 180 days | [Date] | [Date] |
| Telegram Token | As needed | [Date] | N/A |

## Access Control

| Role | Can Access |
|------|------------|
| Admin | All credentials |
| Developer | Dev environment only |
| Bot | Runtime credentials only |
| CI/CD | Deployment credentials only |

## Emergency Procedures

### If Credentials Are Compromised

1. **Immediately revoke** the compromised credential
2. **Generate new** credential
3. **Update** all systems using the credential
4. **Review logs** for unauthorized access
5. **Document** the incident

### Credential Recovery

- OpenAI: Regenerate in dashboard
- GitHub: Revoke and create new PAT
- Telegram: Contact @BotFather for `/revoke`
- GHL: Regenerate in Settings

---

*Review and update this document whenever credentials change.*
