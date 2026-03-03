# Notion

Access to Notion databases for task management, sprint boards, and project tracking.

## Scope

Access to pages and databases shared with the configured integration.

## Guidelines

- Use `notion_search_pages` to search tasks by title
- Use `notion_query_database` or data source tools to filter by status and assignee
- The database ID is configured in the skill's `config.json` under `tasks.notion.databaseId`
- Common status values: "In Progress", "Sprint", "Backlog", "Done"
- Filter by the person field to get tasks assigned to the current user

## Setup

1. Create an integration at https://notion.so/my-integrations
2. Copy the integration token
3. Share your task database with the integration (click "..." on the database page > "Connections" > select your integration)
