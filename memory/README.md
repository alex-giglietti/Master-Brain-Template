# Memory Directory

This directory stores dynamic conversation history and learned preferences for the AI bot.

## Purpose

The memory directory serves as a space for:
- Conversation logs
- User preferences
- Learned patterns
- Session data

## Important Notes

1. **This directory is gitignored** - Contents are not tracked in version control
2. **Store in external database** - For production, use a proper database
3. **Regular backups** - Implement backup procedures for important data
4. **Privacy compliance** - Ensure data handling meets privacy requirements

## File Types

When using file-based storage (development only):

| File Pattern | Purpose |
|--------------|---------|
| `conversations/*.json` | Individual conversation logs |
| `preferences/*.json` | User preference data |
| `context/*.json` | Contextual memory |

## Production Setup

For production environments, configure external storage:

```python
# Example: Using database instead of files
DATABASE_URL = os.getenv("DATABASE_URL")

# Or configure cloud storage
AWS_S3_BUCKET = os.getenv("MEMORY_S3_BUCKET")
```

## Data Retention

Implement appropriate data retention policies:
- Short-term memory: 30 days
- Long-term patterns: 1 year
- Anonymized analytics: Indefinite

---

*This README is tracked; actual memory files are not.*
