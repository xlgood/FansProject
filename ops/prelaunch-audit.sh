#!/usr/bin/env bash

set -u

backend_config="dujiao-next/config.yml"
site_config=""
user_env=""
admin_env=""
scan_public_text=1

usage() {
  cat <<'USAGE'
Usage:
  bash ops/prelaunch-audit.sh [options]

Options:
  --backend-config PATH   Production Dujiao-Next config.yml to inspect.
                          Default: dujiao-next/config.yml when present.
  --site-config PATH      Optional exported site_config JSON to inspect.
  --user-env PATH         Optional user frontend production env file.
  --admin-env PATH        Optional admin frontend production env file.
  --skip-public-text      Skip public frontend wording scan.
  -h, --help              Show this help.

Exit codes:
  0  No launch-blocking failures found.
  1  One or more launch-blocking failures found.

The script is read-only. It prints WARN for items that require manual review and
FAIL for configuration that should block launch.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --backend-config)
      backend_config="${2:-}"
      shift 2
      ;;
    --site-config)
      site_config="${2:-}"
      shift 2
      ;;
    --user-env)
      user_env="${2:-}"
      shift 2
      ;;
    --admin-env)
      admin_env="${2:-}"
      shift 2
      ;;
    --skip-public-text)
      scan_public_text=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "FAIL unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

failures=0
warnings=0

pass() {
  printf 'PASS %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf 'WARN %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'FAIL %s\n' "$1"
}

section_value() {
  file="$1"
  section="$2"
  key="$3"
  awk -v section="$section" -v key="$key" '
    $0 ~ "^[[:space:]]*" section ":[[:space:]]*($|#)" {
      in_section = 1
      next
    }
    in_section && $0 ~ /^[^[:space:]#][^:]*:/ {
      in_section = 0
    }
    in_section {
      line = $0
      sub(/[[:space:]]+#.*/, "", line)
      pattern = "^[[:space:]]+" key ":[[:space:]]*"
      if (line ~ pattern) {
        sub(pattern, "", line)
        gsub(/^[[:space:]"\047]+|[[:space:]"\047]+$/, "", line)
        print line
        exit
      }
    }
  ' "$file"
}

check_secret_placeholders() {
  file="$1"
  if grep -Eq 'your-secret-key-change-in-production-please|user-secret-key-change-in-production-please|Admin12345|your-password|your-username|change-in-production' "$file"; then
    fail "$file contains default placeholder secrets"
  else
    pass "$file has no known default secret placeholders"
  fi
}

check_backend_config() {
  file="$1"
  if [ ! -f "$file" ]; then
    warn "backend config not found: $file"
    return
  fi

  check_secret_placeholders "$file"

  mode="$(section_value "$file" server mode)"
  if [ "$mode" = "release" ]; then
    pass "server.mode is release"
  else
    fail "server.mode should be release, got '${mode:-missing}'"
  fi

  for key in read_header_timeout_seconds read_timeout_seconds write_timeout_seconds idle_timeout_seconds max_header_bytes; do
    value="$(section_value "$file" server "$key")"
    case "$value" in
      ''|0)
        fail "server.$key should be non-zero"
        ;;
      *)
        pass "server.$key is set to $value"
        ;;
    esac
  done

  if grep -Eq '^[[:space:]]*-[[:space:]]*"?\*"?[[:space:]]*$' "$file"; then
    fail "CORS allowed_origins appears to contain wildcard '*'"
  else
    pass "no wildcard origin found in config lists"
  fi

  if grep -Eq '^[[:space:]]*-[[:space:]]*X-Lang[[:space:]]*$' "$file"; then
    pass "CORS allowed headers include X-Lang"
  else
    fail "CORS allowed headers should include X-Lang"
  fi

  if grep -Eq 'telegram_auth:[[:space:]]*$' "$file" && grep -A8 -E '^[[:space:]]*telegram_auth:' "$file" | grep -Eq '^[[:space:]]*enabled:[[:space:]]*true[[:space:]]*$'; then
    warn "telegram_auth.enabled is true; confirm this is intentional and Telegram SKUs remain excluded"
  else
    pass "telegram_auth is not enabled in backend config"
  fi
}

check_site_config() {
  file="$1"
  if [ -z "$file" ]; then
    warn "site_config JSON not provided; cannot verify currency, site_url, or public brand fields"
    return
  fi
  if [ ! -f "$file" ]; then
    fail "site_config file not found: $file"
    return
  fi

  if grep -Eq '"currency"[[:space:]]*:[[:space:]]*"USD"' "$file"; then
    pass "site_config currency is USD"
  else
    fail "site_config currency should be USD"
  fi

  if grep -Eq '"site_url"[[:space:]]*:[[:space:]]*"https://[^"]+[^/]"' "$file"; then
    pass "site_config brand.site_url looks like absolute HTTPS without trailing slash"
  else
    fail "site_config brand.site_url should be absolute HTTPS without trailing slash"
  fi

  if grep -Eiq 'fansgurus|tgx|upstream|procurement|provider api|api routing' "$file"; then
    fail "site_config appears to expose provider/API/procurement wording"
  else
    pass "site_config does not contain obvious provider/API/procurement wording"
  fi
}

check_frontend_env() {
  label="$1"
  file="$2"
  if [ -z "$file" ]; then
    warn "$label env file not provided; cannot verify VITE_API_BASE_URL"
    return
  fi
  if [ ! -f "$file" ]; then
    fail "$label env file not found: $file"
    return
  fi

  api_base="$(awk -F= '/^[[:space:]]*VITE_API_BASE_URL[[:space:]]*=/{print $2; exit}' "$file" | sed 's/^[[:space:]"'\'']*//; s/[[:space:]"'\'']*$//')"
  if [ -z "$api_base" ]; then
    fail "$label VITE_API_BASE_URL is missing"
  elif printf '%s' "$api_base" | grep -Eq '/api/v1/?$'; then
    fail "$label VITE_API_BASE_URL must not include /api/v1"
  elif printf '%s' "$api_base" | grep -Eq '^https://'; then
    pass "$label VITE_API_BASE_URL uses HTTPS origin"
  else
    fail "$label VITE_API_BASE_URL should be an HTTPS origin"
  fi

  if grep -Eiq 'app_key|api_key|secret|password|token|private_key' "$file"; then
    fail "$label env appears to contain secret-like values"
  else
    pass "$label env has no obvious secret-like variable names"
  fi
}

check_public_text() {
  if [ "$scan_public_text" -ne 1 ]; then
    return
  fi
  if [ ! -d "user/src/i18n" ]; then
    warn "user/src not found; cannot scan public frontend text"
    return
  fi

  matches="$(grep -RInE 'FansGurus|TGX|upstream|procurement|provider page|provider API|API routing' user/src/i18n --include='*.ts' --include='*.json' 2>/dev/null || true)"
  if [ -n "$matches" ]; then
    warn "public frontend contains terms that may expose internals; review these lines:"
    printf '%s\n' "$matches" | sed 's/^/  /'
  else
    pass "public frontend text scan found no obvious provider/API/procurement wording"
  fi
}

check_backend_config "$backend_config"
check_site_config "$site_config"
check_frontend_env "user" "$user_env"
check_frontend_env "admin" "$admin_env"
check_public_text

printf '\nSummary: %s failure(s), %s warning(s)\n' "$failures" "$warnings"

if [ "$failures" -gt 0 ]; then
  exit 1
fi

exit 0
