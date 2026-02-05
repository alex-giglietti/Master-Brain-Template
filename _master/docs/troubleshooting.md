# Troubleshooting Guide

## Common Issues and Solutions

### Bot Gives Generic Responses Instead of Using Brain

**Symptoms:** Bot responds with general knowledge instead of company-specific information.

**Solutions:**
1. Verify `brain_loader` is imported in your agent configuration
2. Confirm system prompt includes brain content variables
3. Check logs for fetch errors: `docker logs openclaw-container | grep brain`
4. Ensure GitHub token is set in `.env`

### "Failed to fetch" Errors in Logs

**Symptoms:** Log messages showing `Failed to fetch config/vision.md` or similar.

**Solutions:**
1. Verify GitHub token is correct in `.env` file
2. Check repository is public OR token has `repo` scope
3. Test manually:
   ```bash
   curl -H "Authorization: token YOUR_TOKEN" \
     https://raw.githubusercontent.com/YOUR_USERNAME/your-brain/main/template/config/vision.md
   ```
4. Verify repository name and branch are correct
5. Check network connectivity from server

### Bot Uses Outdated Information

**Symptoms:** Bot references old content even after updating files.

**Solutions:**
1. Clear cache: `rm -rf /tmp/openclaw_brain/*`
2. Restart bot: `docker-compose restart`
3. Check `BRAIN_SYNC_INTERVAL` value (lower = more frequent updates)
4. Force sync: `python3 -c "from brain_loader import brain; brain.sync_all()"`

### Rate Limiting from GitHub

**Symptoms:** HTTP 403 errors or throttling messages.

**Solutions:**
1. Verify you're using an authenticated token (unauthenticated = 60 req/hour)
2. Increase `BRAIN_SYNC_INTERVAL` to reduce API calls
3. Check current rate limit:
   ```bash
   curl -H "Authorization: token YOUR_TOKEN" \
     https://api.github.com/rate_limit
   ```
4. Authenticated limit is 5,000 requests/hour - sufficient for most setups

### Validation Script Fails

**Symptoms:** `validate-brain.py` reports missing files or folders.

**Solutions:**
1. Run from repository root directory
2. Check you haven't accidentally deleted required files
3. Ensure all `[TEMPLATE]` files have been created (not just placeholders)
4. Verify directory structure matches expected layout

### Google Drive Sync Fails

**Symptoms:** `sync-from-drive.py` errors during export.

**Solutions:**
1. Re-authenticate: Delete `token.pickle` and run again
2. Verify `credentials.json` exists and is valid
3. Check document IDs in `DOCUMENT_MAPPING` are correct
4. Ensure Google Drive API is enabled in your Google Cloud project

### Cache Directory Permission Issues

**Symptoms:** `Permission denied` errors when writing to cache.

**Solutions:**
1. Check cache directory permissions: `ls -la /tmp/openclaw_brain/`
2. Ensure the bot process has write access
3. Change cache directory in `.env`: `BRAIN_CACHE_DIR=/path/with/permissions`

### Fork Merge Conflicts

**Symptoms:** Conflicts when pulling updates from master template.

**Solutions:**
1. Only merge `_master/` directory from upstream:
   ```bash
   git fetch upstream
   git checkout upstream/main -- _master/
   git add _master/
   git commit -m "Updated master files from upstream"
   ```
2. Never modify files in `_master/` on client forks
3. If conflicts occur in `template/`, resolve in favor of client's version

## Getting Help

- **Technical Issues:** Open an issue in the repository
- **Strategic Questions:** Contact your AI implementation partner
- **System Documentation:** See `_master/docs/architecture.md`
