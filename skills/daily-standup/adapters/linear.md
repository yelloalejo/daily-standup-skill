# Linear Task Adapter

Fetch today's tasks from Linear.

## Required source

- **Source slug**: `linear`
- **Type**: MCP (OAuth)
- **URL**: `https://mcp.linear.app`

## Required config

```json
{
  "tasks": {
    "provider": "linear",
    "linear": {
      "teamId": "your-linear-team-id"
    }
  }
}
```

## How to get the tasks

Use the Linear MCP tools to query issues:

1. **Find issues assigned to the user** in the current cycle/sprint for the team `config.tasks.linear.teamId`.

2. **Group by state**:
   - **In Progress**: Issues with state type "started" (e.g., "In Progress", "In Review")
   - **Upcoming**: Issues with state type "unstarted" that are in the current cycle
   - **Backlog**: If nothing else, show backlog items

3. **If no issues found**: Return `config.fallback.noTasksMessage`.

## Tool usage

Use Linear MCP tools like `list_issues`, `search_issues`, or `get_issues`. Filter by:
- `assignee`: the authenticated user
- `team`: `config.tasks.linear.teamId`
- `cycle`: current (active) cycle

## Output format

### In progress:
- [ ] TEAM-123 — Issue title

### Upcoming (Cycle):
- TEAM-456 — Issue title
