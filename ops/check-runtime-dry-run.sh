#!/usr/bin/env bash

set -u

target_dir="${1:-deploy/production-local}"
compose_file="${COMPOSE_FILE:-ops/compose/docker-compose.production.yml}"
compose_env="$target_dir/compose.env"
nginx_dir="${NGINX_DIR:-$target_dir/nginx}"
failures=0
warnings=0
tmp_files=""

cleanup() {
  for file in $tmp_files; do
    [ -n "$file" ] && [ -e "$file" ] && rm -f "$file"
  done
}
trap cleanup EXIT

fail() {
  failures=$((failures + 1))
  printf 'FAIL %s\n' "$1"
}

pass() {
  printf 'PASS %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
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

env_value() {
  key="$1"
  file="$2"
  grep -E "^${key}=" "$file" 2>/dev/null | tail -n 1 | sed "s/^${key}=//"
}

check_port_binding() {
  key="$1"
  value="$(env_value "$key" "$compose_env")"
  if [ -z "$value" ]; then
    fail "$key is missing from compose.env"
    return
  fi
  case "$value" in
    127.0.0.1:*|localhost:*)
      pass "$key binds to loopback"
      ;;
    *)
      fail "$key must bind to 127.0.0.1 or localhost"
      ;;
  esac
}

check_path_value() {
  key="$1"
  expected="$2"
  value="$(env_value "$key" "$compose_env")"
  if [ -z "$value" ]; then
    fail "$key is missing from compose.env"
    return
  fi
  case "$value" in
    "$expected"|"$expected"/*|/*)
      pass "$key uses an explicit deployment path"
      ;;
    ./*)
      warn "$key uses a relative path; production should use $expected or an approved absolute path"
      ;;
    *)
      warn "$key uses a non-standard path"
      ;;
  esac
}

printf 'Gate 2 runtime dry-run: %s\n\n' "$target_dir"

require_file "$compose_env"
require_file "$compose_file"
require_file "$target_dir/config.yml"
require_file "$nginx_dir/target-site.conf"
require_file "$nginx_dir/target-proxy-headers.conf"
require_file "dujiao-next/Dockerfile"
require_file "user/Dockerfile"
require_file "admin/Dockerfile"

if [ "$failures" -gt 0 ]; then
  printf '\nSummary: %d failure(s), %d warning(s).\n' "$failures" "$warnings"
  exit 1
fi

printf '\nChecking Compose env bindings and paths...\n'
check_port_binding API_HOST_PORT
check_port_binding USER_HOST_PORT
check_port_binding ADMIN_HOST_PORT
check_path_value DUJIAO_CONFIG_PATH /etc/target-site
check_path_value UPLOADS_PATH /var/lib/target-site
check_path_value LOGS_PATH /var/lib/target-site
check_path_value POSTGRES_DATA_PATH /var/lib/target-site
check_path_value REDIS_DATA_PATH /var/lib/target-site

for key in API_BUILD_CONTEXT USER_BUILD_CONTEXT ADMIN_BUILD_CONTEXT; do
  value="$(env_value "$key" "$compose_env")"
  if [ -d "$value" ]; then
    pass "$key build context exists"
  elif [ -n "$value" ]; then
    fail "$key build context does not exist: $value"
  else
    fail "$key is missing from compose.env"
  fi
done

if grep -nE 'CHANGE_ME|=(https://)?FINAL_[A-Z_]*|=FINAL_[A-Z_]*' "$compose_env" >/dev/null 2>&1 ||
  sed '/^[[:space:]]*#/d' "$nginx_dir/target-site.conf" "$nginx_dir/target-proxy-headers.conf" |
    grep -E 'CHANGE_ME|FINAL_[A-Z_]*|https://FINAL' >/dev/null 2>&1; then
  fail "Compose or Nginx runtime files still contain placeholders"
else
  pass "Compose and Nginx runtime files have no launch placeholders"
fi

public_host_pattern='target\.example\.com|(^|[^[:alnum:]-])([[:alnum:]-]+\.)+(example|test|invalid)(:[0-9]+)?([^[:alnum:]._-]|$)|https?://(localhost|127\.[0-9.]+|\[?::1\]?)(:[0-9]+)?([^[:alnum:]._-]|$)'
if grep -InE "$public_host_pattern" \
  "$compose_env" "$nginx_dir/target-site.conf" >/dev/null 2>&1; then
  fail "Compose or Nginx public config contains a reserved or local host"
else
  pass "Compose and Nginx public hosts are production-safe"
fi

printf '\nChecking Docker Compose render...\n'
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  compose_out="$(mktemp "${TMPDIR:-/tmp}/target-compose-config.XXXXXX")"
  compose_err="$(mktemp "${TMPDIR:-/tmp}/target-compose-config-err.XXXXXX")"
  tmp_files="$tmp_files $compose_out $compose_err"
  if docker compose --env-file "$compose_env" -f "$compose_file" config >"$compose_out" 2>"$compose_err"; then
    pass "docker compose config exits 0"
    if grep -q '\${' "$compose_out"; then
      fail "docker compose config output contains unresolved variables"
    else
      pass "docker compose config output has no unresolved variables"
    fi
  else
    fail "docker compose config failed"
    warn "rerun docker compose config manually on the target host for details"
  fi
else
  warn "docker compose plugin not found; skipped Compose render check"
fi

printf '\nChecking Nginx config shape...\n'
if grep -q 'include /etc/nginx/snippets/target-proxy-headers.conf;' "$nginx_dir/target-site.conf"; then
  pass "Nginx site config includes shared proxy headers"
else
  fail "Nginx site config does not include shared proxy headers"
fi

if grep -q 'server_name' "$nginx_dir/target-site.conf"; then
  pass "Nginx site config declares server_name"
else
  fail "Nginx site config has no server_name"
fi

for header in Content-Security-Policy Permissions-Policy X-Frame-Options; do
  if grep -q "add_header $header" "$nginx_dir/target-site.conf"; then
    pass "Nginx site config sets $header"
  else
    fail "Nginx site config must set $header"
  fi
done

if grep -q 'X-Frame-Options "DENY"' "$nginx_dir/target-site.conf"; then
  pass "Nginx site config denies framing for admin/API"
else
  fail "Nginx site config must deny framing for admin/API"
fi

for route in '/sitemap.xml' '/robots.txt'; do
  if grep -Fq "location = $route" "$nginx_dir/target-site.conf"; then
    pass "Nginx site config proxies $route to the API"
  else
    fail "Nginx site config must proxy $route to the API"
  fi
done

if grep -q 'proxy_set_header X-Country-Code' "$nginx_dir/target-proxy-headers.conf"; then
  pass "Nginx proxy headers pass country code for locale detection"
else
  fail "Nginx proxy headers do not pass country code"
fi

if command -v nginx >/dev/null 2>&1; then
  warn "nginx binary found; run nginx -t after installing these files into the host nginx config tree"
else
  warn "nginx binary not found; skipped nginx -t"
fi

printf '\nNext steps:\n'
printf '%s\n' '- Resolve every FAIL before build/up.'
printf '%s\n' '- On the target host, run docker compose config and nginx -t against installed production files.'
printf '%s\n' '- After this dry-run passes, continue to production build and payment-channel preparation.'

if [ "$failures" -gt 0 ]; then
  printf '\nSummary: %d failure(s), %d warning(s).\n' "$failures" "$warnings"
  exit 1
fi

printf '\nSummary: 0 failure(s), %d warning(s).\n' "$warnings"
