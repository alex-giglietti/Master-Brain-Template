# Zapier Setup Guide

> Instructions for connecting your systems with Zapier automations

## Overview

Zapier connects your apps and automates workflows without coding. Use it to:
- Connect systems that don't have direct integrations
- Create multi-step automations
- Transform and route data
- Trigger actions based on events

## Prerequisites

- Zapier account (Free tier or paid plan)
- Access to apps you want to connect
- Understanding of your automation needs

## Key Concepts

### Zap
A Zap is an automated workflow that connects apps.

### Trigger
The event that starts a Zap (e.g., "New Lead in CRM")

### Action
What happens after the trigger (e.g., "Send Email", "Create Contact")

### Filter
Conditions that must be met for actions to run

### Paths
Branches in your workflow for different scenarios

## Common Automation Patterns

### 1. Lead Capture to CRM

**Trigger:** New form submission (Typeform, Google Forms, etc.)
**Actions:**
1. Create contact in CRM (GHL, HubSpot, etc.)
2. Add to email sequence
3. Notify sales team (Slack, Email)

### 2. Bot Conversation Logging

**Trigger:** Webhook from bot (new conversation)
**Actions:**
1. Log to Google Sheets
2. Update CRM contact notes
3. Create task if action needed

### 3. Appointment Reminders

**Trigger:** Calendar event starting soon
**Actions:**
1. Send SMS reminder
2. Send email with meeting link
3. Update CRM with reminder sent

### 4. Content Publishing

**Trigger:** New blog post published
**Actions:**
1. Share to LinkedIn
2. Share to Twitter
3. Add to email newsletter queue

## Setting Up Webhooks

### Trigger: Webhooks by Zapier

Use when your app can send HTTP requests:

1. Add "Webhooks by Zapier" as trigger
2. Choose "Catch Hook"
3. Copy the webhook URL
4. Configure your app to send data to this URL
5. Test by sending sample data

### Action: Webhooks by Zapier

Use to send data to APIs:

1. Add "Webhooks by Zapier" as action
2. Choose "POST" (or GET, PUT, etc.)
3. Enter the API URL
4. Configure headers (e.g., Authorization)
5. Map data fields to payload

## Data Transformation

### Formatter by Zapier

Transform data between steps:

**Text:**
- Split text into parts
- Find and replace
- Convert case
- Extract patterns

**Numbers:**
- Math operations
- Format currency
- Round numbers

**Dates:**
- Format dates
- Add/subtract time
- Convert timezones

**Example:** Convert "John Smith" to "john.smith@company.com"
```
1. Formatter > Text > Lowercase > "john smith"
2. Formatter > Text > Replace > " " with "." > "john.smith"
3. Formatter > Text > Append > "@company.com" > "john.smith@company.com"
```

## Filters & Paths

### Filter Example

Only continue if lead is qualified:
```
Only continue if...
Lead Score is greater than 50
AND
Company Size is not empty
```

### Paths Example

Route based on lead source:
```
Path A: Source equals "Website"
  → Add to Campaign A

Path B: Source equals "Referral"
  → Add to Campaign B
  → Notify referrer

Path C: All other cases
  → Add to general sequence
```

## Integration with Bot

### Bot → Zapier (Outgoing)

Send conversation data to Zapier:

```python
import requests

ZAPIER_WEBHOOK_URL = "https://hooks.zapier.com/hooks/catch/xxxxx/xxxxx/"

def send_to_zapier(data):
    response = requests.post(
        ZAPIER_WEBHOOK_URL,
        json=data,
        timeout=10
    )
    return response.status_code == 200

# Example: Log new lead
send_to_zapier({
    "event": "new_lead",
    "name": lead.name,
    "email": lead.email,
    "source": "telegram_bot",
    "conversation_summary": summary
})
```

### Zapier → Bot (Incoming)

Trigger bot actions via API:

1. Create API endpoint in bot
2. Use Zapier webhook action to call it
3. Handle the incoming request

## Best Practices

### Organization
- Name Zaps descriptively (e.g., "Website Lead → GHL + Slack Notification")
- Use folders to group related Zaps
- Add descriptions explaining purpose

### Performance
- Minimize steps to reduce task usage
- Use filters early to avoid unnecessary actions
- Batch operations when possible

### Error Handling
- Set up error notifications
- Use conditional paths for edge cases
- Test thoroughly before going live

### Monitoring
- Review Zap history regularly
- Set up alerts for failed Zaps
- Track task usage vs. plan limits

## Troubleshooting

### Zap Not Triggering
1. Check trigger app is connected
2. Verify trigger conditions
3. Test trigger manually
4. Check Zapier status page

### Data Not Mapping Correctly
1. Check field names match
2. Verify data types
3. Use Formatter for transformations
4. Test with sample data

### Action Failing
1. Check destination app connection
2. Verify required fields
3. Check API limits
4. Review error message details

## Advanced Features

### Multi-Step Zaps
Chain multiple actions for complex workflows.

### Scheduled Zaps
Run Zaps on a schedule (hourly, daily, weekly).

### Code Steps
Use Python or JavaScript for custom logic:
```javascript
// Zapier Code step
const data = inputData.name.split(' ');
output = [{
  firstName: data[0],
  lastName: data[1] || ''
}];
```

### Digest by Zapier
Collect items over time and send as batch.

---

*Store webhook URLs securely and rotate if compromised.*
