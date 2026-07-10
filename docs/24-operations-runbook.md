# Operations Runbook

Date: 2026-07-10

## Purpose

This runbook covers day-to-day production operations for the separated
deployment:

- build and deploy;
- start, stop, restart;
- health checks and logs;
- Gate 1 audit;
- disabling payment or provider functionality;
- rollback and incident response.

It assumes the topology from `docs/21-production-deployment-plan.md`.
Use `docs/29-production-environment-checklist.md` for first-time host setup
before applying this day-to-day operations runbook.

## Paths And Inputs

Templates in this repository:

- `ops/compose/docker-compose.production.yml`
- `ops/compose/.env.production.example`
- `ops/compose/config.yml.production.example`
- `ops/gate1/site_config.json.example`
- `ops/gate1/user.env.production.example`
- `ops/gate1/admin.env.production.example`
- `ops/nginx/target-site.conf.example`
- `ops/nginx/target-proxy-headers.conf.example`

Production files must live outside git-tracked paths, for example:

- `/secure/path/target.env`
- `/secure/path/config.yml`
- `/secure/path/site_config.json`
- `/secure/path/user.env.production`
- `/secure/path/admin.env.production`
- `/secure/path/nginx/target-site.conf`
- `/secure/path/nginx/target-proxy-headers.conf`

Do not commit real production files.

## Gate 1 Audit

Run before every deployment, domain change, payment change, provider change, or
config change:

```bash
bash ops/prelaunch-audit.sh \
  --backend-config /secure/path/config.yml \
  --site-config /secure/path/site_config.json \
  --user-env /secure/path/user.env.production \
  --admin-env /secure/path/admin.env.production
```

Rules:

- `FAIL` must be `0`.
- Every `WARN` must have an owner decision.
- Do not build, deploy, or run live provider tests while Gate 1 has failures.

## Build

From the repository root:

```bash
cd ops/compose
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  build
```

Validate Compose rendering when Docker is available:

```bash
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  config
```

## Start

```bash
cd ops/compose
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  up -d
```

Expected services:

- `postgres`
- `redis`
- `api`
- `worker`
- `user`
- `admin`

## Stop

Stop app containers without deleting volumes:

```bash
cd ops/compose
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  stop api worker user admin
```

Stop all services without deleting volumes:

```bash
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  stop
```

Do not run `down -v` in production unless intentionally deleting persistent
data.

## Restart

Restart API and worker after backend config changes:

```bash
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  up -d api worker
```

Restart frontend services after image rebuild:

```bash
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  up -d user admin
```

Reload Nginx after proxy config changes:

```bash
nginx -t -c /secure/path/nginx/nginx.conf
nginx -s reload
```

## Health Checks

Container-level:

```bash
docker compose \
  --env-file /secure/path/target.env \
  -f ops/compose/docker-compose.production.yml \
  ps
```

Public checks:

```bash
curl -i https://FINAL_API_DOMAIN/health
curl -I https://FINAL_DOMAIN/
curl -I https://FINAL_ADMIN_DOMAIN/
curl -i https://FINAL_API_DOMAIN/api/v1/public/config
```

Pass criteria:

- API health returns `200`.
- Storefront and admin return `200`.
- Public config returns final brand fields and `currency: "USD"`.

## Logs

Follow API logs:

```bash
docker compose \
  --env-file /secure/path/target.env \
  -f ops/compose/docker-compose.production.yml \
  logs -f api
```

Follow worker logs:

```bash
docker compose \
  --env-file /secure/path/target.env \
  -f ops/compose/docker-compose.production.yml \
  logs -f worker
```

Recent payment/provider-relevant logs:

```bash
docker compose \
  --env-file /secure/path/target.env \
  -f ops/compose/docker-compose.production.yml \
  logs --since 30m api worker
```

Logs must not expose provider keys, payment credentials, JWT secrets, account
delivery secrets, or customer-sensitive form values.

## Manual Operational Actions

Use the admin UI for normal operations:

- manual provider catalog sync;
- procurement status sync;
- payment channel enable/disable;
- provider connection enable/disable;
- refund/reconciliation actions.

Prefer admin actions over direct database edits. Direct database edits require a
backup and explicit approval.

## Disable Payment

Use this when payment callbacks are failing, a merchant account is compromised,
or pricing/currency behavior is wrong.

Preferred action:

- In admin, disable the affected payment channel.

If admin is unavailable:

- Stop frontend checkout access at the reverse proxy or CDN.
- Keep API reachable for callbacks if payments are already in progress.
- Do not delete payment channel rows directly without a database backup.

After disabling:

- Verify the payment method is absent from checkout.
- Monitor pending payment callbacks.
- Document affected order IDs and channels.

## Disable Provider Fulfillment

Use this when live order submission is creating risk, provider credentials are
compromised, or a provider returns abnormal results.

Preferred action:

- In admin, disable the affected provider connection or stop live submission if
  that switch is available.
- Stop manual catalog sync if catalog data is suspect.

Emergency containment:

```bash
docker compose \
  --env-file /secure/path/target.env \
  -f ops/compose/docker-compose.production.yml \
  stop worker
```

Notes:

- Stopping `worker` pauses background fulfillment/status sync.
- API checkout may still accept orders unless payment channels or affected
  products are also disabled.
- Restart worker only after provider settings and credentials are verified.

## Rollback

Before every deployment, record:

- previous `APP_VERSION`;
- previous image tags;
- previous `/secure/path/target.env`;
- previous `/secure/path/config.yml`;
- previous Nginx config;
- database backup or restore point.

Rollback image version:

```bash
# Edit /secure/path/target.env and restore previous APP_VERSION first.
cd ops/compose
docker compose \
  --env-file /secure/path/target.env \
  -f docker-compose.production.yml \
  up -d api worker user admin
```

Rollback config:

```bash
# Restore previous /secure/path/config.yml first.
docker compose \
  --env-file /secure/path/target.env \
  -f ops/compose/docker-compose.production.yml \
  up -d api worker
```

Rollback proxy:

```bash
nginx -t -c /secure/path/nginx/nginx.conf
nginx -s reload
```

Do not roll back database schema blindly. If migrations ran, review migration
direction and restore strategy before changing binaries.

## Incident Priorities

Payment money risk:

1. Disable affected payment channel.
2. Keep callbacks reachable.
3. Preserve logs.
4. Reconcile payments and orders.

Provider duplicate-order risk:

1. Stop `worker`.
2. Disable affected provider connection or products.
3. Preserve procurement logs and order IDs.
4. Re-enable only after idempotency and status are verified.

Credential exposure:

1. Disable affected channel/provider.
2. Rotate credential.
3. Restart API/worker with updated config.
4. Review logs and access history.

Public site outage:

1. Check CDN/Nginx health.
2. Check `user` and `api` containers.
3. Roll back frontend image if the latest build caused the outage.
4. Keep admin/API access limited to operators during recovery if needed.

## Post-Change Checklist

After any production change:

- Run Gate 1 audit.
- Run public health checks.
- Confirm checkout sees only intended payment channels.
- Confirm Telegram SKUs remain absent.
- Confirm non-intersection platforms remain absent.
- Confirm logs have no secrets.
- Record the change, operator, timestamp, and rollback path.
