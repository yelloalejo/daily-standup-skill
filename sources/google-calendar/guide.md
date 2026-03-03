# Google Calendar

Calendar events, meetings, and availability via the Google Calendar API.

## Scope

Access to the authenticated user's calendars, events, and free/busy information.

## Guidelines

- Use ISO 8601 format for dates: `2026-01-15T10:00:00-05:00`
- The primary calendar is accessed with `calendars/primary`
- List events with `calendars/primary/events` using `timeMin` and `timeMax` parameters
- Always include `timeZone` in queries (configured in skill's config.json)
- Expand recurring events with `singleEvents=true`
- Sort by date with `orderBy=startTime` (requires `singleEvents=true`)

## API Reference

### GET calendars/primary/events
List events from the primary calendar.

**Useful parameters:**
- `timeMin` (datetime): Range start (RFC 3339)
- `timeMax` (datetime): Range end (RFC 3339)
- `timeZone` (string): Timezone for the response
- `singleEvents` (boolean): Expand recurring events
- `orderBy` (string): `startTime` or `updated`

## Setup

1. Create OAuth credentials at [Google Cloud Console](https://console.cloud.google.com/apis/credentials) (Desktop app type)
2. Enable the Google Calendar API
3. Add your Client ID and Client Secret to the source config
4. Authenticate via OAuth in Craft Agent
