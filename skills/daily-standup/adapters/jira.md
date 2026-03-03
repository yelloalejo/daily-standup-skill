# Jira Task Adapter

Fetch today's tasks from Jira.

## Required source

- **Source slug**: `jira`
- **Type**: API (basic auth)
- **Base URL**: `https://your-domain.atlassian.net/rest/api/3/`

## Required config

```json
{
  "tasks": {
    "provider": "jira",
    "jira": {
      "baseUrl": "https://your-domain.atlassian.net",
      "projectKey": "PROJ"
    }
  }
}
```

## How to get the tasks

Use the Jira API source to query issues via JQL:

1. **Find issues assigned to the current user in the active sprint**:
   ```
   GET search?jql=assignee=currentUser() AND sprint in openSprints() AND project={config.tasks.jira.projectKey} ORDER BY status ASC
   ```

2. **Group by status category**:
   - **In Progress**: Issues with status category "In Progress" (e.g., "In Progress", "In Review", "In QA")
   - **To Do**: Issues with status category "To Do" in the current sprint
   - **Done yesterday**: Issues moved to "Done" yesterday (for the summary)

3. **If no issues found**: Return `config.fallback.noTasksMessage`.

## Tool usage

Use the Jira API source. If `jira` source is not configured, inform the user they need to create it:
- Type: `api`
- Base URL: `{config.tasks.jira.baseUrl}/rest/api/3/`
- Auth: `basic` (email + API token from https://id.atlassian.com/manage-profile/security/api-tokens)

## Output format

### In progress:
- [ ] PROJ-123 — Issue title

### To Do (Sprint):
- PROJ-456 — Issue title
