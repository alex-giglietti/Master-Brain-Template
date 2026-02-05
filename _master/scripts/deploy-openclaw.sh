#!/bin/bash
# Deploy OpenClaw with Brain integration

set -e

echo "OpenClaw Brain Deployment Script"
echo "================================="

# Check prerequisites
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: docker-compose is not installed. Please install docker-compose first."
    exit 1
fi

# Check for .env file
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found."
    echo "Copy .env.example to .env and fill in your values:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Validate required env vars
source .env

if [ -z "$GITHUB_BRAIN_REPO" ] || [ "$GITHUB_BRAIN_REPO" = "your-username/your-brain-repo" ]; then
    echo "ERROR: GITHUB_BRAIN_REPO is not configured in .env"
    exit 1
fi

if [ -z "$GITHUB_ACCESS_TOKEN" ] || [ "$GITHUB_ACCESS_TOKEN" = "ghp_your_token_here" ]; then
    echo "ERROR: GITHUB_ACCESS_TOKEN is not configured in .env"
    exit 1
fi

echo "Configuration:"
echo "  Brain Repo: $GITHUB_BRAIN_REPO"
echo "  Branch: ${GITHUB_BRAIN_BRANCH:-main}"
echo "  Sync Interval: ${BRAIN_SYNC_INTERVAL:-300}s"

# Test brain connectivity
echo ""
echo "Testing brain connectivity..."
TEST_URL="https://raw.githubusercontent.com/$GITHUB_BRAIN_REPO/${GITHUB_BRAIN_BRANCH:-main}/template/config/vision.md"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_ACCESS_TOKEN" "$TEST_URL")

if [ "$HTTP_CODE" = "200" ]; then
    echo "  Brain connection successful!"
else
    echo "  WARNING: Brain connection returned HTTP $HTTP_CODE"
    echo "  Check your GITHUB_BRAIN_REPO and GITHUB_ACCESS_TOKEN settings"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Copy brain loader
echo ""
echo "Installing brain loader..."
cp _master/scripts/brain_loader.py ./brain_loader.py
echo "  Copied brain_loader.py"

# Deploy with docker-compose
echo ""
echo "Starting OpenClaw..."
docker-compose up -d

echo ""
echo "Checking container status..."
sleep 5
docker-compose ps

echo ""
echo "Deployment complete!"
echo ""
echo "Verify with:"
echo "  docker logs openclaw-container --tail 20"
echo ""
echo "Test brain loading:"
echo "  python3 -c \"from brain_loader import brain; print(brain.get_company_overview()[:100])\""
