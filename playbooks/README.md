# Playbooks

This directory contains customer journey automation playbooks organized by funnel stage.

## Funnel Stages

### 1. Attract (`/attract/`)
Lead generation, outreach, and first contact procedures. This stage is about getting attention and generating interest.

**Key activities:**
- Content marketing
- Social media outreach
- Advertising campaigns
- SEO and organic traffic
- Cold outreach

### 2. Convert (`/convert/`)
Sales qualification, objection handling, and closing strategies. This stage turns interested prospects into paying customers.

**Key activities:**
- Lead qualification
- Discovery calls
- Proposals and quotes
- Objection handling
- Closing techniques

### 3. Nurture (`/nurture/`)
Follow-up sequences, relationship building, and retention. This stage maintains relationships with leads not yet ready to buy and keeps existing customers engaged.

**Key activities:**
- Email sequences
- Check-in calls
- Value-add content
- Referral programs
- Customer success

### 4. Deliver (`/deliver/`)
Onboarding, service delivery, and customer success protocols. This stage ensures customers get value and become advocates.

**Key activities:**
- Onboarding processes
- Project delivery
- Support procedures
- Success milestones
- Offboarding (if applicable)

## How Bots Use Playbooks

AI bots fetch specific playbooks based on the context of a conversation:

```python
# Bot recognizes a sales objection
objection_playbook = brain.fetch_playbook("convert", "objections")

# Bot needs to onboard a new customer
onboarding_playbook = brain.fetch_playbook("deliver", "onboarding")
```

## Creating New Playbooks

1. Identify the funnel stage
2. Create a markdown file in the appropriate folder
3. Use consistent formatting (see existing playbooks)
4. Include clear instructions the bot can follow
5. Test with sample conversations

## Playbook Template

```markdown
# [Playbook Name]

## Purpose
[What this playbook achieves]

## When to Use
[Triggers or situations that call for this playbook]

## Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Sample Scripts
[Example language to use]

## Escalation
[When to hand off to a human]
```

---

*See individual folder READMEs for stage-specific guidance.*
