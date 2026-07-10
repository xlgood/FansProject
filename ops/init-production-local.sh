#!/usr/bin/env bash

set -eu

target_dir="${1:-deploy/production-local}"

copy_if_missing() {
  src="$1"
  dst="$2"
  if [ -e "$dst" ]; then
    printf 'SKIP %s already exists\n' "$dst"
    return
  fi
  cp "$src" "$dst"
  printf 'COPY %s\n' "$dst"
}

mkdir -p "$target_dir"

copy_if_missing "ops/compose/.env.production.example" "$target_dir/compose.env"
copy_if_missing "ops/compose/config.yml.production.example" "$target_dir/config.yml"
copy_if_missing "ops/gate1/site_config.json.example" "$target_dir/site_config.json"
copy_if_missing "ops/gate1/user.env.production.example" "$target_dir/user.env.production"
copy_if_missing "ops/gate1/admin.env.production.example" "$target_dir/admin.env.production"

readme="$target_dir/README.md"
if [ ! -e "$readme" ]; then
  cat > "$readme" <<'README'
# Local Production Config Draft

This directory is ignored by git. It is for drafting production or staging
configuration values locally.

Files:

- `compose.env`: Docker Compose env input.
- `config.yml`: backend production config.
- `site_config.json`: exported/importable site config for Gate 1 audit.
- `user.env.production`: user frontend build env.
- `admin.env.production`: admin frontend build env.

Do not commit real secrets. Replace every `CHANGE_ME` and `FINAL_*` placeholder
before running Gate 1.

Run the audit from the repository root:

```bash
bash ops/prelaunch-audit.sh \
  --backend-config deploy/production-local/config.yml \
  --site-config deploy/production-local/site_config.json \
  --user-env deploy/production-local/user.env.production \
  --admin-env deploy/production-local/admin.env.production
```
README
  printf 'COPY %s\n' "$readme"
else
  printf 'SKIP %s already exists\n' "$readme"
fi

printf '\nNext: edit files in %s and run Gate 1 audit.\n' "$target_dir"
