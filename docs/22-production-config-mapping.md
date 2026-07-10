# Production Config Mapping

Date: 2026-07-10

## Purpose

This document maps the separated Compose deployment inputs to backend
`dujiao-next/config.yml`, frontend build variables, and post-boot admin
settings.

The backend can read environment variables through Viper, but the default
Compose deployment mounts a production `config.yml` at `/app/config.yml`.
Treat the Compose env file as deployment input, not as the only backend config
source.

## Files

Templates:

- `ops/compose/.env.production.example`
- `ops/compose/config.yml.production.example`
- `ops/gate1/site_config.json.example`
- `ops/gate1/user.env.production.example`
- `ops/gate1/admin.env.production.example`
- `docs/19-production-config-template.md`

Runtime mount:

- Compose variable `DUJIAO_CONFIG_PATH`
- Container path `/app/config.yml`

Rules:

- Copy example files outside git-tracked paths before adding real values.
- Keep real `config.yml` and real Compose env files in the deployment secret
  store or another protected location.

## Compose Env To Backend Config

These values must match between the Compose env file and `config.yml`:

| Compose env | Backend config field | Notes |
| --- | --- | --- |
| `POSTGRES_DB` | `database.dsn` `dbname` | Use the same database name. |
| `POSTGRES_USER` | `database.dsn` `user` | Use the same database user. |
| `POSTGRES_PASSWORD` | `database.dsn` `password` | Must match the Postgres service password. |
| `REDIS_PASSWORD` | `redis.password`, `queue.password` | Must match the Redis service password. |
| `DUJIAO_CONFIG_PATH` | mounted to `/app/config.yml` | Points Compose at the real backend config file. |
| `UPLOADS_PATH` | mounted to `/app/uploads` | Must persist user-uploaded files. |
| `LOGS_PATH` | mounted to `/app/logs` | Optional if logs are shipped elsewhere. |
| `FINAL_DOMAIN` | `cors.allowed_origins`, `site_config.brand.site_url` | No trailing slash in `site_url`. |
| `FINAL_ADMIN_DOMAIN` | `cors.allowed_origins` | Prefer separate admin domain. |
| `FINAL_API_DOMAIN` | payment callback URLs and frontend `VITE_API_BASE_URL` | Frontend value must not include `/api/v1`. |

Compose service hostnames inside `config.yml`:

- PostgreSQL host: `postgres`
- Redis host: `redis`
- Backend port inside container: `8080`

Example PostgreSQL DSN:

```yaml
database:
  driver: postgres
  dsn: "host=postgres port=5432 user=dujiao password=CHANGE_ME_POSTGRES_PASSWORD dbname=dujiao sslmode=disable TimeZone=UTC"
```

## Backend Required Production Values

Set these in the real `config.yml` before launch:

- `app.secret_key`: strong random value.
- `server.mode`: `release`.
- `server.read_header_timeout_seconds`: non-zero.
- `server.read_timeout_seconds`: non-zero.
- `server.write_timeout_seconds`: non-zero.
- `server.idle_timeout_seconds`: non-zero.
- `server.max_header_bytes`: non-zero.
- `database.driver`: `postgres`.
- `database.dsn`: points at Compose service `postgres`.
- `jwt.secret`: strong random value.
- `user_jwt.secret`: strong random value.
- `redis.host`: `redis`.
- `redis.password`: same as `REDIS_PASSWORD`.
- `queue.host`: `redis`.
- `queue.password`: same as `REDIS_PASSWORD`.
- `cors.allowed_origins`: final storefront and admin origins only.
- `cors.allowed_headers`: includes `X-Lang`.
- `telegram_auth.enabled`: `false` unless explicitly approved.

Keep `bootstrap.default_admin_password` empty after the first admin account is
created.

## Frontend Build Values

Set in the Compose env file before building frontend images:

```bash
VITE_API_BASE_URL=https://FINAL_API_DOMAIN
VITE_ADMIN_PATH=
```

Rules:

- `VITE_API_BASE_URL` is public.
- Do not include `/api/v1`; both frontends append it internally.
- Do not put secrets in any `VITE_*` variable.
- Use `VITE_ADMIN_PATH` only when admin is served under a path. Prefer a
  dedicated admin domain for the first launch.

## Post-Boot Admin Settings

These are not fully represented in `config.yml`; configure them in admin or
through the settings data store after the backend is running:

- `site_config.currency`: `USD`.
- `site_config.brand.site_url`: `https://FINAL_DOMAIN`.
- Brand name, favicon, logo, and OG image.
- Payment channels:
  - Alipay
  - WeChat Pay
  - PayPal
- Payment callback/return/webhook URLs:
  - `https://FINAL_API_DOMAIN/api/v1/payments/callback`
  - `https://FINAL_API_DOMAIN/api/v1/payments/webhook/paypal`
  - storefront return URLs under `https://FINAL_DOMAIN`
- Provider connections:
  - FansGurus
  - TGX Account
- Provider catalog sync schedule or admin manual sync policy.

Payment credentials and provider credentials must remain server-side.

## Validation

Run the prelaunch audit with the real generated files:

```bash
bash ops/prelaunch-audit.sh \
  --backend-config /secure/path/config.yml \
  --site-config /secure/path/site_config.json \
  --user-env /secure/path/user.env.production \
  --admin-env /secure/path/admin.env.production
```

Pass criteria:

- `FAIL` count is `0`.
- Warnings have explicit owner decisions.
- Public config returns `currency: "USD"` after deployment.

The example files under `ops/gate1/` intentionally contain `FINAL_*`
placeholders. They are structure templates only. Copy them outside git-tracked
paths and replace placeholders before using them as Gate 1 inputs.

If Docker is available, validate Compose rendering:

```bash
cd ops/compose
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  config
```

## Common Mistakes

- Editing `.env.production.example` directly with real secrets.
- Setting `VITE_API_BASE_URL=https://FINAL_API_DOMAIN/api/v1`.
- Updating `POSTGRES_PASSWORD` in Compose env but not in `database.dsn`.
- Updating `REDIS_PASSWORD` in Compose env but not in `redis.password` and
  `queue.password`.
- Leaving `server.mode: debug`.
- Leaving `cors.allowed_origins` as `*`.
- Forgetting `X-Lang` in CORS allowed headers.
- Setting `site_config.currency` in docs only, without updating production
  settings.
