#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Daily Standup Skill — Installer
# https://github.com/yelloalejo/daily-standup-skill
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/yelloalejo/daily-standup-skill/main/install.sh | bash
#   curl ... | bash -s -- --global                    # Install globally (default)
#   curl ... | bash -s -- --workspace my-workspace    # Install to specific Craft Agent workspace
#   curl ... | bash -s -- --skip-config               # Skip interactive config (set up later via /daily-standup)
# ─────────────────────────────────────────────

REPO_URL="https://github.com/yelloalejo/daily-standup-skill"
RAW_URL="https://raw.githubusercontent.com/yelloalejo/daily-standup-skill/main"
SKILL_SLUG="daily-standup"

# Install targets
GLOBAL_SKILLS_DIR="$HOME/.agents/skills"
CRAFT_DIR="$HOME/.craft-agent/workspaces"

# Flags
INSTALL_MODE=""          # "global" or "workspace"
TARGET_WORKSPACE=""      # specific workspace name
SKIP_CONFIG=false
UPDATE_MODE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── Argument parsing ───────────────────────

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --global|-g)
        INSTALL_MODE="global"
        shift
        ;;
      --workspace|-w)
        INSTALL_MODE="workspace"
        TARGET_WORKSPACE="${2:-}"
        shift 2
        ;;
      --update|-u)
        UPDATE_MODE=true
        SKIP_CONFIG=true
        shift
        ;;
      --skip-config)
        SKIP_CONFIG=true
        shift
        ;;
      --help|-h)
        echo "Usage: install.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --global, -g              Install globally (~/.agents/skills/) — works with all agents"
        echo "  --workspace, -w <name>    Install to a specific Craft Agent workspace"
        echo "  --update, -u              Update skill files only (preserves your config.json)"
        echo "  --skip-config             Skip config wizard (configure later via /daily-standup)"
        echo "  --help, -h                Show this help"
        exit 0
        ;;
      *)
        echo -e "${RED}Unknown option: $1${NC}"
        exit 1
        ;;
    esac
  done
}

# ─── UI helpers ─────────────────────────────

print_banner() {
  echo ""
  if [ "$UPDATE_MODE" = true ]; then
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}📋 Daily Standup Skill — Updater${NC}           ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${DIM}Updating skill files (your config is preserved).${NC}"
  else
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}📋 Daily Standup Skill — Installer${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${DIM}Automate your daily standup summary with${NC}"
    echo -e "${DIM}Git commits, tasks, and calendar events.${NC}"
  fi
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
  if ! command -v curl &>/dev/null; then missing+=("curl"); fi

  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${RED}✗ Missing dependencies: ${missing[*]}${NC}"
    echo "  Please install them and try again."
    exit 1
  fi
}

# ─── Install target selection ───────────────

choose_install_target() {
  # If mode was set via flag, use it
  if [ -n "$INSTALL_MODE" ]; then
    if [ "$INSTALL_MODE" = "workspace" ] && [ -n "$TARGET_WORKSPACE" ]; then
      setup_workspace_paths "$TARGET_WORKSPACE"
      return
    elif [ "$INSTALL_MODE" = "global" ]; then
      setup_global_paths
      return
    fi
  fi

  # Auto-detect available targets
  local has_craft=false
  local craft_workspaces=()
  if [ -d "$CRAFT_DIR" ]; then
    for dir in "$CRAFT_DIR"/*/; do
      [ -d "$dir" ] && craft_workspaces+=("$(basename "$dir")")
    done
    [ ${#craft_workspaces[@]} -gt 0 ] && has_craft=true
  fi

  echo -e "${BOLD}Where do you want to install?${NC}"
  echo ""
  echo -e "  ${BOLD}1)${NC} ${GREEN}Global${NC} ${DIM}(~/.agents/skills/)${NC}"
  echo -e "     ${DIM}Works with Claude Code, Cursor, Craft Agent, and any SKILL.md agent${NC}"

  if [ "$has_craft" = true ]; then
    local idx=2
    for ws in "${craft_workspaces[@]}"; do
      echo -e "  ${BOLD}${idx})${NC} Craft Agent → ${BOLD}${ws}${NC}"
      idx=$((idx + 1))
    done
  fi

  echo ""
  echo -ne "  ${BOLD}Select${NC} ${DIM}(1)${NC}: "
  read -r choice
  choice="${choice:-1}"

  if [ "$choice" = "1" ]; then
    setup_global_paths
  elif [ "$has_craft" = true ] && [ "$choice" -ge 2 ] 2>/dev/null; then
    local ws_idx=$((choice - 2))
    if [ "$ws_idx" -lt "${#craft_workspaces[@]}" ]; then
      setup_workspace_paths "${craft_workspaces[$ws_idx]}"
    else
      echo -e "${RED}Invalid selection${NC}"
      exit 1
    fi
  else
    echo -e "${RED}Invalid selection${NC}"
    exit 1
  fi
}

setup_global_paths() {
  SKILL_DIR="$GLOBAL_SKILLS_DIR/$SKILL_SLUG"
  SOURCES_DIR=""  # No source install for global
  INSTALL_LOCATION="global"
  echo -e "  ${GREEN}✓${NC} Installing globally to ${BOLD}~/.agents/skills/${SKILL_SLUG}/${NC}"
}

setup_workspace_paths() {
  local ws_name="$1"
  local ws_dir="$CRAFT_DIR/$ws_name"

  if [ ! -d "$ws_dir" ]; then
    echo -e "${RED}✗ Workspace not found: $ws_name${NC}"
    exit 1
  fi

  SKILL_DIR="$ws_dir/skills/$SKILL_SLUG"
  SOURCES_DIR="$ws_dir/sources"
  INSTALL_LOCATION="workspace:$ws_name"
  echo -e "  ${GREEN}✓${NC} Installing to workspace ${BOLD}${ws_name}${NC}"
}

# ─── Download ───────────────────────────────

download_file() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  curl -fsSL "$RAW_URL/$src" -o "$dest"
}

# ─── Config wizard ──────────────────────────

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
    detected_tz=$(cat /etc/timezone 2>/dev/null || true)
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

# ─── Update mode ─────────────────────────────

find_existing_installations() {
  local found=()

  # Check global
  if [ -f "$GLOBAL_SKILLS_DIR/$SKILL_SLUG/SKILL.md" ]; then
    found+=("global:$GLOBAL_SKILLS_DIR/$SKILL_SLUG")
  fi

  # Check Craft Agent workspaces
  if [ -d "$CRAFT_DIR" ]; then
    for dir in "$CRAFT_DIR"/*/skills/$SKILL_SLUG; do
      if [ -f "$dir/SKILL.md" ] 2>/dev/null; then
        local ws_name
        ws_name=$(echo "$dir" | sed "s|$CRAFT_DIR/||;s|/skills/$SKILL_SLUG||")
        found+=("workspace:$ws_name:$dir")
      fi
    done
  fi

  echo "${found[@]}"
}

run_update() {
  local installations
  installations=($(find_existing_installations))

  if [ ${#installations[@]} -eq 0 ]; then
    echo -e "${RED}✗ No existing installation found.${NC}"
    echo -e "  Run without ${BOLD}--update${NC} to install for the first time."
    exit 1
  fi

  for entry in "${installations[@]}"; do
    local type="${entry%%:*}"
    local rest="${entry#*:}"

    if [ "$type" = "global" ]; then
      local path="$rest"
      echo -e "  ${BOLD}Updating global installation...${NC}"
      update_skill_files "$path"
    elif [ "$type" = "workspace" ]; then
      local ws_name="${rest%%:*}"
      local path="${rest#*:}"
      echo -e "  ${BOLD}Updating workspace ${ws_name}...${NC}"
      update_skill_files "$path"
    fi
  done

  echo ""
  echo -e "${CYAN}══════════════════════════════════════════════${NC}"
  echo -e "${GREEN}${BOLD}✓ Update complete!${NC}"
  echo -e "${CYAN}══════════════════════════════════════════════${NC}"
  echo ""
  echo -e "  Your ${BOLD}config.json${NC} was preserved."
  echo -e "  Updated: SKILL.md, adapters, icon"
  echo ""
}

update_skill_files() {
  local target_dir="$1"

  mkdir -p "$target_dir/adapters"

  download_file "skills/daily-standup/SKILL.md" "$target_dir/SKILL.md"
  download_file "skills/daily-standup/icon.svg" "$target_dir/icon.svg"
  download_file "skills/daily-standup/config.example.json" "$target_dir/config.example.json"
  download_file "VERSION" "$target_dir/VERSION"

  for adapter in notion linear github-issues jira; do
    download_file "skills/daily-standup/adapters/${adapter}.md" "$target_dir/adapters/${adapter}.md"
  done

  echo -e "  ${GREEN}✓${NC} Skill files updated"
}

# ─── Installation ───────────────────────────

install_skill() {
  echo -e "${BOLD}Installing skill...${NC}"

  mkdir -p "$SKILL_DIR/adapters"

  download_file "skills/daily-standup/SKILL.md" "$SKILL_DIR/SKILL.md"
  download_file "skills/daily-standup/icon.svg" "$SKILL_DIR/icon.svg"
  download_file "skills/daily-standup/config.example.json" "$SKILL_DIR/config.example.json"
  download_file "VERSION" "$SKILL_DIR/VERSION"

  for adapter in notion linear github-issues jira; do
    download_file "skills/daily-standup/adapters/${adapter}.md" "$SKILL_DIR/adapters/${adapter}.md"
  done

  echo -e "  ${GREEN}✓${NC} Skill files installed"
}

install_sources() {
  # Only install sources for workspace installs
  if [ -z "$SOURCES_DIR" ]; then
    return
  fi

  echo -e "${BOLD}Installing source templates...${NC}"

  local sources_to_install=("github")

  case "$TASK_PROVIDER" in
    notion) sources_to_install+=("notion") ;;
    linear) sources_to_install+=("linear") ;;
  esac

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

# ─── Finish ─────────────────────────────────

print_next_steps() {
  echo ""
  echo -e "${CYAN}══════════════════════════════════════════════${NC}"
  echo -e "${GREEN}${BOLD}✓ Installation complete!${NC}"
  echo -e "${CYAN}══════════════════════════════════════════════${NC}"
  echo ""
  echo -e "  Type ${BOLD}/daily-standup${NC} in your agent to get started."

  if [ "$SKIP_CONFIG" = true ]; then
    echo -e "  The skill will guide you through setup on first run."
  else
    echo -e "  Your config is ready — source auth will be handled"
    echo -e "  automatically by your agent when needed."
  fi

  echo ""
  echo -e "  ${DIM}Skill: ${SKILL_DIR}${NC}"
  echo -e "  ${DIM}Repo:  ${REPO_URL}${NC}"
  echo ""
}

# ─── Main ───────────────────────────────────

main() {
  parse_args "$@"
  print_banner
  check_dependencies

  if [ "$UPDATE_MODE" = true ]; then
    run_update
  else
    choose_install_target
    echo ""

    install_skill

    if [ "$SKIP_CONFIG" = false ]; then
      step_user_info
      step_git_config
      step_task_provider
      step_calendar_config
      generate_config
      install_sources
    fi

    print_next_steps
  fi
}

main "$@"
