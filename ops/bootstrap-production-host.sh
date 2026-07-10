#!/usr/bin/env bash

set -eu

base_dir="${BASE_DIR:-/srv/target-site}"
config_dir="${CONFIG_DIR:-/etc/target-site}"
data_dir="${DATA_DIR:-/var/lib/target-site}"

fans_repo="${FANSPROJECT_REPO:-git@github.com:xlgood/FansProject.git}"
api_repo="${DUJIAO_REPO:-git@github.com:xlgood/target-dujiao-next.git}"
user_repo="${USER_REPO:-git@github.com:xlgood/target-user.git}"
admin_repo="${ADMIN_REPO:-git@github.com:xlgood/target-admin.git}"

check_cmd() {
  name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf 'PASS command found: %s\n' "$name"
  else
    printf 'WARN command missing: %s\n' "$name"
  fi
}

clone_or_update() {
  repo="$1"
  dir="$2"
  if [ -d "$dir/.git" ]; then
    printf 'UPDATE %s\n' "$dir"
    git -C "$dir" pull --ff-only origin main
    return
  fi
  if [ -e "$dir" ]; then
    printf 'SKIP %s exists but is not a git checkout\n' "$dir"
    return
  fi
  printf 'CLONE %s -> %s\n' "$repo" "$dir"
  git clone "$repo" "$dir"
}

copy_if_missing() {
  src="$1"
  dst="$2"
  mode="$3"
  if [ -e "$dst" ]; then
    printf 'SKIP %s already exists\n' "$dst"
    return
  fi
  install -m "$mode" "$src" "$dst"
  printf 'COPY %s\n' "$dst"
}

printf 'Production host bootstrap\n'
printf 'BASE_DIR=%s\n' "$base_dir"
printf 'CONFIG_DIR=%s\n' "$config_dir"
printf 'DATA_DIR=%s\n\n' "$data_dir"

check_cmd git
check_cmd docker
check_cmd nginx
check_cmd curl
check_cmd jq
check_cmd openssl

if docker compose version >/dev/null 2>&1; then
  printf 'PASS docker compose plugin found\n'
else
  printf 'WARN docker compose plugin missing or not usable\n'
fi

printf '\nCreating directories...\n'
mkdir -p \
  "$base_dir" \
  "$config_dir/nginx" \
  "$data_dir/postgres" \
  "$data_dir/redis" \
  "$data_dir/uploads" \
  "$data_dir/logs"

printf '\nCloning or updating repositories...\n'
clone_or_update "$fans_repo" "$base_dir/FansProject"
clone_or_update "$api_repo" "$base_dir/dujiao-next"
clone_or_update "$user_repo" "$base_dir/user"
clone_or_update "$admin_repo" "$base_dir/admin"

printf '\nInstalling config templates when missing...\n'
copy_if_missing "$base_dir/FansProject/ops/compose/.env.production.example" "$config_dir/compose.env" 600
copy_if_missing "$base_dir/FansProject/ops/compose/config.yml.production.example" "$config_dir/config.yml" 600
copy_if_missing "$base_dir/FansProject/ops/gate1/site_config.json.example" "$config_dir/site_config.json" 600
copy_if_missing "$base_dir/FansProject/ops/gate1/user.env.production.example" "$config_dir/user.env.production" 600
copy_if_missing "$base_dir/FansProject/ops/gate1/admin.env.production.example" "$config_dir/admin.env.production" 600
copy_if_missing "$base_dir/FansProject/ops/nginx/target-site.conf.example" "$config_dir/nginx/target-site.conf" 644
copy_if_missing "$base_dir/FansProject/ops/nginx/target-proxy-headers.conf.example" "$config_dir/nginx/target-proxy-headers.conf" 644

printf '\nNext steps:\n'
printf '%s\n' "- Edit files under $config_dir; replace all CHANGE_ME and FINAL_* placeholders."
printf '%s\n' "- Set DUJIAO_CONFIG_PATH=$config_dir/config.yml in $config_dir/compose.env."
printf '%s\n' "- Set data paths in compose.env to $data_dir/postgres, $data_dir/redis, $data_dir/uploads, and $data_dir/logs."
printf '%s\n' "- Run Gate 1 audit from $base_dir/FansProject."
printf '%s\n' "- Run docker compose config before build/up."
