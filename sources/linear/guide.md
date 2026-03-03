# Linear

Issue tracking, sprint planning, and project management via the official Linear MCP server.

## Scope

Access to issues, projects, and cycles associated with the authenticated user's Linear account.

## Guidelines

- Use `list_issues` to get issues by team, cycle, or assignee
- Use `search_issues` to search across all issues
- Use `get_issue` to get details of a specific issue
- Filter by state type: "started" (in progress), "unstarted" (to do), "completed" (done)
- Use cycle filters to get issues in the current sprint

## Setup

1. Authentication is handled via OAuth — your agent will prompt you to log in to Linear
2. No token needed — just authenticate when prompted
