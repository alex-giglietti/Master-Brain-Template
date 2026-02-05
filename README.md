# Master Brain Template System

> **A fork-able, customizable knowledge base template for AI-powered business automation**

## What Is This?

This is a **master template repository** that serves as the foundation for creating custom AI bot "brains." Each client gets their own fork of this template, which they customize with their business-specific information.

## Repository Structure

### `/_master/` - **DO NOT EDIT** (Maintained by AI implementation team)
Contains core system files that power the brain across all clients:
- **docs/** - System architecture, best practices, API reference
- **scripts/** - Integration scripts, validation tools, deployment automation
- **templates/** - Blank templates for creating new documents

### `/template/` - **CUSTOMIZE THIS** (Client-specific content)
Contains the actual "brain" that clients customize:
- **config/** - Company vision, offers, tech stack
- **brand/** - Brand guidelines, social bios, visual assets
- **playbooks/** - Customer journey automation (attract, convert, nurture, deliver)
- **execution/** - Operations, project management, financials
- **setup/** - Integration guides for tools and platforms
- **memory/** - Dynamic conversation history (not in git)

### `/examples/` - **REFERENCE ONLY** (Sample completed brains)
Real-world examples of fully customized brains for different business types

## Quick Start for Clients

### Step 1: Fork This Repository
```bash
gh repo fork master-brain-template --clone
cd master-brain-template
```

### Step 2: Customize Your Brain
Navigate to `/template/` and update all `[TEMPLATE]` files with your business info:
- `template/config/vision.md` - Your company overview
- `template/brand/brand.md` - Your brand guidelines
- `template/playbooks/` - Your customer journey scripts
- See [TEMPLATE-CUSTOMIZATION-GUIDE.md](TEMPLATE-CUSTOMIZATION-GUIDE.md) for detailed instructions

### Step 3: Deploy to Your Bot
Follow [SETUP-GUIDE.md](SETUP-GUIDE.md) to connect your customized brain to OpenClaw

## For AI Implementation Teams

### Updating the Master Template
When you improve the core system (scripts, docs, templates):
1. Update files in `/_master/` on this repo
2. All client forks can pull these improvements without affecting their customized `/template/` content

### Creating a New Client Brain
```bash
# Use the automated setup script
bash _master/scripts/setup-client-brain.sh "ClientName"
```

This will:
- Create a new fork
- Add client name to all template files
- Initialize their customized structure
- Generate deployment credentials

## Documentation

- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Connect brain to OpenClaw
- **[TEMPLATE-CUSTOMIZATION-GUIDE.md](TEMPLATE-CUSTOMIZATION-GUIDE.md)** - Customize template files
- **[_master/docs/architecture.md](_master/docs/architecture.md)** - How the brain system works
- **[_master/docs/best-practices.md](_master/docs/best-practices.md)** - Maintenance and optimization
- **[_master/docs/api-reference.md](_master/docs/api-reference.md)** - Programmatic access patterns
- **[_master/docs/troubleshooting.md](_master/docs/troubleshooting.md)** - Common issues and solutions

## Philosophy

### Template vs. Instance
- **This repo** = The template (like a blank form)
- **Client fork** = An instance (like a filled-out form)

### Master vs. Client Separation
- **`/_master/`** stays in sync across all forks (pull updates)
- **`/template/`** is unique per client (never pushed back to master)

### Why This Structure?
- **Scalability**: Onboard 10 clients or 1000 with the same system
- **Maintainability**: Fix a bug once, deploy to all clients
- **Customization**: Each client gets a unique brain without code duplication
- **Version Control**: Track template improvements separately from client customizations

## Keeping Your Brain Updated

### As a Client
```bash
# Pull master template improvements (doesn't touch your /template/ content)
git fetch upstream
git merge upstream/main _master/
```

### As an Implementation Team
```bash
# Push improvements to master template
git checkout main
# Edit files in _master/
git add _master/
git commit -m "Improved brain loader caching"
git push origin main
```

All clients can now pull this improvement.

## Examples

Check `/examples/` to see fully-completed brains for:
- **Consulting Firm** - B2B professional services
- **E-commerce Store** - D2C product business

These show what a production-ready brain looks like.

## Support

- **For Clients**: See your implementation partner's contact info in your customized README
- **For Implementation Teams**: Open issues in this repository
- **Documentation**: All guides are in `/_master/docs/`

---

**System Version:** 1.0
**Last Updated:** February 2026
**Maintained By:** AIM
