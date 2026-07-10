# Production Deployment Plan

Date: 2026-07-10

## Decision

Use separated production deployment as the default:

- `dujiao-next`: Go API and worker service.
- `user`: customer frontend built to static files and served by Nginx/CDN.
- `admin`: admin frontend built to static files and served by Nginx/CDN.
- PostgreSQL: persistent database.
- Redis: cache, queues, locks, and rate limits.
- Reverse proxy/CDN: TLS, security headers, public routing, and country header.

Fullstack embedded deployment is supported by the backend source but is not the
default launch path. Use it only when operations explicitly wants one binary and
accepts rebuilding the backend whenever either frontend changes.

## Why Separated Deployment

The current source already has production Dockerfiles for all three services:

- `dujiao-next/Dockerfile`
- `user/Dockerfile`
- `admin/Dockerfile`

The backend Dockerfile builds the Go API with `-tags release`. The user/admin
Dockerfiles build Vite assets and serve them from Nginx.

Separated deployment keeps:

- frontend assets cacheable and independently deployable;
- admin routing isolated from public storefront routing;
- API/worker scaling independent from static asset serving;
- the existing Dockerfiles usable without custom fullstack asset copying.

## Runtime Topology

Minimum production topology:

```text
Internet
  |
  v
CDN / reverse proxy / TLS
  |-- https://FINAL_DOMAIN          -> user static frontend
  |-- https://FINAL_ADMIN_DOMAIN    -> admin static frontend
  |-- https://FINAL_API_DOMAIN      -> dujiao-next API :8080
  |
  v
dujiao-next API/worker
  |-- PostgreSQL
  |-- Redis db 0: cache/rate limits
  |-- Redis db 1: queues
  |-- uploads volume or object storage-backed upload path
```

If frontend and API share one domain, keep `/api/v1/*`, payment callbacks, and
`/health` routed to the backend; all other public storefront routes go to user
static assets. Prefer a separate admin domain for the admin frontend.

## Required Persistent State

Backend containers must persist:

- PostgreSQL database.
- Redis data if queue durability is required by the selected Redis mode.
- `dujiao-next/uploads` or its production upload storage equivalent.
- `dujiao-next/logs` if logs are not shipped to a central collector.

Do not store production secrets inside image layers.

## Backend Build

Use the existing backend Dockerfile:

```bash
cd dujiao-next
docker build \
  --build-arg APP_VERSION=target-YYYYMMDD \
  -t target/dujiao-api:target-YYYYMMDD .
```

Run modes:

- API and worker together:
  - `./dujiao-api -mode all`
- API only:
  - `./dujiao-api -mode api`
- worker only:
  - `./dujiao-api -mode worker`

For a small first launch, `-mode all` is acceptable. For production operations,
prefer separate `api` and `worker` processes so worker saturation cannot affect
public request latency.

Backend production config must follow `docs/19-production-config-template.md`.

## User Frontend Build

The existing `user/Dockerfile` builds with:

```bash
pnpm run build
```

Production env requirement:

```bash
VITE_API_BASE_URL=https://FINAL_API_DOMAIN
```

Do not include `/api/v1`; the frontend app appends that prefix internally.

Build image:

```bash
cd user
docker build -t target/user-web:target-YYYYMMDD .
```

## Admin Frontend Build

The existing `admin/Dockerfile` builds with:

```bash
pnpm run build
```

Production env requirements:

```bash
VITE_API_BASE_URL=https://FINAL_API_DOMAIN
VITE_ADMIN_PATH=
```

If admin is served under a path instead of a dedicated domain, set
`VITE_ADMIN_PATH` to that path and verify route refreshes. Prefer a dedicated
admin domain for the first production launch.

Build image:

```bash
cd admin
docker build -t target/admin-web:target-YYYYMMDD .
```

## Reverse Proxy Routes

Recommended route split:

- `https://FINAL_DOMAIN/*`
  - user frontend static service
- `https://FINAL_ADMIN_DOMAIN/*`
  - admin frontend static service
- `https://FINAL_API_DOMAIN/health`
  - backend
- `https://FINAL_API_DOMAIN/api/v1/*`
  - backend
- `https://FINAL_API_DOMAIN/api/v1/payments/callback`
  - backend
- `https://FINAL_API_DOMAIN/api/v1/payments/webhook/paypal`
  - backend

Required proxy behavior:

- Redirect HTTP to HTTPS.
- Set security headers from `docs/18-production-security-compliance-checklist.md`.
- Preserve `Host`.
- Pass exactly one trusted country header for first-visit locale.
- Strip untrusted incoming `X-Forwarded-Host`.
- Keep request body limits aligned with backend upload limits.

## Health Checks

Backend:

```bash
curl -i https://FINAL_API_DOMAIN/health
```

User frontend:

```bash
curl -i https://FINAL_DOMAIN/health
```

Admin frontend:

```bash
curl -i https://FINAL_ADMIN_DOMAIN/health
```

The current frontend Nginx configs expose `/health` with `ok`.

## Fullstack Embedded Alternative

The backend source can embed both SPAs when built with `-tags fullstack`.

Source signals:

- `dujiao-next/internal/web/embed_fullstack.go`
- `dujiao-next/internal/router/router.go`
- `admin/package.json` has `build:fullstack`

High-level build shape:

```bash
cd user
VITE_API_BASE_URL= pnpm run build

cd ../admin
VITE_API_BASE_URL= VITE_FULLSTACK=1 pnpm run build

cd ../dujiao-next
mkdir -p internal/web/dist/user internal/web/dist/admin
cp -R ../user/dist/* internal/web/dist/user/
cp -R ../admin/dist/* internal/web/dist/admin/
go build -tags "release fullstack" -o dujiao-api ./cmd/server
```

Fullstack requirements:

- `web.admin_path` must not be `/admin` in production.
- API, user frontend, and admin frontend share the same backend process.
- Frontend changes require rebuilding the backend binary.
- The existing backend Dockerfile does not currently perform this asset-copying
  fullstack build.

Do not use fullstack for first production launch unless operations explicitly
chooses this packaging model.

## Deployment Gate

Before deploying any image to public production:

```bash
bash ops/prelaunch-audit.sh \
  --backend-config /path/to/production/config.yml \
  --site-config /path/to/site_config.json \
  --user-env /path/to/user.env.production \
  --admin-env /path/to/admin.env.production
```

Deployment is blocked unless the audit reports `0` failures.

After deployment, continue with `docs/20-go-live-runbook.md`.

## Compose Template

A minimal separated deployment Compose template is available at:

- `ops/compose/docker-compose.production.yml`
- `ops/compose/.env.production.example`

Use it as a structure reference, not as a complete secret-management solution.
Copy `.env.production.example` outside git-tracked paths before filling real
values.

Example:

```bash
cd ops/compose
cp .env.production.example /secure/path/target.env
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  build
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  up -d
```

Before running `up`, provide `/secure/path/config.yml` or update
`DUJIAO_CONFIG_PATH` to point at the production backend config generated from
`docs/19-production-config-template.md`.

Validate the rendered Compose file in an environment with Docker installed:

```bash
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  config
```
