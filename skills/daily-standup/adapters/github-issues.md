# GitHub Issues Task Adapter

Fetch today's tasks from GitHub Issues.

## Required source

- **Source slug**: `github`
- **Type**: MCP (stdio or bearer)
- **Server**: `@modelcontextprotocol/server-github`

## Required config

```json
{
  "tasks": {
    "provider": "github-issues",
    "github-issues": {
      "owner": "your-org",
      "repo": "your-repo",
      "assignee": "your-github-username"
    }
  }
}
```

## How to get the tasks

Use the GitHub MCP tools to query issues:

1. **Find open issues assigned to the user**: Use `list_issues` or `search_issues` with:
   - `owner`: `config.tasks.github-issues.owner`
   - `repo`: `config.tasks.github-issues.repo`
   - `assignee`: `config.tasks.github-issues.assignee`
   - `state`: `open`

2. **Group by labels** (if available):
   - **In Progress**: Issues with labels like "in progress", "wip", "doing"
   - **Upcoming**: Issues in a milestone matching the current sprint, or labeled "todo", "ready"
   - **Other**: Remaining open issues

3. **If no issues found**: Return `config.fallback.noTasksMessage`.

## Tool usage

Use `mcp__github__list_issues` or `mcp__github__search_issues`. The GitHub MCP server provides these tools.

## Output format

### In progress:
- [ ] #123 — Issue title

### Upcoming:
- #456 — Issue title
