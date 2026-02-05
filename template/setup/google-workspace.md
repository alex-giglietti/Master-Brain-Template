# Google Workspace Setup Guide

> Instructions for integrating Google Workspace with your automation stack

## Overview

Google Workspace integration enables:
- Automated email responses
- Calendar scheduling
- Document management
- Contact synchronization
- Spreadsheet data access

## Prerequisites

- Google Workspace account (or personal Google account)
- Google Cloud Project
- OAuth 2.0 credentials

## Setting Up Google Cloud Project

### Step 1: Create Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click "Select a project" > "New Project"
3. Enter project name: "[Company] Automation"
4. Click "Create"

### Step 2: Enable APIs

Enable these APIs for your project:

1. Go to "APIs & Services" > "Library"
2. Search and enable:
   - Gmail API
   - Google Calendar API
   - Google Drive API
   - Google Sheets API
   - Google Docs API
   - People API (for contacts)

### Step 3: Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Choose user type:
   - **Internal**: For Workspace users only
   - **External**: For any Google user
3. Fill in required information:
   - App name
   - User support email
   - Developer contact email
4. Add scopes (permissions your app needs)
5. Add test users (if external)

### Step 4: Create Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Choose application type:
   - **Desktop app**: For local scripts
   - **Web application**: For server deployments
4. Download the JSON credentials file
5. Store securely (never commit to git)

## API Scopes Reference

| Scope | Purpose |
|-------|---------|
| `gmail.send` | Send emails |
| `gmail.readonly` | Read emails |
| `gmail.modify` | Read and modify emails |
| `calendar.events` | Manage calendar events |
| `drive.file` | Access files created by app |
| `drive.readonly` | Read all Drive files |
| `spreadsheets` | Full Sheets access |

## Gmail Integration

### Sending Emails

```python
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
import base64
from email.mime.text import MIMEText

def send_email(service, to, subject, body):
    message = MIMEText(body)
    message['to'] = to
    message['subject'] = subject

    raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
    service.users().messages().send(
        userId='me',
        body={'raw': raw}
    ).execute()
```

### Reading Emails

```python
def get_recent_emails(service, query='', max_results=10):
    results = service.users().messages().list(
        userId='me',
        q=query,
        maxResults=max_results
    ).execute()

    messages = results.get('messages', [])
    return messages
```

## Calendar Integration

### Create Event

```python
def create_calendar_event(service, summary, start, end, attendees=[]):
    event = {
        'summary': summary,
        'start': {'dateTime': start, 'timeZone': 'UTC'},
        'end': {'dateTime': end, 'timeZone': 'UTC'},
        'attendees': [{'email': a} for a in attendees],
    }

    service.events().insert(
        calendarId='primary',
        body=event,
        sendUpdates='all'
    ).execute()
```

### Check Availability

```python
def get_free_busy(service, calendar_id, time_min, time_max):
    body = {
        'timeMin': time_min,
        'timeMax': time_max,
        'items': [{'id': calendar_id}]
    }

    result = service.freebusy().query(body=body).execute()
    return result['calendars'][calendar_id]['busy']
```

## Drive Integration

### Upload File

```python
from googleapiclient.http import MediaFileUpload

def upload_file(service, file_path, folder_id=None):
    file_metadata = {'name': os.path.basename(file_path)}
    if folder_id:
        file_metadata['parents'] = [folder_id]

    media = MediaFileUpload(file_path)
    file = service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id'
    ).execute()

    return file.get('id')
```

### List Files

```python
def list_files(service, folder_id=None, query=''):
    q = query
    if folder_id:
        q = f"'{folder_id}' in parents" + (' and ' + query if query else '')

    results = service.files().list(
        q=q,
        fields='files(id, name, mimeType)'
    ).execute()

    return results.get('files', [])
```

## Sheets Integration

### Read Data

```python
def read_sheet(service, spreadsheet_id, range_name):
    result = service.spreadsheets().values().get(
        spreadsheetId=spreadsheet_id,
        range=range_name
    ).execute()

    return result.get('values', [])
```

### Write Data

```python
def write_sheet(service, spreadsheet_id, range_name, values):
    body = {'values': values}

    service.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id,
        range=range_name,
        valueInputOption='USER_ENTERED',
        body=body
    ).execute()
```

## Authentication Flow

### Service Account (Server-to-Server)

For automated processes without user interaction:

1. Create service account in Cloud Console
2. Download JSON key file
3. Share resources with service account email

```python
from google.oauth2 import service_account

credentials = service_account.Credentials.from_service_account_file(
    'service-account.json',
    scopes=['https://www.googleapis.com/auth/drive']
)

service = build('drive', 'v3', credentials=credentials)
```

### OAuth 2.0 (User Authorization)

For accessing user-specific data:

```python
from google_auth_oauthlib.flow import InstalledAppFlow

flow = InstalledAppFlow.from_client_secrets_file(
    'credentials.json',
    scopes=['https://www.googleapis.com/auth/gmail.send']
)

credentials = flow.run_local_server(port=0)
```

## Best Practices

1. **Minimize scopes** - Request only what you need
2. **Handle token refresh** - Tokens expire, plan for refresh
3. **Rate limiting** - Respect API quotas
4. **Error handling** - Handle API errors gracefully
5. **Secure storage** - Never expose credentials

## Troubleshooting

### Common Errors

**403 Forbidden**
- Check API is enabled
- Verify scopes are correct
- Ensure OAuth consent is configured

**401 Unauthorized**
- Token may be expired
- Credentials file may be invalid
- Scopes may have changed

**429 Rate Limit**
- Implement exponential backoff
- Request quota increase if needed

---

*Store credentials securely and never commit to version control.*
