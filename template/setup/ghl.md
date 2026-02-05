# GoHighLevel (GHL) Setup Guide

> Instructions for integrating GoHighLevel CRM with your automation stack

## Overview

GoHighLevel is an all-in-one marketing and CRM platform. Integration enables:
- Lead capture and management
- Automated follow-up sequences
- Appointment scheduling
- Pipeline management
- SMS and email campaigns

## Prerequisites

- GoHighLevel account (Agency or Sub-account)
- API access enabled
- API key or OAuth credentials

## Getting API Credentials

### API Key Method

1. Log into GoHighLevel
2. Go to Settings > Business Profile
3. Navigate to API Keys section
4. Click "Create API Key"
5. Name it (e.g., "OpenClaw Integration")
6. Copy and store securely

### OAuth Method (Recommended for Marketplace Apps)

1. Register as a developer at developers.gohighlevel.com
2. Create an application
3. Configure OAuth settings
4. Implement OAuth flow

## API Basics

### Base URL
```
https://rest.gohighlevel.com/v1/
```

### Authentication Header
```
Authorization: Bearer YOUR_API_KEY
```

### Example Request
```python
import requests

API_KEY = "your-api-key"
BASE_URL = "https://rest.gohighlevel.com/v1"

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

# Get contacts
response = requests.get(f"{BASE_URL}/contacts/", headers=headers)
contacts = response.json()
```

## Contact Management

### Create Contact
```python
def create_contact(data):
    payload = {
        "firstName": data.get("first_name"),
        "lastName": data.get("last_name"),
        "email": data.get("email"),
        "phone": data.get("phone"),
        "tags": data.get("tags", []),
        "source": "Bot Lead",
        "customField": {
            "custom_field_id": data.get("custom_value")
        }
    }

    response = requests.post(
        f"{BASE_URL}/contacts/",
        headers=headers,
        json=payload
    )
    return response.json()
```

### Update Contact
```python
def update_contact(contact_id, data):
    response = requests.put(
        f"{BASE_URL}/contacts/{contact_id}",
        headers=headers,
        json=data
    )
    return response.json()
```

### Search Contacts
```python
def search_contacts(query):
    response = requests.get(
        f"{BASE_URL}/contacts/search",
        headers=headers,
        params={"query": query}
    )
    return response.json()
```

## Pipeline & Opportunities

### Create Opportunity
```python
def create_opportunity(contact_id, pipeline_id, stage_id, data):
    payload = {
        "pipelineId": pipeline_id,
        "pipelineStageId": stage_id,
        "contactId": contact_id,
        "name": data.get("name"),
        "monetaryValue": data.get("value", 0),
        "status": "open"
    }

    response = requests.post(
        f"{BASE_URL}/opportunities/",
        headers=headers,
        json=payload
    )
    return response.json()
```

### Move Opportunity Stage
```python
def update_opportunity_stage(opp_id, new_stage_id):
    payload = {"pipelineStageId": new_stage_id}

    response = requests.put(
        f"{BASE_URL}/opportunities/{opp_id}",
        headers=headers,
        json=payload
    )
    return response.json()
```

## Appointments

### Get Available Slots
```python
def get_available_slots(calendar_id, date):
    response = requests.get(
        f"{BASE_URL}/calendars/{calendar_id}/free-slots",
        headers=headers,
        params={"startDate": date}
    )
    return response.json()
```

### Book Appointment
```python
def book_appointment(calendar_id, contact_id, slot_time):
    payload = {
        "calendarId": calendar_id,
        "contactId": contact_id,
        "startTime": slot_time,
        "title": "Discovery Call",
        "appointmentStatus": "confirmed"
    }

    response = requests.post(
        f"{BASE_URL}/appointments/",
        headers=headers,
        json=payload
    )
    return response.json()
```

## Campaigns & Workflows

### Add to Campaign
```python
def add_to_campaign(contact_id, campaign_id):
    response = requests.post(
        f"{BASE_URL}/contacts/{contact_id}/campaigns/{campaign_id}",
        headers=headers
    )
    return response.json()
```

### Trigger Workflow
```python
def trigger_workflow(contact_id, workflow_id):
    response = requests.post(
        f"{BASE_URL}/contacts/{contact_id}/workflows/{workflow_id}",
        headers=headers
    )
    return response.json()
```

## Tags Management

### Add Tags
```python
def add_tags(contact_id, tags):
    payload = {"tags": tags}

    response = requests.post(
        f"{BASE_URL}/contacts/{contact_id}/tags",
        headers=headers,
        json=payload
    )
    return response.json()
```

### Remove Tags
```python
def remove_tags(contact_id, tags):
    response = requests.delete(
        f"{BASE_URL}/contacts/{contact_id}/tags",
        headers=headers,
        json={"tags": tags}
    )
    return response.json()
```

## Webhooks

### Setting Up Webhooks

1. Go to Settings > Webhooks
2. Add new webhook URL
3. Select events to trigger

### Common Webhook Events
- `contact.created`
- `contact.updated`
- `opportunity.created`
- `opportunity.stage_changed`
- `appointment.booked`
- `appointment.cancelled`

### Handling Webhooks
```python
from flask import Flask, request

app = Flask(__name__)

@app.route('/webhook/ghl', methods=['POST'])
def handle_ghl_webhook():
    data = request.json
    event_type = data.get('type')

    if event_type == 'contact.created':
        handle_new_contact(data['contact'])
    elif event_type == 'opportunity.stage_changed':
        handle_stage_change(data['opportunity'])

    return '', 200
```

## Rate Limits

GHL enforces rate limits:
- **100 requests per minute** for most endpoints
- Implement exponential backoff for 429 errors

```python
import time

def api_request_with_retry(method, url, **kwargs):
    for attempt in range(5):
        response = requests.request(method, url, **kwargs)
        if response.status_code == 429:
            wait_time = 2 ** attempt
            time.sleep(wait_time)
        else:
            return response
    raise Exception("Rate limit exceeded after retries")
```

## Best Practices

1. **Use webhooks** instead of polling for real-time updates
2. **Batch operations** when possible to reduce API calls
3. **Cache frequently accessed data** like pipeline stages
4. **Handle errors gracefully** with proper error messages
5. **Log all API interactions** for debugging

## Troubleshooting

### Common Issues

**401 Unauthorized**
- Check API key is correct
- Verify API key has necessary permissions
- Ensure key hasn't been revoked

**404 Not Found**
- Verify resource IDs are correct
- Check endpoint URL spelling
- Ensure resource exists in the account

**429 Too Many Requests**
- Implement rate limiting
- Add delays between requests
- Use bulk endpoints when available

---

*Store API credentials securely and never expose in client-side code.*
