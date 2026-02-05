# Master Brain Best Practices

## For Implementation Teams

### Version Control
- **Tag releases:** Use semantic versioning (`v1.0.0`, `v1.1.0`)
- **Branch strategy:** `main` for stable, `dev` for testing
- **Commit messages:** Clear, descriptive (e.g., "Added price objection responses to convert playbook")

### Testing
- Test changes in staging before production
- Use separate bot instance pointing to test branch
- Validate with real conversation scenarios

### Documentation
- Update `_master/docs/` when system changes
- Keep examples in `/examples/` current
- Document breaking changes in release notes

## For Clients

### Playbook Maintenance
- **Review monthly:** Check if playbooks match current process
- **Update based on data:** If bot consistently fails at X, update playbook for X
- **Keep it simple:** Write for clarity, not cleverness

### Brand Consistency
- Update social bios when positioning changes
- Keep brand assets current (new logo = update all files)
- Ensure voice guidelines match how you actually communicate

### Performance Optimization

**Monitor these metrics:**
- Bot response accuracy (are answers correct?)
- Conversation completion rate (do users finish conversations?)
- Escalation rate (how often does bot hand off to human?)

**Monthly optimization:**
1. Review conversation logs
2. Identify patterns where bot struggles
3. Update relevant playbook
4. Test and deploy
5. Measure improvement

### Security
- Rotate GitHub tokens annually
- Never commit API keys to git
- Keep `.env` in `.gitignore`

## Common Pitfalls

### Do Not Edit `/_master/` Files
Don't customize files in `/_master/` - those are system files.
Customize files in `/template/` instead.

### Do Not Commit Secrets
Never put API keys in markdown files.
Use `.env` and reference them: `[Get from .env]`

### Avoid Overly Complex Playbooks
Don't write novels. Bots work best with concise, clear instructions.
Use bullet points, short paragraphs, clear examples.

### Always Test Before Deploying
Don't push changes without testing.
Test in staging bot before production.

### Replace All Placeholders
Don't leave placeholder text like `[Your Company]`.
Replace ALL placeholders with real info.
