#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Daily Standup Skill — Validation
# Checks structure, JSON, references, and installer
# ─────────────────────────────────────────────

PASS=0
FAIL=0
WARN=0

pass() { echo -e "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ❌ $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "  ⚠️  $1"; WARN=$((WARN + 1)); }

# ─── 1. Required files exist ────────────────

echo ""
echo "📁 Structure"

required_files=(
  "skills/daily-standup/SKILL.md"
  "skills/daily-standup/config.example.json"
  "skills/daily-standup/icon.svg"
  "install.sh"
  "VERSION"
  "README.md"
  "README.es.md"
  "LICENSE"
  ".gitignore"
)

for f in "${required_files[@]}"; do
  if [ -f "$f" ]; then
    pass "$f"
  else
    fail "$f — missing"
  fi
done

# ─── 2. Adapters referenced in SKILL.md exist ──

echo ""
echo "🔌 Adapters"

adapters_dir="skills/daily-standup/adapters"
expected_adapters=(notion linear github-issues jira)

for adapter in "${expected_adapters[@]}"; do
  adapter_file="$adapters_dir/${adapter}.md"
  if [ -f "$adapter_file" ]; then
    # Check it's referenced in SKILL.md
    if grep -q "$adapter" skills/daily-standup/SKILL.md; then
      pass "$adapter — file exists + referenced in SKILL.md"
    else
      warn "$adapter — file exists but NOT referenced in SKILL.md"
    fi
  else
    fail "$adapter — file missing at $adapter_file"
  fi
done

# ─── 3. JSON validity ───────────────────────

echo ""
echo "📋 JSON validation"

json_files=(
  "skills/daily-standup/config.example.json"
  "sources/github/config.template.json"
  "sources/notion/config.template.json"
  "sources/linear/config.template.json"
  "sources/google-calendar/config.template.json"
)

for jf in "${json_files[@]}"; do
  if [ ! -f "$jf" ]; then
    fail "$jf — file missing"
    continue
  fi
  if python3 -c "import json; json.load(open('$jf'))" 2>/dev/null; then
    pass "$jf"
  elif node -e "JSON.parse(require('fs').readFileSync('$jf','utf8'))" 2>/dev/null; then
    pass "$jf"
  else
    fail "$jf — invalid JSON"
  fi
done

# ─── 4. Source templates ─────────────────────

echo ""
echo "🔗 Source templates"

sources=(github notion linear google-calendar)

for src in "${sources[@]}"; do
  src_dir="sources/$src"
  if [ -f "$src_dir/config.template.json" ]; then
    pass "$src — config.template.json exists"
  else
    fail "$src — config.template.json missing"
  fi
  if [ -f "$src_dir/guide.md" ]; then
    pass "$src — guide.md exists"
  else
    warn "$src — guide.md missing"
  fi
  if [ -f "$src_dir/permissions.json" ]; then
    pass "$src — permissions.json exists"
  else
    warn "$src — permissions.json missing"
  fi
done

# ─── 5. VERSION file ────────────────────────

echo ""
echo "🏷️  Version"

if [ -f "VERSION" ]; then
  version=$(cat VERSION | tr -d '[:space:]')
  if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    pass "VERSION = $version (valid semver)"
  else
    fail "VERSION = '$version' (not valid semver X.Y.Z)"
  fi
else
  fail "VERSION file missing"
fi

# ─── 6. Installer flags ─────────────────────

echo ""
echo "🛠️  Installer"

if [ ! -f "install.sh" ]; then
  fail "install.sh missing — skipping installer checks"
else
  if [ -x "install.sh" ] || head -1 install.sh | grep -q "bash"; then
    pass "install.sh is a bash script"
  else
    warn "install.sh may not be executable"
  fi

  for flag in "--global" "--workspace" "--update" "--skip-config" "--help"; do
    if grep -q -- "$flag" install.sh; then
      pass "Flag $flag supported"
    else
      fail "Flag $flag not found in installer"
    fi
  done

  # Check it doesn't contain hardcoded tokens
  if grep -qiE "(ghp_|github_pat_|ntn_|sk-|Bearer [A-Za-z0-9])" install.sh; then
    fail "install.sh contains what looks like a hardcoded token!"
  else
    pass "No hardcoded tokens in installer"
  fi
fi

# ─── 7. SKILL.md content checks ─────────────

echo ""
echo "📝 SKILL.md content"

skill_file="skills/daily-standup/SKILL.md"

if grep -q "^---" "$skill_file"; then
  pass "Has YAML frontmatter"
else
  fail "Missing YAML frontmatter"
fi

if grep -q "Auto-update" "$skill_file"; then
  pass "Has auto-update section"
else
  warn "Missing auto-update section"
fi

if grep -q "Step 0" "$skill_file"; then
  pass "Has Step 0 (config)"
else
  fail "Missing Step 0"
fi

for step in "Step 1" "Step 2" "Step 3" "Step 4" "Step 5"; do
  if grep -q "$step" "$skill_file"; then
    pass "Has $step"
  else
    fail "Missing $step"
  fi
done

if grep -q "auth failures" "$skill_file"; then
  pass "Has auth failure handling"
else
  warn "Missing auth failure handling section"
fi

# Check no hardcoded tokens in SKILL.md
if grep -qiE "(ghp_|github_pat_[A-Za-z0-9]{10,}|ntn_[A-Za-z0-9]{10,})" "$skill_file"; then
  fail "SKILL.md contains what looks like a hardcoded token!"
else
  pass "No hardcoded tokens in SKILL.md"
fi

# ─── 8. No secrets in repo ──────────────────

echo ""
echo "🔒 Security"

if grep -rlE "(ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9]{20,}|ntn_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,})" --include="*.json" --include="*.md" --include="*.sh" . 2>/dev/null; then
  fail "Found potential secrets in repo files!"
else
  pass "No secrets detected in repo"
fi

# ─── Summary ─────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ✅ Passed: $PASS"
echo -e "  ❌ Failed: $FAIL"
echo -e "  ⚠️  Warnings: $WARN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "❌ Validation failed with $FAIL error(s)"
  exit 1
else
  echo "✅ All checks passed!"
  exit 0
fi
