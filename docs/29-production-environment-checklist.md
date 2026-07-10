# Production Environment Checklist

Date: 2026-07-10

## Purpose

Use this checklist to prepare a production or staging host after Gate 1 config
files are ready. It bridges the repository layout, Docker Compose template, and
reverse proxy template.

Do not put production secrets into git. Real config files should live in a
protected path on the deployment host.

## Remote Repositories

The deployment host needs these repositories:

| Repo | Purpose |
| --- | --- |
| `git@github.com:xlgood/FansProject.git` | Docs, ops templates, Compose, Nginx examples |
| `git@github.com:xlgood/target-dujiao-next.git` | Backend API and worker |
| `git@github.com:xlgood/target-user.git` | Customer storefront |
| `git@github.com:xlgood/target-admin.git` | Admin frontend |

HTTPS clone URLs are also valid when the host uses token-based access.

## Host Requirements

Minimum host tools:

- Git
- Docker Engine
- Docker Compose plugin
- Nginx or another reverse proxy
- TLS certificate automation or installed certificates
- `curl`
- `jq`
- `rg` or `grep`
- `openssl`

Recommended operational setup:

- non-root deploy user;
- firewall allowing only SSH, HTTP, and HTTPS from the internet;
- API/user/admin container ports bound to `127.0.0.1`;
- database and Redis not exposed publicly;
- persistent backup plan for PostgreSQL and uploads;
- centralized log collection or retained host logs.

## Suggested Directory Layout

Example host layout:

```text
/srv/target-site/
  FansProject/
  dujiao-next/
  user/
  admin/

/etc/target-site/
  compose.env
  config.yml
  site_config.json
  user.env.production
  admin.env.production
  nginx/
    target-site.conf
    target-proxy-headers.conf

/var/lib/target-site/
  postgres/
  redis/
  uploads/
  logs/
```

The exact paths can change, but keep secrets and data outside git checkouts.

## Clone Or Update Repositories

For first-time host setup, the bootstrap script can create directories,
clone/update the four repositories, and install template files when missing:

```bash
BASE_DIR=/srv/target-site \
CONFIG_DIR=/etc/target-site \
DATA_DIR=/var/lib/target-site \
bash ops/bootstrap-production-host.sh
```

The script does not overwrite existing config files and does not start
services. Review its output before continuing.

First-time clone:

```bash
mkdir -p /srv/target-site
cd /srv/target-site

git clone git@github.com:xlgood/FansProject.git
git clone git@github.com:xlgood/target-dujiao-next.git dujiao-next
git clone git@github.com:xlgood/target-user.git user
git clone git@github.com:xlgood/target-admin.git admin
```

Update existing checkouts:

```bash
cd /srv/target-site/FansProject && git pull --ff-only origin main
cd /srv/target-site/dujiao-next && git pull --ff-only origin main
cd /srv/target-site/user && git pull --ff-only origin main
cd /srv/target-site/admin && git pull --ff-only origin main
```

Do not run destructive git reset commands on production without an explicit
rollback decision.

## Install Production Config

Copy the Gate 1 files from the protected staging location to the deployment
host, for example:

```bash
mkdir -p /etc/target-site/nginx
install -m 600 deploy/production-local/compose.env /etc/target-site/compose.env
install -m 600 deploy/production-local/config.yml /etc/target-site/config.yml
install -m 600 deploy/production-local/site_config.json /etc/target-site/site_config.json
install -m 600 deploy/production-local/user.env.production /etc/target-site/user.env.production
install -m 600 deploy/production-local/admin.env.production /etc/target-site/admin.env.production
```

For real production, replace the local draft secrets with values generated on
the deployment host or from the production secret store.

Then edit `/etc/target-site/compose.env` so paths point at host locations:

```bash
DUJIAO_CONFIG_PATH=/etc/target-site/config.yml
UPLOADS_PATH=/var/lib/target-site/uploads
LOGS_PATH=/var/lib/target-site/logs
POSTGRES_DATA_PATH=/var/lib/target-site/postgres
REDIS_DATA_PATH=/var/lib/target-site/redis
```

Create data directories:

```bash
mkdir -p \
  /var/lib/target-site/postgres \
  /var/lib/target-site/redis \
  /var/lib/target-site/uploads \
  /var/lib/target-site/logs
```

## Gate 1 On Host

From `/srv/target-site/FansProject`:

```bash
bash ops/prelaunch-audit.sh \
  --backend-config /etc/target-site/config.yml \
  --site-config /etc/target-site/site_config.json \
  --user-env /etc/target-site/user.env.production \
  --admin-env /etc/target-site/admin.env.production
```

Do not build or start services until this reports `0` failures.

## Compose Validation

From `/srv/target-site/FansProject/ops/compose`:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  config
```

Pass criteria:

- no unresolved `${...}` variables;
- API/user/admin host ports bind to `127.0.0.1`;
- backend config mounts `/etc/target-site/config.yml`;
- persistent paths point at `/var/lib/target-site/...` or approved alternatives.

## Build And Start

Build:

```bash
cd /srv/target-site/FansProject/ops/compose
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  build
```

Start:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  up -d
```

Check containers:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  ps
```

## Reverse Proxy Setup

Copy Nginx templates:

```bash
cp /srv/target-site/FansProject/ops/nginx/target-site.conf.example \
  /etc/target-site/nginx/target-site.conf
cp /srv/target-site/FansProject/ops/nginx/target-proxy-headers.conf.example \
  /etc/target-site/nginx/target-proxy-headers.conf
```

Replace:

- `FINAL_DOMAIN`
- `FINAL_ADMIN_DOMAIN`
- `FINAL_API_DOMAIN`
- certificate paths
- upstream ports if different from `compose.env`

Validate and reload:

```bash
nginx -t
nginx -s reload
```

If using a CDN, configure it before public testing:

- preserve `Host`;
- do not cache `/api/v1/*`, callbacks, webhooks, or `index.html`;
- pass trusted country headers only from the CDN/proxy;
- do not inject scripts into storefront or admin pages.

## Initial Smoke

Before payment or provider testing:

```bash
curl -i https://FINAL_API_DOMAIN/health
curl -I https://FINAL_DOMAIN/
curl -I https://FINAL_ADMIN_DOMAIN/
curl -i https://FINAL_API_DOMAIN/api/v1/public/config
```

Expected:

- API health returns `200`;
- user/admin frontends return `200`;
- public config shows the final brand and `currency: "USD"`;
- no public response exposes provider credentials or internal wording.

## Blockers

Do not continue to payment or provider acceptance if any of these are true:

- Gate 1 has failures;
- Compose config has unresolved variables;
- API health is not `200`;
- CORS allows wildcard origins;
- final TLS is missing or invalid;
- admin is exposed under an unintended public route;
- database or Redis is reachable from the public internet;
- any real secret appears in git status, logs, or frontend bundle.
