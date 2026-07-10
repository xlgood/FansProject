#!/usr/bin/env bash

set -u

target_dir="${1:-deploy/production-local}"
failures=0

fail() {
  failures=$((failures + 1))
  printf 'FAIL %s\n' "$1"
}

pass() {
  printf 'PASS %s\n' "$1"
}

warn() {
  printf 'WARN %s\n' "$1"
}

require_file() {
  file="$1"
  if [ -f "$file" ]; then
    pass "$file exists"
  else
    fail "$file is missing"
  fi
}

printf 'Gate 1 local config check: %s\n\n' "$target_dir"

require_file "$target_dir/compose.env"
require_file "$target_dir/config.yml"
require_file "$target_dir/site_config.json"
require_file "$target_dir/user.env.production"
require_file "$target_dir/admin.env.production"

if [ "$failures" -gt 0 ]; then
  printf '\nSummary: %d failure(s). Run: bash ops/init-production-local.sh %s\n' "$failures" "$target_dir"
  exit 1
fi

if command -v jq >/dev/null 2>&1; then
  if jq . "$target_dir/site_config.json" >/dev/null; then
    pass "site_config.json is valid JSON"
  else
    fail "site_config.json is not valid JSON"
  fi
else
  warn "jq not found; skipped site_config JSON validation"
fi

placeholder_hits="$(grep -RInE 'CHANGE_ME' \
  "$target_dir/compose.env" \
  "$target_dir/config.yml" \
  "$target_dir/site_config.json" \
  "$target_dir/user.env.production" \
  "$target_dir/admin.env.production" 2>/dev/null || true)"
placeholder_hits="${placeholder_hits}
$(grep -RInE 'FINAL_[A-Z_]*|https://FINAL' \
  "$target_dir/config.yml" \
  "$target_dir/site_config.json" \
  "$target_dir/user.env.production" \
  "$target_dir/admin.env.production" 2>/dev/null || true)"
placeholder_hits="${placeholder_hits}
$(grep -nE '=(https://)?FINAL_[A-Z_]*|=FINAL_[A-Z_]*' "$target_dir/compose.env" 2>/dev/null | sed "s#^#$target_dir/compose.env:#" || true)"
placeholder_hits="$(printf '%s\n' "$placeholder_hits" | sed '/^[[:space:]]*$/d')"

if [ -n "$placeholder_hits" ]; then
  fail "placeholders remain in audit input files"
  printf '%s\n' "$placeholder_hits" | sed 's/^/  /'
else
  pass "no CHANGE_ME or FINAL_* placeholders remain in audit input files"
fi

printf '\nRunning prelaunch audit...\n'
bash ops/prelaunch-audit.sh \
  --backend-config "$target_dir/config.yml" \
  --site-config "$target_dir/site_config.json" \
  --user-env "$target_dir/user.env.production" \
  --admin-env "$target_dir/admin.env.production"
audit_status="$?"

if [ "$audit_status" -eq 0 ]; then
  pass "prelaunch audit exited 0"
else
  fail "prelaunch audit exited $audit_status"
fi

printf '\nNext steps:\n'
if [ -n "$placeholder_hits" ]; then
  printf '%s\n' '- Replace remaining placeholders using docs/28-secret-generation-guide.md.'
fi
printf '%s\n' '- When this script exits 0, continue to Gate 2 builds in docs/20-go-live-runbook.md.'

if [ "$failures" -gt 0 ]; then
  printf '\nSummary: %d failure(s).\n' "$failures"
  exit 1
fi

printf '\nSummary: 0 failure(s).\n'
