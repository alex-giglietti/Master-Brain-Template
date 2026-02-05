"""
Google Drive to Markdown Exporter
Fetches all documents from AIM Master Brain and converts to markdown
"""

from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow
import os
import pickle

SCOPES = ['https://www.googleapis.com/auth/drive.readonly']

# Document ID mapping (from Drive structure)
DOCUMENT_MAPPING = {
    '1H_U_c_m5oPjUKkLPm3r3Zs7VFMjfoR3H-aX8R1SWwoI': 'config/vision.md',
    '1oBRZR2pQ2hJ58z-OgW-SOZfBqE2YZp2rMoBIDSwpb2E': 'config/offers.md',
    '1n057dUpH61oJZCchji_vyedESVxt1InU8VQfWP2uvxg': 'brand/brand.md',
    '197IStPSln69vkXESX8N3Q70_SeTA540t-ZHaa5CB2-o': 'brand/social-bios.md',
    '1f3OeXyQ2mcPI3T_3DGEhoFsXtBJcIx3x1emkVK14LtE': 'config/tech-stack.md',
    '1FcoA4EirVNjy8ad7KKSYSehyg2p5-Fonx-iRW0h82E0': 'setup/api-connections.md',
    '1CCu7kHo561Ju9CEHfr_XP_a8LPfTdRtwIhSJCSbE_Wo': 'setup/openclaw.md',
    '1zjQAF7Ay2xGhjF6UFdvS_Z4hnAZG1ssTVrKzD8VxsDo': 'setup/telegram.md',
    '1aXrfSEZVM5pc6A-6VEx2lQ-zXlIEX0OCGKMM1X35S64': 'setup/google-workspace.md',
    '1adV2i6W35NKAeANHYyf68bJiZBssfXf0RHnr1Je05LQ': 'setup/ghl.md',
    '1BvT7dd0ixxejWq_Wt6BewijmDWBJabY5cRE0XrZTOsY': 'setup/zapier.md',
    '1DuGzbhcJyxE_596YJ-DXv6GFIfZI7axYsBwp2wpyF7E': 'execution/roles.md',
    '1OQFDd6GRjajgMKdwzI3BzZDKj6cI1PhvXqyytmg7B98': 'execution/project-management.md',
    '1ToQFQkJw4JhxIQkvDRp6CBW_kBOeC-EfmBLZfhTqdEQ': 'execution/financials.md',
    '1f4r4rCiW6mfIzgINVDNWIkTOowstJqqit2rpozQF3wU': 'execution/reporting.md',
}

# Playbook folder IDs
PLAYBOOK_FOLDERS = {
    '1gURy-dDX9YRmmK0w86-XbKD_JfuMmw7q': 'playbooks/attract',
    '1AbzNE1-uFVav55PMaEYw6Zvo3C01YKer': 'playbooks/convert',
    '1xcB-iqE5ZP6LRda67E0QEEDU-s_S3uL2': 'playbooks/nurture',
    '1r-WDhBCkN8MXQmsa0o-RZvlUSlSHerWH': 'playbooks/deliver',
}


def authenticate():
    """Authenticate with Google Drive API"""
    creds = None
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)

        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)

    return build('drive', 'v3', credentials=creds)


def export_document_to_markdown(service, doc_id, output_path):
    """Export a Google Doc as markdown"""
    try:
        # Export as plain text (closest to markdown)
        request = service.files().export_media(
            fileId=doc_id,
            mimeType='text/plain'
        )
        content = request.execute().decode('utf-8')

        # Ensure directory exists
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        # Write to file
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"Exported: {output_path}")
        return True
    except Exception as e:
        print(f"Failed to export {doc_id} to {output_path}: {str(e)}")
        return False


def export_folder_contents(service, folder_id, output_dir):
    """Recursively export all documents in a folder"""
    try:
        query = f"'{folder_id}' in parents and trashed=false"
        results = service.files().list(
            q=query,
            fields="files(id, name, mimeType)"
        ).execute()

        items = results.get('files', [])

        for item in items:
            if item['mimeType'] == 'application/vnd.google-apps.document':
                # It's a document
                file_name = item['name'].replace(' ', '-').lower()
                if not file_name.endswith('.md'):
                    file_name += '.md'
                output_path = os.path.join(output_dir, file_name)
                export_document_to_markdown(service, item['id'], output_path)
            elif item['mimeType'] == 'application/vnd.google-apps.folder':
                # It's a folder - recurse
                subfolder_path = os.path.join(output_dir, item['name'].lower())
                os.makedirs(subfolder_path, exist_ok=True)
                export_folder_contents(service, item['id'], subfolder_path)

        return True
    except Exception as e:
        print(f"Failed to export folder {folder_id}: {str(e)}")
        return False


def main():
    """Main export function"""
    print("Authenticating with Google Drive...")
    service = authenticate()

    print("\nExporting documents from mapped IDs...")
    for doc_id, output_path in DOCUMENT_MAPPING.items():
        export_document_to_markdown(service, doc_id, output_path)

    print("\nExporting Playbooks folder structure...")
    for folder_id, output_dir in PLAYBOOK_FOLDERS.items():
        os.makedirs(output_dir, exist_ok=True)
        export_folder_contents(service, folder_id, output_dir)

    print("\nExport complete!")


if __name__ == '__main__':
    main()
