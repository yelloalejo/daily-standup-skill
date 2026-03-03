#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Daily Standup Skill — Installer
# https://github.com/yelloalejo/daily-standup-skill
# ─────────────────────────────────────────────

REPO_URL="https://github.com/yelloalejo/daily-standup-skill"
RAW_URL="https://raw.githubusercontent.com/yelloalejo/daily-standup-skill/main"
CRAFT_DIR="$HOME/.craft-agent/workspaces"
SKILL_SLUG="daily-standup"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

print_banner() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}  ${BOLD}📋 Daily Standup Skill — Installer${NC}          ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${DIM}Automate your daily standup summary with${NC}"
  echo -e "${DIM}Git commits, tasks, and calendar events.${NC}"
  echo ""
}

prompt() {
  local var_name="$1"
  local message="$2"
  local default="${3:-}"
  if [ -n "$default" ]; then
    echo -ne "  ${BOLD}${message}${NC} ${DIM}(${default})${NC}: "
    read -r input
    eval "$var_name=\"${input:-$default}\""
  else
    echo -ne "  ${BOLD}${message}${NC}: "
    read -r input
    eval "$var_name=\"$input\""
  fi
}

check_dependencies() {
  local missing=()
  if ! command -v git &>/dev/null; then missing+=("git"); fi
  if ! command -v curl &>/dev/null; then missing+=("curl"); fi

  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${RED}✗ Missing dependencies: ${missing[*]}${NC}"
    echo "  Please install them and try again."
    exit 1
  fi
}

detect_workspace() {
  if [ ! -d "$CRAFT_DIR" ]; then
    echo -e "${RED}✗ Craft Agent workspace not found at $CRAFT_DIR${NC}"
    echo "  This installer targets Craft Agent. For other agents, use: npx skills add yelloalejo/daily-standup-skill"
    exit 1
  fi

  local workspaces=()
  for dir in "$CRAFT_DIR"/*/; do
    [ -d "$dir" ] && workspaces+=("$(basename "$dir")")
  done

  if [ ${#workspaces[@]} -eq 0 ]; then
    echo -e "${RED}✗ No workspaces found in $CRAFT_DIR${NC}"
    exit 1
  elif [ ${#workspaces[@]} -eq 1 ]; then
    WORKSPACE="${workspaces[0]}"
    echo -e "  ${GREEN}✓${NC} Found workspace: ${BOLD}${WORKSPACE}${NC}"
  else
    echo -e "  Found ${#workspaces[@]} workspaces:"
    for i in "${!workspaces[@]}"; do
      echo -e "    ${BOLD}$((i+1)))${NC} ${workspaces[$i]}"
    done
    echo -ne "  ${BOLD}Select workspace${NC} ${DIM}(1)${NC}: "
    read -r choice
    choice="${choice:-1}"
    WORKSPACE="${workspaces[$((choice-1))]}"
  fi

  WORKSPACE_DIR="$CRAFT_DIR/$WORKSPACE"
  SKILLS_DIR="$WORKSPACE_DIR/skills"
  SOURCES_DIR="$WORKSPACE_DIR/sources"
  SKILL_DIR="$SKILLS_DIR/$SKILL_SLUG"
}

download_file() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  curl -fsSL "$RAW_URL/$src" -o "$dest"
}

step_user_info() {
  echo -e "${BLUE}Step 1/4 — About you${NC}"
  echo ""
  prompt USER_NAME "Your full name"
  prompt GIT_EMAIL "Git email"
  prompt CAL_EMAILS "Calendar emails (comma-separated)"
  prompt LANG_PREF "Preferred language" "en"
  echo ""
}

step_git_config() {
  echo -e "${BLUE}Step 2/4 — Git repository${NC}"
  echo ""
  prompt GIT_OWNER "GitHub org or username"
  prompt GIT_REPO "Repository name"
  prompt GIT_BRANCH "Default branch" "main"
  echo ""
}

step_task_provider() {
  echo -e "${BLUE}Step 3/4 — Task management${NC}"
  echo ""
  echo "  Which tool do you use for task tracking?"
  echo -e "    ${BOLD}1)${NC} Notion"
  echo -e "    ${BOLD}2)${NC} Linear"
  echo -e "    ${BOLD}3)${NC} GitHub Issues"
  echo -e "    ${BOLD}4)${NC} Jira"
  echo -e "    ${BOLD}5)${NC} None / Skip"
  echo ""
  echo -ne "  ${BOLD}Select${NC} ${DIM}(1)${NC}: "
  read -r task_choice
  task_choice="${task_choice:-1}"

  TASK_PROVIDER="none"
  TASK_CONFIG=""

  case "$task_choice" in
    1)
      TASK_PROVIDER="notion"
      prompt NOTION_DB_ID "Notion database ID"
      TASK_CONFIG="\"notion\": { \"databaseId\": \"$NOTION_DB_ID\" }"
      ;;
    2)
      TASK_PROVIDER="linear"
      prompt LINEAR_TEAM_ID "Linear team ID"
      TASK_CONFIG="\"linear\": { \"teamId\": \"$LINEAR_TEAM_ID\" }"
      ;;
    3)
      TASK_PROVIDER="github-issues"
      prompt GH_ISSUES_OWNER "GitHub Issues owner" "$GIT_OWNER"
      prompt GH_ISSUES_REPO "GitHub Issues repo" "$GIT_REPO"
      prompt GH_ISSUES_ASSIGNEE "GitHub username (assignee)"
      TASK_CONFIG="\"github-issues\": { \"owner\": \"$GH_ISSUES_OWNER\", \"repo\": \"$GH_ISSUES_REPO\", \"assignee\": \"$GH_ISSUES_ASSIGNEE\" }"
      ;;
    4)
      TASK_PROVIDER="jira"
      prompt JIRA_URL "Jira base URL (e.g., https://your-domain.atlassian.net)"
      prompt JIRA_PROJECT "Jira project key (e.g., PROJ)"
      TASK_CONFIG="\"jira\": { \"baseUrl\": \"$JIRA_URL\", \"projectKey\": \"$JIRA_PROJECT\" }"
      ;;
    5)
      TASK_PROVIDER="none"
      ;;
  esac
  echo ""
}

step_calendar_config() {
  echo -e "${BLUE}Step 4/4 — Calendar${NC}"
  echo ""

  # Try to detect timezone
  local detected_tz=""
  if command -v timedatectl &>/dev/null; then
    detected_tz=$(timedatectl show -p Timezone --value 2>/dev/null || true)
  fi
  if [ -z "$detected_tz" ] && [ -f /etc/timezone ]; then
    detected_tz=$(cat /etc/timezone)
  fi
  if [ -z "$detected_tz" ] && command -v readlink &>/dev/null; then
    detected_tz=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || true)
  fi
  detected_tz="${detected_tz:-America/New_York}"

  prompt TIMEZONE "Timezone" "$detected_tz"

  echo ""
  echo "  Do you want to include Google Calendar events?"
  echo -ne "  ${BOLD}(y/n)${NC} ${DIM}(y)${NC}: "
  read -r cal_choice
  cal_choice="${cal_choice:-y}"

  if [[ "$cal_choice" =~ ^[Yy] ]]; then
    CAL_PROVIDER="google-calendar"
  else
    CAL_PROVIDER="none"
  fi
  echo ""
}

generate_config() {
  local cal_emails_json=""
  IFS=',' read -ra emails <<< "$CAL_EMAILS"
  for i in "${!emails[@]}"; do
    local email
    email=$(echo "${emails[$i]}" | xargs) # trim whitespace
    if [ "$i" -gt 0 ]; then cal_emails_json+=", "; fi
    cal_emails_json+="\"$email\""
  done

  local fallback_msg="I'll review priorities and pick up a new task."
  if [ "$LANG_PREF" = "es" ]; then
    fallback_msg="Voy a revisar prioridades para tomar una nueva tarea."
  fi

  local tasks_block="\"provider\": \"$TASK_PROVIDER\""
  if [ -n "$TASK_CONFIG" ]; then
    tasks_block+=",
    $TASK_CONFIG"
  fi

  cat > "$SKILL_DIR/config.json" << HEREDOC
{
  "user": {
    "name": "$USER_NAME",
    "gitEmail": "$GIT_EMAIL",
    "calendarEmails": [$cal_emails_json]
  },
  "git": {
    "provider": "github",
    "owner": "$GIT_OWNER",
    "repo": "$GIT_REPO",
    "defaultBranch": "$GIT_BRANCH"
  },
  "tasks": {
    $tasks_block
  },
  "calendar": {
    "provider": "$CAL_PROVIDER",
    "timezone": "$TIMEZONE",
    "ignoredPatterns": ["sync", "daily", "standup", "scrum", "lunch"],
    "ignoredEventTypes": ["outOfOffice"]
  },
  "output": {
    "language": "$LANG_PREF"
  },
  "fallback": {
    "noTasksMessage": "$fallback_msg"
  }
}
HEREDOC
}

install_skill() {
  echo -e "${BOLD}Installing skill...${NC}"

  mkdir -p "$SKILL_DIR/adapters"

  # Download skill files
  download_file "skills/daily-standup/SKILL.md" "$SKILL_DIR/SKILL.md"
  download_file "skills/daily-standup/icon.svg" "$SKILL_DIR/icon.svg"
  download_file "skills/daily-standup/config.example.json" "$SKILL_DIR/config.example.json"

  # Download adapters
  for adapter in notion linear github-issues jira; do
    download_file "skills/daily-standup/adapters/${adapter}.md" "$SKILL_DIR/adapters/${adapter}.md"
  done

  echo -e "  ${GREEN}✓${NC} Skill files installed"
}

install_sources() {
  echo -e "${BOLD}Installing source templates...${NC}"

  # Always install GitHub source template
  local sources_to_install=("github")

  # Add task provider source
  case "$TASK_PROVIDER" in
    notion) sources_to_install+=("notion") ;;
    linear) sources_to_install+=("linear") ;;
    # github-issues uses the github source (already included)
    # jira needs manual setup (API source)
  esac

  # Add calendar source
  if [ "$CAL_PROVIDER" = "google-calendar" ]; then
    sources_to_install+=("google-calendar")
  fi

  for source in "${sources_to_install[@]}"; do
    local source_dir="$SOURCES_DIR/$source"
    if [ -d "$source_dir" ] && [ -f "$source_dir/config.json" ]; then
      echo -e "  ${YELLOW}⊘${NC} Source ${BOLD}${source}${NC} already exists — skipping"
    else
      mkdir -p "$source_dir"
      download_file "sources/${source}/config.template.json" "$source_dir/config.json"
      download_file "sources/${source}/guide.md" "$source_dir/guide.md"
      download_file "sources/${source}/permissions.json" "$source_dir/permissions.json"

      # Generate unique ID
      local random_id
      random_id=$(LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom | head -c 8)
      local slug_safe
      slug_safe=$(echo "$source" | tr '-' '_')

      if command -v sed &>/dev/null; then
        sed -i.bak "s/\"connectionStatus\"/\"id\": \"${slug_safe}_${random_id}\",\n  \"connectionStatus\"/" "$source_dir/config.json" 2>/dev/null && rm -f "$source_dir/config.json.bak" || true
      fi

      echo -e "  ${GREEN}✓${NC} Source ${BOLD}${source}${NC} template installed"
    fi
  done
}

print_next_steps() {
  echo ""
  echo -e "${CYAN}══════════════════════════════════════════════${NC}"
  echo -e "${GREEN}${BOLD}✓ Installation complete!${NC}"
  echo -e "${CYAN}══════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${BOLD}Next steps — Authenticate your sources:${NC}"
  echo ""
  echo -e "  ${BOLD}1. GitHub${NC}"
  echo "     Create a Personal Access Token (classic or fine-grained):"
  echo "     https://github.com/settings/tokens"
  echo "     Then update the token in your source config or paste it"
  echo "     when your agent asks."
  echo ""

  case "$TASK_PROVIDER" in
    notion)
      echo -e "  ${BOLD}2. Notion${NC}"
      echo "     Create an integration at: https://notion.so/my-integrations"
      echo "     Share your task database with the integration."
      echo "     Then update the token in your source config."
      echo ""
      ;;
    linear)
      echo -e "  ${BOLD}2. Linear${NC}"
      echo "     Authenticate via OAuth when your agent prompts you."
      echo ""
      ;;
    jira)
      echo -e "  ${BOLD}2. Jira${NC}"
      echo "     Create an API token at:"
      echo "     https://id.atlassian.com/manage-profile/security/api-tokens"
      echo "     You'll need to set up the Jira source manually in your agent."
      echo ""
      ;;
  esac

  if [ "$CAL_PROVIDER" = "google-calendar" ]; then
    local step_num=3
    [ "$TASK_PROVIDER" = "none" ] && step_num=2
    echo -e "  ${BOLD}${step_num}. Google Calendar${NC}"
    echo "     Create OAuth credentials at Google Cloud Console:"
    echo "     https://console.cloud.google.com/apis/credentials"
    echo "     Enable the Google Calendar API, then authenticate"
    echo "     via OAuth in your agent."
    echo ""
  fi

  echo -e "${CYAN}──────────────────────────────────────────────${NC}"
  echo ""
  echo -e "  Open your agent and type ${BOLD}/daily-standup${NC}"
  echo ""
  echo -e "  ${DIM}Skill: ${SKILL_DIR}${NC}"
  echo -e "  ${DIM}Repo:  ${REPO_URL}${NC}"
  echo ""
}

# ─── Main ───────────────────────────────────

main() {
  print_banner
  check_dependencies

  echo -e "${BOLD}Detecting workspace...${NC}"
  detect_workspace
  echo ""

  step_user_info
  step_git_config
  step_task_provider
  step_calendar_config

  install_skill
  generate_config
  install_sources
  print_next_steps
}

main "$@"
