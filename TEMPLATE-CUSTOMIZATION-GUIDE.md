# Template Customization Guide

> **Complete guide for transforming the master template into your unique AI bot brain**

## Overview

This guide walks you through customizing every `[TEMPLATE]` file in the `/template/` directory.

## Before You Start

### Prerequisites
- [ ] You've forked this repository to your own GitHub account
- [ ] You have your business documents ready (mission statement, product list, etc.)
- [ ] You have brand assets (logos, colors, fonts)
- [ ] You understand your customer journey stages

### What You'll Customize
All files in `/template/` directory. Files marked with `[TEMPLATE]` contain placeholder content to replace.

---

## Part 1: Core Configuration

### 1.1 Company Vision (`template/config/vision.md`)

**What to include:**
- Company name and tagline
- Mission statement (why you exist)
- Vision statement (where you're going)
- Core values (3-5 principles)
- Target market description
- Unique value proposition

**Example:**
```markdown
# Company Overview

## Who We Are
Acme Consulting helps B2B SaaS companies scale from $1M to $10M ARR through AI-powered sales automation.

## Our Mission
To democratize enterprise-grade sales technology for growing startups.

## Our Vision
A world where every startup has access to Fortune 500 sales capabilities.

## Core Values
1. **Client Success First** - We only win when our clients win
2. **Automate Thoughtfully** - Technology serves humans, not replaces them
3. **Transparent Growth** - Open metrics, honest conversations, real results
```

### 1.2 Offers (`template/config/offers.md`)

**What to include:**
- Complete product/service catalog
- Pricing tiers
- What's included in each offer
- Ideal customer for each offer
- Common objections and responses

### 1.3 Tech Stack (`template/config/tech-stack.md`)

**What to include:**
- All tools/platforms you use
- Integration points
- Data flow architecture
- API credentials storage locations

---

## Part 2: Brand Identity

### 2.1 Brand Guidelines (`template/brand/brand.md`)

**What to include:**
- Brand personality traits
- Voice and tone guidelines
- Do's and don'ts
- Example messages in your voice
- Visual identity (colors, fonts, logos)

**Example:**
```markdown
# Brand Guidelines

## Personality
We are: **Confident**, **Approachable**, **Data-Driven**
We are not: Stuffy, Overly Casual, Vague

## Voice
We speak like a knowledgeable advisor who's been in the trenches. We use "we" and "you" frequently. We back claims with data but explain it simply.

## Tone Examples

**Professional (Proposal Email):**
> "Based on your current sales cycle of 45 days and close rate of 18%, our AI system projects an additional $240K in pipeline value within 90 days."

**Friendly (Nurture Message):**
> "Hey! Just wanted to share a quick win - one of our clients just closed their biggest deal using the exact objection-handling script we built."
```

### 2.2 Social Bios (`template/brand/social-bios.md`)

Write 3-5 versions of your bio for different platforms (LinkedIn, Twitter/X, Instagram, etc.)

### 2.3 Upload Brand Assets

Place your files in the appropriate folders:
```
template/brand/assets/logos/       # Logo files
template/brand/assets/favicon/     # Favicon
template/brand/assets/business-cards/
template/brand/assets/banners/     # Social media banners
```

---

## Part 3: Customer Journey Playbooks

This is the heart of your brain. Customize each stage with your actual process.

### 3.1 Attract Stage (`template/playbooks/attract/`)

Create playbooks for how you generate leads:
- Cold outreach scripts
- Content distribution strategy
- Lead magnets
- Qualification questions

### 3.2 Convert Stage (`template/playbooks/convert/`)

Create playbooks for your sales process:
- Discovery call scripts
- Demo flow
- Objection handling
- Pricing presentation
- Closing techniques

### 3.3 Nurture Stage (`template/playbooks/nurture/`)

Create playbooks for staying engaged:
- Follow-up email sequences
- Value content to share
- Check-in cadence
- Re-engagement for cold leads

### 3.4 Deliver Stage (`template/playbooks/deliver/`)

Create playbooks for customer success:
- Onboarding process (30-60-90 days)
- Training materials
- Success metrics
- Escalation procedures

Use the playbook template at `_master/templates/playbook-template.md` for consistent formatting.

---

## Part 4: Execution & Operations

### 4.1 Roles & Responsibilities (`template/execution/roles.md`)
- Team structure
- Who does what
- Decision-making authority
- Escalation paths

### 4.2 Project Management (`template/execution/project-management.md`)
- How projects move through stages
- Milestones and deliverables
- Review/approval process
- Tools used

### 4.3 Financials (`template/execution/financials.md`)
- Pricing calculations (costs + margin)
- Payment terms
- Refund policy
- Revenue tracking methods

### 4.4 Reporting (`template/execution/reporting.md`)
- Metrics you track
- How often you report
- Dashboard tools
- What success looks like

---

## Part 5: Setup & Integration

For each file in `template/setup/`, replace placeholders with your actual credentials and configurations.

Key files to update:
- `template/setup/openclaw.md` - Bot deployment settings
- `template/setup/api-connections.md` - All API keys and webhooks
- `template/setup/telegram.md` - Telegram bot configuration
- `template/setup/ghl.md` - GoHighLevel CRM setup
- `template/setup/google-workspace.md` - Google Workspace automation
- `template/setup/zapier.md` - Zapier workflow connections

---

## Part 6: Final Steps

### 6.1 Update Template README
Edit `template/README.md` to include your company name and details.

### 6.2 Run Validation
```bash
python _master/scripts/validate-brain.py
```

This checks:
- All required files exist
- No placeholder text remains
- Files are properly formatted
- Assets are in place

### 6.3 Commit Your Customizations
```bash
git add template/
git commit -m "Initial customization for [Your Company Name]"
git push origin main
```

---

## Customization Checklist

### Configuration
- [ ] `template/config/vision.md` - Company overview complete
- [ ] `template/config/offers.md` - All products/services documented
- [ ] `template/config/tech-stack.md` - Technology infrastructure mapped

### Brand
- [ ] `template/brand/brand.md` - Brand guidelines written
- [ ] `template/brand/social-bios.md` - Bios written for all platforms
- [ ] `template/brand/assets/logos/` - All logo files uploaded
- [ ] `template/brand/assets/favicon/` - Favicon uploaded
- [ ] Other assets uploaded as needed

### Playbooks - Attract
- [ ] Created playbooks for lead generation methods
- [ ] Scripts for outreach channels (email, social, etc.)
- [ ] Lead magnet descriptions and access links

### Playbooks - Convert
- [ ] Discovery call script
- [ ] Demo/presentation flow
- [ ] Objection handling responses
- [ ] Pricing presentation approach
- [ ] Closing techniques

### Playbooks - Nurture
- [ ] Follow-up email sequences
- [ ] Value content library
- [ ] Check-in cadence defined
- [ ] Re-engagement strategies

### Playbooks - Deliver
- [ ] Onboarding process documented
- [ ] Training materials created
- [ ] Success metrics defined
- [ ] Escalation procedures written

### Execution
- [ ] `template/execution/roles.md` - Team structure defined
- [ ] `template/execution/project-management.md` - Workflow documented
- [ ] `template/execution/financials.md` - Pricing/costs calculated
- [ ] `template/execution/reporting.md` - KPIs and dashboards defined

### Setup
- [ ] `template/setup/openclaw.md` - Bot setup instructions
- [ ] `template/setup/api-connections.md` - All API keys documented
- [ ] Other integration guides completed

### Final
- [ ] Validation script passed
- [ ] Template README updated
- [ ] All changes committed and pushed
- [ ] Ready to deploy!

---

## Next Steps

After customization:
1. Follow [SETUP-GUIDE.md](SETUP-GUIDE.md) to connect your brain to OpenClaw
2. Test with sample conversations
3. Iterate based on bot performance
4. Keep playbooks updated as your process evolves

---

Your brain is never "done" - it evolves with your business.
