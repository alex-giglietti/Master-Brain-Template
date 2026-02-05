# Brain API Reference

## GitHubBrain Class

### Initialization
```python
from _master.scripts.brain_loader import GitHubBrain

brain = GitHubBrain(
    repo="username/repo-name",      # Required: GitHub repo in format owner/repo
    branch="main",                  # Optional: branch to read from (default: main)
    token="ghp_xxx",                # Optional: GitHub PAT for private repos
    cache_dir="/tmp/brain_cache"    # Optional: where to cache files
)
```

### Methods

#### `fetch_file(file_path, use_cache=True)`
Fetch any file from the brain repository.

**Parameters:**
- `file_path` (str): Path to file relative to repo root (e.g., `"template/config/vision.md"`)
- `use_cache` (bool): Whether to use cached version if available

**Returns:** String containing file contents

**Example:**
```python
vision = brain.fetch_file("template/config/vision.md")
```

#### `fetch_playbook(stage, playbook_name)`
Convenience method to fetch playbooks by stage and name.

**Parameters:**
- `stage` (str): One of `attract`, `convert`, `nurture`, `deliver`
- `playbook_name` (str): Filename without `.md` extension

**Returns:** String containing playbook contents

**Example:**
```python
script = brain.fetch_playbook("convert", "discovery-call")
```

#### `get_brand_voice()`
Fetch brand guidelines.

**Returns:** String containing brand.md contents

**Example:**
```python
brand_guidelines = brain.get_brand_voice()
```

#### `get_company_overview()`
Fetch company vision and mission.

**Returns:** String containing vision.md contents

**Example:**
```python
company_info = brain.get_company_overview()
```

#### `get_offers()`
Fetch product/service offerings.

**Returns:** String containing offers.md contents

**Example:**
```python
products = brain.get_offers()
```

#### `sync_all()`
Pre-load all critical files into cache.

**Returns:** None (loads files in background)

**Example:**
```python
brain.sync_all()  # Run on bot startup
```

## File Paths

All paths are relative to repository root:

```
template/config/vision.md
template/config/offers.md
template/config/tech-stack.md
template/brand/brand.md
template/brand/social-bios.md
template/playbooks/{stage}/{playbook-name}.md
template/execution/roles.md
template/execution/project-management.md
template/execution/financials.md
template/execution/reporting.md
template/setup/{service}.md
```

## Error Handling

```python
try:
    content = brain.fetch_file("template/config/vision.md")
except requests.exceptions.RequestException as e:
    # Failed to fetch from GitHub
    # Falls back to cache if available
    # Raises exception if no cache exists
    logger.error(f"Failed to load vision: {e}")
```

## Rate Limits

- **Authenticated:** 5,000 requests/hour
- **Unauthenticated:** 60 requests/hour
- **Cache duration:** 5 minutes (reduces API calls)

## Best Practices

1. **Always use tokens** for private repos and higher rate limits
2. **Call sync_all() on startup** to pre-populate cache
3. **Handle errors gracefully** - have fallback content
4. **Monitor cache hit rate** - adjust cache duration if needed
5. **Use specific file paths** - don't rely on file listing APIs
