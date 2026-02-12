# OpenClaw Setup Guide

> Complete instructions for deploying and configuring your OpenClaw bot instance

## Prerequisites

- Linux server (Ubuntu 20.04+ recommended) or Docker environment
- Python 3.9+
- At least 2GB RAM
- Domain name (optional, for public access)
- API keys for your chosen LLM provider

## Installation Options

### Option 1: Docker (Recommended)

```bash
# Pull the OpenClaw image
docker pull openclaw/openclaw:latest

# Create configuration directory
mkdir -p /opt/openclaw/config

# Create environment file
cat > /opt/openclaw/.env << 'EOF'
# LLM Configuration
OPENAI_API_KEY=sk-your-key-here
# Or for Claude:
ANTHROPIC_API_KEY=sk-ant-your-key-here

# Bot Configuration
BOT_NAME=YourBotName
TELEGRAM_BOT_TOKEN=your-telegram-token

# GitHub Brain
GITHUB_BRAIN_REPO=your-username/your-brain-repo
GITHUB_BRAIN_BRANCH=main
GITHUB_ACCESS_TOKEN=ghp_your-token

# Database
DATABASE_URL=sqlite:///data/openclaw.db
EOF

# Run the container
docker run -d \
  --name openclaw \
  --restart unless-stopped \
  -v /opt/openclaw/data:/app/data \
  -v /opt/openclaw/config:/app/config \
  --env-file /opt/openclaw/.env \
  -p 8080:8080 \
  openclaw/openclaw:latest
```

### Option 2: Direct Installation

```bash
# Clone the repository
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy and configure environment
cp .env.example .env
nano .env  # Edit with your values

# Run the application
python main.py
```

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENAI_API_KEY` | Yes* | OpenAI API key |
| `ANTHROPIC_API_KEY` | Yes* | Anthropic API key |
| `TELEGRAM_BOT_TOKEN` | Yes | From @BotFather |
| `GITHUB_BRAIN_REPO` | Yes | Your brain repository |
| `GITHUB_ACCESS_TOKEN` | Yes | PAT with repo scope |
| `DATABASE_URL` | No | Database connection string |
| `LOG_LEVEL` | No | DEBUG, INFO, WARNING, ERROR |

*At least one LLM provider required

### Bot Personality Configuration

Create `/opt/openclaw/config/personality.yaml`:

```yaml
name: "YourBotName"
description: "AI assistant for [Your Company]"

system_prompt: |
  You are an AI assistant for [Company Name].

  Your primary functions:
  - Answer questions about our products and services
  - Qualify potential leads
  - Provide support information
  - Schedule meetings with our team

  Always be helpful, professional, and on-brand.
  Refer to the brand guidelines for tone and voice.

behaviors:
  - greet_new_users: true
  - ask_clarifying_questions: true
  - escalate_complex_issues: true
  - log_all_conversations: true

escalation_triggers:
  - "speak to human"
  - "real person"
  - "manager"
  - "complaint"
  - "refund"
```

## Telegram Integration

### Create Bot with BotFather

1. Open Telegram and search for `@BotFather`
2. Send `/newbot`
3. Choose a name for your bot
4. Choose a username (must end in 'bot')
5. Copy the API token provided

### Configure Bot Settings

With BotFather:
```
/setdescription - Set what users see when they open chat
/setabouttext - Set the "About" section
/setuserpic - Upload your bot's profile picture
/setcommands - Set available commands
```

Recommended commands:
```
start - Start conversation
help - Get help
contact - Speak to a human
services - Learn about our services
```

## Brain Integration

### Connect to GitHub Brain

1. Ensure brain_loader.py is in your OpenClaw directory
2. Configure environment variables:
   ```bash
   GITHUB_BRAIN_REPO=your-username/aim-master-brain
   GITHUB_BRAIN_BRANCH=main
   GITHUB_ACCESS_TOKEN=ghp_your-token
   ```

3. Import in your agent configuration:
   ```python
   from brain_loader import brain

   # Use in system prompt
   company_info = brain.get_company_overview()
   brand_voice = brain.get_brand_voice()
   ```

## Monitoring

### View Logs

```bash
# Docker
docker logs openclaw -f

# Direct installation
tail -f logs/openclaw.log
```

### Health Check

```bash
curl http://localhost:8080/health
```

Expected response:
```json
{
  "status": "healthy",
  "brain_connected": true,
  "telegram_connected": true,
  "last_sync": "2024-01-15T10:30:00Z"
}
```

## Troubleshooting

### Bot Not Responding

1. Check Telegram token is correct
2. Verify bot is running: `docker ps` or `ps aux | grep python`
3. Check logs for errors

### Brain Not Loading

1. Verify GitHub token has `repo` scope
2. Test repository access manually
3. Check network connectivity

### High Latency

1. Check LLM API status
2. Review rate limits
3. Consider caching responses

## Security Best Practices

1. **Never commit secrets** - Use environment variables
2. **Rotate tokens regularly** - Especially after team changes
3. **Limit bot permissions** - Only what's needed
4. **Monitor usage** - Watch for unusual patterns
5. **Regular updates** - Keep dependencies current

---

*See SETUP-GUIDE.md for complete brain integration instructions.*
