#!/usr/bin/env bash

set -eu

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fixture_dir="$(mktemp -d "${TMPDIR:-/tmp}/prelaunch-audit-test.XXXXXX")"
trap 'rm -rf "$fixture_dir"' EXIT

cat >"$fixture_dir/config.yml" <<'YAML'
app:
  secret_key: strong-production-secret-value
server:
  mode: release
  read_header_timeout_seconds: 5
  read_timeout_seconds: 30
  write_timeout_seconds: 60
  idle_timeout_seconds: 120
  max_header_bytes: 1048576
cors:
  allowed_origins:
    - https://socialgurushub.com
  allowed_headers:
    - X-Lang
telegram_auth:
  enabled: false
YAML

cat >"$fixture_dir/site_config.json" <<'JSON'
{
  "currency": "USD",
  "brand": {"site_url": "https://socialgurushub.com"},
  "contact": {"email": "support@socialgurushub.com"},
  "legal": {
    "terms": {"zh-CN": "terms", "zh-TW": "terms", "en-US": "terms"},
    "privacy": {"zh-CN": "privacy", "zh-TW": "privacy", "en-US": "privacy"}
  }
}
JSON
printf '%s\n' 'VITE_API_BASE_URL=https://api.socialgurushub.com' >"$fixture_dir/user.env"
printf '%s\n' 'VITE_API_BASE_URL=https://api.socialgurushub.com' >"$fixture_dir/admin.env"

run_audit() {
  bash "$project_dir/ops/prelaunch-audit.sh" \
    --backend-config "$fixture_dir/config.yml" \
    --site-config "$fixture_dir/site_config.json" \
    --user-env "$fixture_dir/user.env" \
    --admin-env "$fixture_dir/admin.env" \
    --skip-public-text >/dev/null
}

run_audit

for invalid_host in target.example.com shop.example shop.test shop.invalid localhost 127.0.0.1; do
  printf 'VITE_API_BASE_URL=https://%s\n' "$invalid_host" >"$fixture_dir/user.env"
  if run_audit; then
    printf 'FAIL reserved host passed audit: %s\n' "$invalid_host"
    exit 1
  fi
done

printf '%s\n' 'PASS prelaunch audit rejects reserved and local public hosts'
