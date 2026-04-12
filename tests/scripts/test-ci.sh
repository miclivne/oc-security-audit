#!/bin/sh
# CI Test Runner for oc-security-audit
# Runs discover.sh + scan.sh against the fixture project and asserts expected output.
# Designed for GitHub Actions — no color, exit non-zero on failure.
set -u

REPO_ROOT="$(cd "$(dirname "$(realpath "$0" 2>/dev/null || echo "$0")")/../.." && pwd)"
SKILL_DIR="$REPO_ROOT/plugins/oc-security-audit/skills/oc-security-audit"
FIXTURE_DIR="$REPO_ROOT/tests/fixtures/nextjs-prisma-app"

PASS=0; FAIL=0

check() {
  label="$1"; condition="$2"
  if eval "$condition"; then
    echo "  [PASS] $label"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $label"
    FAIL=$((FAIL+1))
  fi
}

echo "============================================"
echo "OC Security Audit — CI Test Runner"
echo "============================================"
echo ""
echo "Skill dir:   $SKILL_DIR"
echo "Fixture dir: $FIXTURE_DIR"
echo ""

# ---- Phase 0: Structure validation ----
echo "Phase 0: Structure validation"
check "SKILL.md exists" "[ -f '$SKILL_DIR/SKILL.md' ]"
check "SKILL.md has name field" "grep -q '^name:' '$SKILL_DIR/SKILL.md'"
check "SKILL.md has description field" "grep -q '^description:' '$SKILL_DIR/SKILL.md'"
check "SKILL.md has allowed-tools field" "grep -q '^allowed-tools:' '$SKILL_DIR/SKILL.md'"
check "SKILL.md under 500 lines" "[ \$(wc -l < '$SKILL_DIR/SKILL.md') -lt 500 ]"
check "No Write in allowed-tools" "! grep 'allowed-tools' '$SKILL_DIR/SKILL.md' | grep -q 'Write'"
check "marketplace.json exists" "[ -f '$REPO_ROOT/.claude-plugin/marketplace.json' ]"
check "marketplace.json is valid JSON" "python3 -c \"import json; json.load(open('$REPO_ROOT/.claude-plugin/marketplace.json'))\""
check "plugin.json exists" "[ -f '$SKILL_DIR/../../.claude-plugin/plugin.json' ]"
check "discover.sh exists and executable" "[ -x '$SKILL_DIR/scripts/discover.sh' ]"
check "scan.sh exists and executable" "[ -x '$SKILL_DIR/scripts/scan.sh' ]"
echo ""

# ---- Phase 1: POSIX syntax validation ----
echo "Phase 1: POSIX syntax validation"
check "discover.sh passes sh -n" "sh -n '$SKILL_DIR/scripts/discover.sh'"
check "scan.sh passes sh -n" "sh -n '$SKILL_DIR/scripts/scan.sh'"
check "test-harness.sh passes sh -n" "sh -n '$SKILL_DIR/scripts/test-harness.sh'"
check "patterns.sh passes sh -n" "sh -n '$SKILL_DIR/profiles/nextjs-prisma.patterns.sh'"
echo ""

# ---- Phase 2: discover.sh against fixture ----
echo "Phase 2: Running discover.sh against fixture..."
DISCOVERY=$(cd "$FIXTURE_DIR" && sh "$SKILL_DIR/scripts/discover.sh" 2>&1)
DISCOVER_EXIT=$?

echo ""
echo "--- discover.sh output (abbreviated) ---"
echo "$DISCOVERY" | grep -E '^(FRAMEWORK|ORM|PROFILE|AUTH|HOSTING|DOMAIN|ROUTE_COUNT|FILE_UPLOADS|AI_SDK|SRC_ROOT|PROJECT_ROOT|ROUTE:)'
echo "--- end ---"
echo ""

echo "Phase 2 checks: discover.sh"
check "discover.sh exits 0" "[ $DISCOVER_EXIT -eq 0 ]"
check "FRAMEWORK is Next.js" "echo \"\$DISCOVERY\" | grep '^FRAMEWORK:' | grep -qi 'next'"
check "ORM is Prisma" "echo \"\$DISCOVERY\" | grep '^ORM:' | grep -qi 'prisma'"
check "PROFILE is nextjs-prisma" "echo \"\$DISCOVERY\" | grep '^PROFILE:' | grep -q 'nextjs-prisma'"
check "AUTH detected" "echo \"\$DISCOVERY\" | grep '^AUTH:' | grep -qi 'better.auth'"
check "AI_SDK detected" "echo \"\$DISCOVERY\" | grep '^AI_SDK:' | grep -qi 'vercel\\|ai'"
check "FILE_UPLOADS is yes" "echo \"\$DISCOVERY\" | grep '^FILE_UPLOADS:' | grep -qi 'yes'"
check "ROUTE_COUNT >= 4" "echo \"\$DISCOVERY\" | grep -E '^ROUTE_COUNT: [4-9]'"
check "At least one route with auth=yes" "echo \"\$DISCOVERY\" | grep '^ROUTE:' | grep -q 'auth=yes'"
check "At least one route with auth=no" "echo \"\$DISCOVERY\" | grep '^ROUTE:' | grep -q 'auth=no'"
check "Health route found" "echo \"\$DISCOVERY\" | grep '^ROUTE:' | grep -q 'health'"
check "Users route found" "echo \"\$DISCOVERY\" | grep '^ROUTE:' | grep -q 'users'"
check "Upload route found" "echo \"\$DISCOVERY\" | grep '^ROUTE:' | grep -q 'upload'"
check "Chat route found" "echo \"\$DISCOVERY\" | grep '^ROUTE:' | grep -q 'chat'"

# Extract values for scan.sh — resolve relative paths against FIXTURE_DIR
PROFILE=$(echo "$DISCOVERY" | grep '^PROFILE:' | awk '{print $2}')
_src_root=$(echo "$DISCOVERY" | grep '^SRC_ROOT:' | awk '{print $2}')
_project_root=$(echo "$DISCOVERY" | grep '^PROJECT_ROOT:' | awk '{print $2}')
HOSTING=$(echo "$DISCOVERY" | grep '^HOSTING:' | awk '{print $2}')
FRAMEWORK=$(echo "$DISCOVERY" | grep '^FRAMEWORK:' | awk '{print $2}')
ORM=$(echo "$DISCOVERY" | grep '^ORM:' | awk '{print $2}')
FILE_UPLOADS=$(echo "$DISCOVERY" | grep '^FILE_UPLOADS:' | awk '{print $2}')
AI_SDK=$(echo "$DISCOVERY" | grep '^AI_SDK:' | awk '{print $2}')

# Resolve relative paths from discover.sh to absolute (discover ran in FIXTURE_DIR)
case "$_src_root" in
  /*) SRC_ROOT="$_src_root" ;;
  *)  SRC_ROOT="$FIXTURE_DIR/$_src_root" ;;
esac
case "$_project_root" in
  /*) PROJECT_ROOT="$_project_root" ;;
  *)  PROJECT_ROOT="$FIXTURE_DIR/$_project_root" ;;
esac
echo ""

# ---- Phase 3: scan.sh against fixture (offline mode) ----
echo "Phase 3: Running scan.sh against fixture (offline — no network)..."
SCAN_OUTPUT=$(OC_PROFILE="${PROFILE:-nextjs-prisma}" \
  OC_SRC_ROOT="${SRC_ROOT:-$FIXTURE_DIR/src}" \
  OC_PROJECT_ROOT="${PROJECT_ROOT:-$FIXTURE_DIR}" \
  OC_DOMAIN="" \
  OC_HOSTING="${HOSTING:-unknown}" \
  OC_FRAMEWORK="${FRAMEWORK:-nextjs}" \
  OC_ORM="${ORM:-prisma}" \
  OC_FILE_UPLOADS="${FILE_UPLOADS:-yes}" \
  OC_AI_SDK="${AI_SDK:-vercel-ai}" \
  sh "$SKILL_DIR/scripts/scan.sh" 2>&1)
SCAN_EXIT=$?

echo ""
echo "--- scan.sh TOTALS ---"
echo "$SCAN_OUTPUT" | grep '^TOTALS:'
echo "--- end ---"
echo ""

echo "Phase 3 checks: scan.sh"
check "scan.sh exits 0" "[ $SCAN_EXIT -eq 0 ]"
check "TOTALS line present" "echo \"\$SCAN_OUTPUT\" | grep -q '^TOTALS:'"

# Extract and verify totals
TOTALS_LINE=$(echo "$SCAN_OUTPUT" | grep '^TOTALS:')
if [ -n "$TOTALS_LINE" ]; then
  TOTAL_PASS=$(echo "$TOTALS_LINE" | grep -oE 'pass=[0-9]+' | cut -d= -f2)
  TOTAL_WARN=$(echo "$TOTALS_LINE" | grep -oE 'warn=[0-9]+' | cut -d= -f2)
  TOTAL_FAIL=$(echo "$TOTALS_LINE" | grep -oE 'fail=[0-9]+' | cut -d= -f2)
  TOTAL_SUM=$((TOTAL_PASS + TOTAL_WARN + TOTAL_FAIL))
  echo "  Totals: pass=$TOTAL_PASS warn=$TOTAL_WARN fail=$TOTAL_FAIL (sum=$TOTAL_SUM)"
  check "Total checks > 10" "[ $TOTAL_SUM -gt 10 ]"

  # Count actual rows and verify they match TOTALS
  ACTUAL_PASS=$(echo "$SCAN_OUTPUT" | grep -c '✅ PASS' || true)
  ACTUAL_WARN=$(echo "$SCAN_OUTPUT" | grep -c '⚠️  WARN' || true)
  ACTUAL_FAIL=$(echo "$SCAN_OUTPUT" | grep -c '❌ FAIL' || true)
  check "TOTALS pass matches actual rows" "[ \"$TOTAL_PASS\" = \"$ACTUAL_PASS\" ]"
  check "TOTALS warn matches actual rows" "[ \"$TOTAL_WARN\" = \"$ACTUAL_WARN\" ]"
  check "TOTALS fail matches actual rows" "[ \"$TOTAL_FAIL\" = \"$ACTUAL_FAIL\" ]"
fi

# WSTG sections present
echo ""
echo "Phase 3 checks: WSTG sections"
check "WSTG-CONF section present" "echo \"\$SCAN_OUTPUT\" | grep -q 'WSTG-CONF'"
check "WSTG-SESS section present" "echo \"\$SCAN_OUTPUT\" | grep -q 'WSTG-SESS'"
check "WSTG-ATHZ section present" "echo \"\$SCAN_OUTPUT\" | grep -q 'WSTG-ATHZ'"
check "WSTG-INPV section present" "echo \"\$SCAN_OUTPUT\" | grep -q 'WSTG-INPV'"
check "WSTG-DOS section present" "echo \"\$SCAN_OUTPUT\" | grep -q 'WSTG-DOS\\|DOS-0'"
check "Supply chain section present" "echo \"\$SCAN_OUTPUT\" | grep -q 'SUPPLY\\|Supply'"
check "Secrets section present" "echo \"\$SCAN_OUTPUT\" | grep -q 'CONF-09\\|Secret'"
check "Privacy section present" "echo \"\$SCAN_OUTPUT\" | grep -q 'PRIV-0'"
check "Logging section present" "echo \"\$SCAN_OUTPUT\" | grep -q 'LOGG-0\\|Logging'"
check "No NOT IMPLEMENTED rows" "! echo \"\$SCAN_OUTPUT\" | grep -q 'NOT IMPLEMENTED'"

# Fixture-specific assertions: known security properties
echo ""
echo "Phase 3 checks: fixture-specific assertions"
check "Rate limiting WARN present (fixture has none)" "echo \"\$SCAN_OUTPUT\" | grep -q 'rate.limit.*WARN\\|Rate.*limit.*WARN\\|DOS.*WARN' || echo \"\$SCAN_OUTPUT\" | grep 'DOS-01' | grep -q 'WARN'"
check "poweredByHeader PASS" "echo \"\$SCAN_OUTPUT\" | grep -q 'CONF-02.*PASS\\|poweredByHeader.*PASS'"
check "Lockfile PASS" "echo \"\$SCAN_OUTPUT\" | grep 'SUPPLY-02' | grep -q 'PASS'"

# ---- Phase 4: Profile-to-scan.sh completeness ----
echo ""
echo "Phase 4: Profile completeness"
PROFILE_PATH="$SKILL_DIR/profiles/nextjs-prisma.md"
SCAN_PATH="$SKILL_DIR/scripts/scan.sh"

PROFILE_RUN_IDS=$(grep -E 'RUN \(script\)|RUN \(escape-hatch\)|RUN \(conditional\)' "$PROFILE_PATH" \
  | sed -E 's/^\|([^|]+)\|.*/\1/' \
  | grep -oE '[A-Z]+-[A-Z0-9]+|[A-Z]+[0-9]+' \
  | grep -vE '^JUDGMENT' \
  | sort -u)

PROFILE_RUN_COUNT=$(echo "$PROFILE_RUN_IDS" | grep -c '.' || echo "0")
MISSING_IMPL=0

for ID in $PROFILE_RUN_IDS; do
  FUNC="check_$(echo "$ID" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
  if ! grep -q "^${FUNC}()" "$SCAN_PATH" 2>/dev/null; then
    echo "  [FAIL] MISSING: $ID — no $FUNC() in scan.sh"
    MISSING_IMPL=$((MISSING_IMPL+1))
    FAIL=$((FAIL+1))
  fi
done

if [ "$MISSING_IMPL" -eq 0 ]; then
  echo "  [PASS] All $PROFILE_RUN_COUNT RUN checks have implementations"
  PASS=$((PASS+1))
fi

# Verify no blank decisions in profile
BLANK_DECISIONS=$(grep -E '^\|[^|]+\|[^|]+\|[[:space:]]*\|' "$PROFILE_PATH" 2>/dev/null | grep -vE '^[-|[:space:]]+$' | grep -v 'Decision' || true)
if [ -n "$BLANK_DECISIONS" ]; then
  echo "  [FAIL] Profile has rows without a decision"
  FAIL=$((FAIL+1))
else
  check "All profile rows have a decision" "true"
fi

# ---- Summary ----
echo ""
echo "============================================"
TOTAL_CHECKS=$((PASS + FAIL))
echo "Results: $PASS passed, $FAIL failed ($TOTAL_CHECKS total)"

if [ $FAIL -eq 0 ]; then
  echo "All checks passed!"
  exit 0
else
  echo "$FAIL check(s) failed."
  exit 1
fi
