#!/bin/bash
# Automated client brain setup script

if [ -z "$1" ]; then
    echo "Usage: ./setup-client-brain.sh <ClientName>"
    exit 1
fi

CLIENT_NAME=$1
REPO_NAME=$(echo "$CLIENT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')-brain

echo "Setting up brain for: $CLIENT_NAME"
echo "Repository name: $REPO_NAME"

# Fork the repository
echo "Forking master template..."
gh repo fork --clone --remote

# Rename the repo
cd master-brain-template
gh repo rename $REPO_NAME

# Replace placeholders
echo "Updating placeholders..."
find template/ -type f -name "*.md" -exec sed -i "s/\[CLIENT NAME\]/$CLIENT_NAME/g" {} \;
find template/ -type f -name "*.md" -exec sed -i "s/\[Your Company\]/$CLIENT_NAME/g" {} \;

# Commit changes
git add template/
git commit -m "Initial setup for $CLIENT_NAME"
git push

echo "Client brain setup complete!"
echo "Repository: https://github.com/$(gh api user --jq .login)/$REPO_NAME"
echo ""
echo "Next steps:"
echo "1. Customize template/ files (see TEMPLATE-CUSTOMIZATION-GUIDE.md)"
echo "2. Add brand assets to template/brand/assets/"
echo "3. Run validation: python _master/scripts/validate-brain.py"
echo "4. Connect to OpenClaw (see SETUP-GUIDE.md)"
