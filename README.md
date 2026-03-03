# 📋 Daily Standup Skill

> Automate your daily standup summary — commits, tasks, and calendar events in one command.

An AI agent skill that generates your daily standup report by pulling data from Git, your task manager, and your calendar. Works with **Notion**, **Linear**, **GitHub Issues**, and **Jira**. Compatible with [Craft Agent](https://craft.do/agents), [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Cursor](https://cursor.sh), and any agent that supports the [SKILL.md format](https://skills.sh).

[Leer en español](README.es.md)

## Quick Install

### Interactive installer (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/yelloalejo/daily-standup-skill/main/install.sh | bash
```

The installer will:
1. Ask for your info (name, email, timezone)
2. Let you pick your task management tool
3. Install the skill and source templates
4. Generate your personal `config.json`

### Using npx skills (skills.sh ecosystem)

```bash
npx skills add yelloalejo/daily-standup-skill
```

> Note: This installs only the skill files. You'll need to configure sources and `config.json` manually.

## Usage

In your AI agent, type:

```
/daily-standup
```

The skill will generate a summary like:

> **Yesterday:**
> I worked on fixing the authentication flow and added unit tests for the payment module.
>
> **Today:**
> I'll continue with the Stripe webhook integration. I have a team sync at 10am and a 1:1 at 3pm.

Plus detailed sections with commits, tasks, and meetings.

## Supported Integrations

| Integration | Type | Purpose |
|-------------|------|---------|
| **GitHub** | Required | Git commits by branch |
| **Notion** | Task provider | Sprint board tasks |
| **Linear** | Task provider | Cycle issues |
| **GitHub Issues** | Task provider | Repository issues |
| **Jira** | Task provider | Sprint tickets |
| **Google Calendar** | Optional | Today's meetings |

## Configuration

After installation, your config lives at:
```
~/.craft-agent/workspaces/{workspace}/skills/daily-standup/config.json
```

See [config.example.json](skills/daily-standup/config.example.json) for the full schema.

### Key fields

| Field | Description |
|-------|-------------|
| `user.name` | Your name (used to filter commits and tasks) |
| `user.gitEmail` | Email used in git commits |
| `user.calendarEmails` | Emails to check declined events |
| `git.owner` / `git.repo` | GitHub org and repository |
| `tasks.provider` | `notion`, `linear`, `github-issues`, `jira`, or `none` |
| `calendar.provider` | `google-calendar` or `none` |
| `calendar.timezone` | Your timezone (e.g., `America/New_York`) |
| `output.language` | `en` or `es` |

## Source Authentication

After installing, you need to authenticate each source in your agent:

### GitHub
1. Create a [Personal Access Token](https://github.com/settings/tokens) with repo access
2. Update the token in `~/.craft-agent/.../sources/github/config.json`

### Notion
1. Create an integration at [notion.so/my-integrations](https://notion.so/my-integrations)
2. Share your task database with the integration
3. Update the token in the Notion source config

### Linear
1. Authentication is handled via OAuth — your agent will prompt you

### Google Calendar
1. Create OAuth credentials at [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Enable the Google Calendar API
3. Update Client ID and Secret in the source config
4. Authenticate via OAuth in your agent

## Adding a Custom Adapter

Want to add support for a new task management tool? Create a new adapter:

1. Create `skills/daily-standup/adapters/your-tool.md`
2. Follow the format of existing adapters (see [notion.md](skills/daily-standup/adapters/notion.md) as reference)
3. Document: required source, config fields, how to query tasks, output format
4. Optionally add a source template in `sources/your-tool/`
5. Submit a PR!

## Project Structure

```
├── skills/daily-standup/
│   ├── SKILL.md              # Main skill instructions
│   ├── icon.svg              # Skill icon
│   ├── config.example.json   # Configuration template
│   └── adapters/             # Task provider adapters
│       ├── notion.md
│       ├── linear.md
│       ├── github-issues.md
│       └── jira.md
├── sources/                  # MCP source templates
│   ├── github/
│   ├── notion/
│   ├── linear/
│   └── google-calendar/
├── install.sh                # Interactive installer
└── README.md
```

## Contributing

Contributions are welcome! Some ideas:

- **New task adapters**: Asana, ClickUp, Todoist, Trello, Monday.com
- **New calendar providers**: Outlook/Microsoft Calendar
- **New languages**: Add support for more languages in the output
- **Improvements**: Better commit grouping, smarter summaries

## License

[MIT](LICENSE)
