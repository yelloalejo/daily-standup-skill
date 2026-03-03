---
name: "Daily Standup"
description: "Generate your daily standup summary: what you did yesterday and what you'll work on today"
requiredSources:
  - github
  - google-calendar
alwaysAllow: ["Bash", "Read", "mcp__github__list_commits", "mcp__google-calendar__api_google-calendar"]
---

# Daily Standup

Generate a complete summary for daily standup meetings by pulling data from Git commits, task management tools, and calendar events.

## Required connections

This skill needs the following MCP sources configured:

| Source | Required | Purpose |
|--------|----------|---------|
| **GitHub** | Yes | Remote commits by branch |
| **Google Calendar** | Optional | Today's meetings |
| **Notion** | If tasks.provider = notion | Sprint board tasks |
| **Linear** | If tasks.provider = linear | Cycle issues |
| **Jira** | If tasks.provider = jira | Sprint tickets |

If a connection fails during execution, show a clear message indicating which one is missing. Generate the summary with the sources that do work and warn about the missing ones at the end.

## Step 0: Read or create user configuration

**BEFORE doing anything else**, try to read the configuration file:

```
Read: {skill_base_dir}/config.json
```

Where `{skill_base_dir}` is the base directory of this skill (provided as "Base directory for this skill" when invoked).

### If `config.json` exists

Use its values in all following steps. References like `config.user.name` mean the value of that key in the JSON. Proceed to Step 1.

### If `config.json` does NOT exist — Interactive Setup

Run an interactive setup by asking the user a few quick questions. Keep it conversational and friendly.

**Ask these questions (all at once, in a single message):**

1. **Your name** — as it appears in git commits (e.g., "Diego Marulanda")
2. **Git email** — the email you use for git
3. **GitHub org/user and repo** — e.g., "mycompany/backend"
4. **Task management tool** — Notion, Linear, GitHub Issues, Jira, or none
5. **Google Calendar** — yes/no, and your calendar email(s)
6. **Timezone** — e.g., America/New_York
7. **Language** — en or es

**After the user responds**, generate `config.json` automatically using the Write tool:

- Parse their answers and map them to the config schema (see `config.example.json` for reference)
- For the task provider, ask the one follow-up question needed:
  - Notion → "What's your Notion database ID?" (explain: it's in the database URL after the workspace name)
  - Linear → "What's your Linear team ID?"
  - GitHub Issues → use the same owner/repo from git config, ask for their GitHub username
  - Jira → "What's your Jira domain and project key?" (e.g., mycompany.atlassian.net, PROJ)
- Set sensible defaults:
  - `calendar.ignoredPatterns`: `["sync", "daily", "standup", "scrum", "lunch"]`
  - `calendar.ignoredEventTypes`: `["outOfOffice"]`
  - `fallback.noTasksMessage`: `"I'll review priorities and pick up a new task."` (en) or `"Voy a revisar prioridades para tomar una nueva tarea."` (es)
- Write the file to `{skill_base_dir}/config.json`
- Confirm to the user: "Config saved! Running your first daily standup..."
- Then proceed to Step 1 normally.

**Important**: Do NOT ask the user to manually edit JSON files. The setup must be conversational.

## Step 1: Determine dates

- **Yesterday**: calculate yesterday's date based on the user's current date (provided in the system prompt as USER'S DATE AND TIME). Format: `YYYY-MM-DD`.
- **Today**: user's current date.
- If today is Monday, "yesterday" refers to the previous Friday.

## Step 2: Get yesterday's commits

### 2a. Remote commits (GitHub)

Use `mcp__github__list_commits` for the repo `config.git.owner`/`config.git.repo`:

1. Query commits on `config.git.defaultBranch` filtered by author `config.user.name` and yesterday's date (`since` and `until` in ISO 8601 format).
2. Search commits on other active branches. Use `git branch -r --sort=-committerdate` locally to get branches with recent activity, and query yesterday's commits on the 10-15 most active branches.
3. Group commits by branch.

### 2b. Local commits

Run in bash:
```bash
git log --all --author="<config.user.name>" --since="YYYY-MM-DD 00:00:00" --until="YYYY-MM-DD 23:59:59" --format="%h %s (%D)" --no-merges
```
Where the date is yesterday's. This captures commits on local branches that may not be on remote yet.

## Step 3: Get today's tasks

Read the adapter file for the configured task provider:

```
Read: {skill_base_dir}/adapters/{config.tasks.provider}.md
```

Follow the instructions in the adapter file to obtain today's tasks. Pass the relevant config section (e.g., `config.tasks.notion` for Notion) as context.

**If the adapter file does not exist**: Inform the user that the task provider `{config.tasks.provider}` is not yet supported. List available adapters and suggest they contribute one.

**If `config.tasks.provider` is not set or is `"none"`**: Skip this section entirely.

## Step 4: Get today's events from calendar

**If `config.calendar.provider` is not set or is `"none"`**: Skip this section.

Query Google Calendar using the API (`mcp__google-calendar__api_google-calendar`) to get today's events:

1. **List today's events**: GET `calendars/primary/events` with:
   - `timeMin`: start of today in RFC 3339 format with the offset from `config.calendar.timezone`
   - `timeMax`: end of today in RFC 3339 format with the offset from `config.calendar.timezone`
   - `timeZone`: `config.calendar.timezone`
   - `singleEvents`: `true`
   - `orderBy`: `startTime`

2. **Extract from each event**: title (`summary`), start and end time, and attendees if any.

3. **Ignore** the following events:
   - Cancelled events (`status: "cancelled"`)
   - Irrelevant all-day events
   - Events whose title contains (case-insensitive) any of the words in `config.calendar.ignoredPatterns`
   - Events whose `eventType` is in `config.calendar.ignoredEventTypes`
   - Events where the user declined: if in the `attendees` list any of the emails in `config.user.calendarEmails` has `responseStatus: "declined"`

## Step 5: Generate the summary

Produce the output in `config.output.language` (default: "en"). Use the templates below, adapting to the configured language.

---

### If language = "en":

## Daily standup summary

**Yesterday:**
[Natural language summary, in first person, as if the user were saying it in the meeting. NOT a list of commits, but a synthesis of the topics/features worked on. Example: "I worked on fixing the wallet issue and reverting the Akua bypass that was causing conflicts."]

**Today:**
[Natural language summary of today's tasks and meetings. Example: "Today I'll continue with the payment module integration. I have a team meeting at 10am and a client call at 3pm."]

---

## Commit details — yesterday ([weekday] [date])

### branch `branch-name`
- `hash` commit description
- `hash` commit description

> If no commits yesterday: "No commits found for yesterday."

---

## Today's tasks ([weekday] [date])

### In progress:
- [ ] Task 1 - brief description
- [ ] Task 2 - brief description

### Upcoming (Sprint/Cycle):
- Task A - description
- Task B - description

> If no tasks: show `config.fallback.noTasksMessage`

---

## Today's meetings ([weekday] [date])

- **10:00 - 11:00** — Meeting name
- **15:00 - 15:30** — Meeting name (with Person X, Person Y)

> If no events: "No meetings scheduled for today."

---

### If language = "es":

## Resumen para la daily

**Ayer:**
[Resumen en lenguaje natural, en primera persona. Ejemplo: "Estuve trabajando en la corrección del problema del wallet y haciendo un revert del bypass de Akua."]

**Hoy:**
[Resumen en lenguaje natural de las tareas y reuniones. Ejemplo: "Hoy voy a continuar con la integración del módulo de dispersiones. Tengo una reunión de equipo a las 10am."]

---

## Detalle de commits de ayer ([día de la semana] [fecha])

### rama `nombre-rama`
- `hash` descripción del commit

> Si no hubo commits ayer: "No se encontraron commits de ayer."

---

## Tareas de hoy ([día de la semana] [fecha])

### En progreso:
- [ ] Tarea 1 - descripción breve

### Próximas (Sprint):
- Tarea A - descripción

> Si no hay tareas: mostrar `config.fallback.noTasksMessage`

---

## Reuniones de hoy ([día de la semana] [fecha])

- **10:00 - 11:00** — Nombre de la reunión

> Si no hay eventos: "No hay reuniones programadas para hoy."

---

## Important rules

- The natural language summary must be **concise and natural**, as if the user were saying it out loud.
- Group commits by topic/feature, don't list each commit individually in the oral summary.
- Dates should be shown in the configured language (Monday/lunes, etc.).
- If there are errors connecting to any source, show what you can and warn about unavailable sources.
- Execute queries in parallel when possible (GitHub + Tasks + Calendar simultaneously).
