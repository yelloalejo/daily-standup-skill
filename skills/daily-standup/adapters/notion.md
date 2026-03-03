# Notion Task Adapter

Fetch today's tasks from a Notion database.

## Required source

- **Source slug**: `notion`
- **Type**: MCP (stdio)
- **Server**: `@notionhq/notion-mcp-server`

## Required config

```json
{
  "tasks": {
    "provider": "notion",
    "notion": {
      "databaseId": "your-notion-database-id"
    }
  }
}
```

## How to get the tasks

Query the Notion database (`config.tasks.notion.databaseId`) using the Notion MCP tools:

1. **Find tasks "In Progress"**: Filter by status = "In Progress". From the results, identify which are assigned to the user by comparing the people field with `config.user.name`.

2. **If no user tasks in "In Progress"**: Search for tasks with status "Sprint" and list them as suggestions.

3. **If no tasks in "Sprint"**: Search for tasks with status "Backlog" and list them as suggestions.

4. **If no tasks in any list**: Return `config.fallback.noTasksMessage`.

## Tool usage

The exact Notion tool names may vary. Use the available Notion MCP tools (search, query database, query data source, etc.). If tools use "data source" instead of "database", adapt the calls accordingly. The assignee (people) field may have an empty string ("") as property ID.

## Output format

Return the tasks grouped as:

### In progress:
- [ ] Task title - brief description

### Upcoming (Sprint):
- Task title - description

### Backlog (if applicable):
- Task title - description
