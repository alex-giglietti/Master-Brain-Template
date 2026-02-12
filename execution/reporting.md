# Reporting Instructions

> Replace this template content with your actual reporting procedures

## Report Types

### Daily Reports
**Purpose:** Quick pulse check on operations
**Owner:** [Role]
**Distribution:** [Team/Channel]

**Contents:**
- Key metrics snapshot
- Issues/blockers
- Wins/completions

### Weekly Reports
**Purpose:** Progress tracking and planning
**Owner:** [Role]
**Distribution:** [Team/Channel]
**Due:** [Day and time]

**Contents:**
- Week accomplishments
- Metrics vs. targets
- Next week priorities
- Resource needs
- Risks/concerns

### Monthly Reports
**Purpose:** Performance review and trends
**Owner:** [Role]
**Distribution:** [Leadership/Stakeholders]
**Due:** [Day of month]

**Contents:**
- Executive summary
- Financial performance
- Client metrics
- Team metrics
- Strategic initiatives update
- Recommendations

## Key Performance Indicators

### Sales Metrics
| Metric | Definition | Target | Data Source |
|--------|------------|--------|-------------|
| Leads Generated | New leads entered | [X]/week | CRM |
| Qualification Rate | Leads qualified / Total leads | [X]% | CRM |
| Conversion Rate | Deals won / Proposals sent | [X]% | CRM |
| Average Deal Size | Revenue / Deals closed | $[X] | CRM |
| Sales Cycle Length | Days from lead to close | [X] days | CRM |

### Delivery Metrics
| Metric | Definition | Target | Data Source |
|--------|------------|--------|-------------|
| On-Time Delivery | Projects delivered on schedule | [X]% | PM Tool |
| Client Satisfaction | CSAT score | [X]/5 | Survey |
| First Response Time | Time to initial response | < [X] hours | Support |
| Resolution Time | Time to close tickets | < [X] hours | Support |
| Utilization Rate | Billable hours / Available hours | [X]% | Time tracking |

### Financial Metrics
| Metric | Definition | Target | Data Source |
|--------|------------|--------|-------------|
| Revenue | Total invoiced | $[X]/month | Accounting |
| MRR | Monthly recurring revenue | $[X] | Accounting |
| Gross Margin | (Revenue - COGS) / Revenue | [X]% | Accounting |
| Collections | Received / Invoiced | [X]% | Accounting |

## Dashboard Locations

### Real-time Dashboards
- **Sales Dashboard:** [URL or tool]
- **Support Dashboard:** [URL or tool]
- **Financial Dashboard:** [URL or tool]

### Report Templates
- **Weekly Report Template:** [Location]
- **Monthly Report Template:** [Location]
- **Client Report Template:** [Location]

## Bot Reporting

### Automated Reports from Bots
Bots can generate and send reports:

```python
# Example: Bot sends daily summary
def generate_daily_summary():
    conversations = get_todays_conversations()
    leads = count_new_leads()
    issues = count_open_issues()

    return f"""
    Daily Bot Summary - {date.today()}

    Conversations: {len(conversations)}
    New Leads: {leads}
    Issues Logged: {issues}

    Top Topics: {get_top_topics()}
    """
```

### Bot Performance Metrics
Track these for bot optimization:
- Conversations handled
- Successful handoffs
- Response accuracy
- User satisfaction ratings

## Report Distribution

### Channels
- **Email:** Weekly and monthly reports
- **Slack/Teams:** Daily updates
- **Dashboard:** Real-time access

### Access Levels
| Report Type | Team | Management | Executive | Client |
|-------------|------|------------|-----------|--------|
| Daily | Yes | Yes | No | No |
| Weekly | Yes | Yes | Summary | No |
| Monthly | Summary | Yes | Yes | Custom |

## Data Quality

### Validation Checks
- All required fields populated
- Numbers within expected ranges
- Dates are current
- Sources are consistent

### Common Issues
- Missing CRM updates
- Delayed time entry
- Inconsistent categorization
- Duplicate records

---

*Last updated: [Date]*
