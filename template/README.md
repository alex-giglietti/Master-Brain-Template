# [CLIENT NAME] Brain

> **Customized AI bot brain for [CLIENT NAME]**

## Overview

This directory contains the customized knowledge base for [CLIENT NAME]'s AI bot. All files in this directory should be updated with your business-specific information.

## Directory Structure

```
template/
├── config/           # Core business configuration
│   ├── vision.md     # Company overview, mission, values
│   ├── offers.md     # Product/service catalog
│   └── tech-stack.md # Technology infrastructure
│
├── brand/            # Brand identity
│   ├── brand.md      # Brand guidelines, voice, tone
│   ├── social-bios.md # Social media bios
│   └── assets/       # Logos, banners, business cards
│
├── playbooks/        # Customer journey automation
│   ├── attract/      # Lead generation
│   ├── convert/      # Sales & closing
│   ├── nurture/      # Follow-up & retention
│   └── deliver/      # Onboarding & success
│
├── execution/        # Operations & management
│   ├── roles.md      # Team roles & responsibilities
│   ├── project-management.md
│   ├── financials.md
│   └── reporting.md
│
├── setup/            # Integration guides
│   ├── openclaw.md
│   ├── telegram.md
│   ├── api-connections.md
│   └── ...
│
└── memory/           # Dynamic conversation history (gitignored)
```

## How to Update

1. Edit markdown files directly in GitHub or locally
2. Replace all `[TEMPLATE]` placeholders with your actual content
3. Commit changes with descriptive messages
4. Bot automatically pulls latest version within 5 minutes

## Maintenance

- Review playbooks monthly
- Update brand guidelines when positioning changes
- Keep API credentials current in `setup/api-connections.md`
- Run validation: `python _master/scripts/validate-brain.py`

## Important

- **DO NOT** edit files in `/_master/` - those are system files
- **DO** edit all files in this `/template/` directory
- **DO** add new playbooks as your process evolves
- **DO** keep brand assets up to date

---

*Maintained by: [Your Name/Team]*
*Last updated: [Date]*
