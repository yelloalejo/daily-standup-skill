# GitHub

Access to GitHub repositories, issues, pull requests, and code search via the official MCP server.

## Scope

Full access to repositories and organizations associated with the configured PAT.

## Guidelines

- Use `search_repositories` or `list_repos` to find repositories
- Use `get_issue` / `list_issues` for issue tracking
- Use `get_pull_request` / `list_pull_requests` for PR management
- Use `search_code` for code search across repos
- Use `list_commits` for commit history by branch and author
- Rate limits apply per GitHub API guidelines (5000 req/hour for authenticated users)
