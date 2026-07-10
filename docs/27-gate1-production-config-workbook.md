# Gate 1 Production Config Workbook

Date: 2026-07-10

## Purpose

Use this workbook before running Gate 1 in `docs/20-go-live-runbook.md`.

This file is safe to commit because it contains no real secrets. Do not add
real production values here. Fill real values only in protected deployment
files copied from:

- `ops/compose/.env.production.example`
- `ops/compose/config.yml.production.example`
- `ops/gate1/site_config.json.example`
- `ops/gate1/user.env.production.example`
- `ops/gate1/admin.env.production.example`

## Gate 1 Output Files

Create these files outside git-tracked paths:

| File | Source template | Used by |
| --- | --- | --- |
| `/secure/target/compose.env` | `ops/compose/.env.production.example` | Docker Compose |
| `/secure/target/config.yml` | `ops/compose/config.yml.production.example` | Backend container |
| `/secure/target/site_config.json` | `ops/gate1/site_config.json.example` | Admin setting import/export and audit |
| `/secure/target/user.env.production` | `ops/gate1/user.env.production.example` | User frontend build |
| `/secure/target/admin.env.production` | `ops/gate1/admin.env.production.example` | Admin frontend build |

The exact `/secure/target` path can be changed by operations. The important
rule is that real secrets stay outside git.

## Required Decisions

Decide these before editing production files:

| Decision | Required value | Owner | Blocks |
| --- | --- | --- | --- |
| Storefront domain | `https://FINAL_DOMAIN` replacement | Product/ops | CORS, SEO, callbacks |
| Admin domain or path | `https://FINAL_ADMIN_DOMAIN` or admin path | Ops | CORS, admin access |
| API domain | `https://FINAL_API_DOMAIN` replacement | Ops | frontend env, payment callbacks |
| Public brand name | `FINAL_SITE_NAME` replacement | Product | site config, email, SEO |
| Support email | `FINAL_SUPPORT_EMAIL` replacement | Support/ops | site config, email sender |
| Deployment topology | separated Compose or approved alternative | Ops | build/run commands |
| Database | PostgreSQL DSN and credentials | Ops | backend startup |
| Redis | host/password/db plan | Ops | queue, rate limit, worker |
| Payment launch mode | sandbox or low-value production | Finance/ops | payment acceptance |
| Provider live test mode | low-value explicit approval only | Product/ops | provider acceptance |

## Secret Inventory

Generate strong unique values. Do not reuse local development credentials.

| Secret | Target file/setting | Notes |
| --- | --- | --- |
| `APP_SECRET_KEY` | `config.yml app.secret_key` | Strong random value. |
| `ADMIN_JWT_SECRET` | `config.yml jwt.secret` | Strong random value. |
| `USER_JWT_SECRET` | `config.yml user_jwt.secret` | Strong random value. |
| `POSTGRES_PASSWORD` | Compose env and `database.dsn` | Must match exactly. |
| `REDIS_PASSWORD` | Compose env, `redis.password`, `queue.password` | Must match exactly. |
| `SMTP_PASSWORD` | `config.yml email.password` | Server-side only. |
| FansGurus API key | Admin provider connection | Server-side only. |
| TGX app id/key | Admin provider connection | Server-side only. |
| Alipay credentials | Admin payment channel | Server-side only. |
| WeChat Pay credentials | Admin payment channel | Server-side only. |
| PayPal credentials | Admin payment channel | Server-side only. |

## File Fill Matrix

Use this matrix while editing copied production files.

| Placeholder or field | File | Required production value |
| --- | --- | --- |
| `FINAL_DOMAIN` | all copied files where present | Final storefront HTTPS host, no trailing slash in `site_url`. |
| `FINAL_ADMIN_DOMAIN` | Compose/backend/frontend env | Final admin HTTPS host. |
| `FINAL_API_DOMAIN` | frontend env, callbacks | Final API HTTPS host, no `/api/v1`. |
| `FINAL_SITE_NAME` | backend config, site config | Public brand name. |
| `FINAL_SUPPORT_EMAIL` | backend email, site config | Monitored support mailbox. |
| `CHANGE_ME_POSTGRES_PASSWORD` | Compose env, backend DSN | Same generated Postgres password. |
| `CHANGE_ME_REDIS_PASSWORD` | Compose env, backend Redis/queue | Same generated Redis password. |
| `CHANGE_ME_APP_SECRET` | backend config | Generated app secret. |
| `CHANGE_ME_ADMIN_JWT_SECRET` | backend config | Generated admin JWT secret. |
| `CHANGE_ME_USER_JWT_SECRET` | backend config | Generated user JWT secret. |
| `VITE_API_BASE_URL` | user/admin env | `https://FINAL_API_DOMAIN`, no `/api/v1`. |
| `currency` | `site_config.json` | `USD`. |
| `server.mode` | backend config | `release`. |
| `telegram_auth.enabled` | backend config | `false` unless explicitly approved. |
| `cors.allowed_origins` | backend config | Storefront and admin origins only. |
| `cors.allowed_headers` | backend config | Must include `X-Lang`. |
| `bootstrap.default_admin_password` | backend config | Empty after first admin exists. |

## Admin Post-Boot Checklist

After backend and admin are reachable, configure these from the admin panel or
settings import workflow:

| Area | Required action |
| --- | --- |
| Site config | Import or update `site_config`, then export it for Gate 1 audit. |
| Brand assets | Upload favicon, logo, and OG image under final paths. |
| Legal pages | Publish terms, privacy, refund/digital delivery, and contact pages. |
| Payment channels | Add only Alipay, WeChat Pay, and PayPal channels selected for launch. |
| Provider connections | Add FansGurus and TGX credentials; keep disabled until acceptance tests. |
| Admin account | Replace bootstrap password and enable 2FA for owner/admin accounts. |
| RBAC | Limit payment, provider, procurement, refund, and finance permissions. |

## Gate 1 Audit Command

Run after placeholders are replaced:

```bash
bash ops/prelaunch-audit.sh \
  --backend-config /secure/target/config.yml \
  --site-config /secure/target/site_config.json \
  --user-env /secure/target/user.env.production \
  --admin-env /secure/target/admin.env.production
```

Pass criteria:

- `Summary: 0 failure(s), ...`
- Any `WARN` has an explicit owner decision.
- No `CHANGE_ME` or `FINAL_*` remains in the audited files.
- Public wording scan has no storefront exposure of provider, upstream, API
  routing, or procurement wording.

## Pre-Build Checks

Before building production images:

```bash
jq . /secure/target/site_config.json
bash -n ops/prelaunch-audit.sh
bash ops/prelaunch-audit.sh \
  --backend-config /secure/target/config.yml \
  --site-config /secure/target/site_config.json \
  --user-env /secure/target/user.env.production \
  --admin-env /secure/target/admin.env.production
```

If Docker is available on the deployment host:

```bash
cd ops/compose
docker compose \
  --env-file /secure/target/compose.env \
  -f docker-compose.production.yml \
  config
```

Do not continue to Gate 2 while Gate 1 has any failure.

## Handoff Record

Fill this table outside git or in the launch ticket:

| Item | Owner | Result | Evidence |
| --- | --- | --- | --- |
| Production files copied outside git |  |  |  |
| All placeholders replaced |  |  |  |
| Secret inventory generated and stored |  |  |  |
| Gate 1 audit exits `0` |  |  |  |
| Warnings reviewed |  |  |  |
| Compose config renders |  |  |  |
| Ready for Gate 2 builds |  |  |  |
