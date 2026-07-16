# Production Data Initialization

Date: 2026-07-10

## Purpose

Use this checklist for the first production or staging data initialization. It
covers database startup, automatic migrations, bootstrap admin creation, site
settings, payment/provider readiness, first SKU sync, backups, and rollback
preconditions.

Do not run these steps against a live production database without a current
backup and a named operator.

## Inputs

Required before starting:

- Gate 1 config audit has `0` failures.
- Gate 2 runtime dry-run has `0` failures.
- Production `compose.env` and backend `config.yml` are installed outside git.
- PostgreSQL and Redis data directories are persistent.
- Final or staging domains are configured in backend config, frontend env, and
  reverse proxy config.
- Provider credentials and payment credentials are available to the operator,
  but not committed to git.
- `bootstrap.default_admin_username` and `bootstrap.default_admin_password` are
  set only for first boot, or `DJ_DEFAULT_ADMIN_USERNAME` /
  `DJ_DEFAULT_ADMIN_PASSWORD` are exported for the first API boot.

## Persistent Data Paths

For the separated Compose deployment, these paths must be persistent and backed
up:

| Data | Compose env | Container mount |
| --- | --- | --- |
| PostgreSQL | `POSTGRES_DATA_PATH` | `/var/lib/postgresql/data` |
| Redis | `REDIS_DATA_PATH` | `/data` |
| Uploads | `UPLOADS_PATH` | `/app/uploads` |
| Logs | `LOGS_PATH` | `/app/logs` |

Do not store persistent data inside git checkouts.

## First Boot Sequence

Run from `/srv/target-site/FansProject` or the approved deployment root.

1. Start database dependencies only:

```bash
cd ops/compose
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  up -d postgres redis
```

2. Confirm dependency health:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  ps postgres redis
```

3. Start API only. The backend startup performs database initialization,
   automatic migrations, and bootstrap admin creation:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  up -d api
```

4. Watch API logs until migration and health are stable:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  logs -f api
```

5. Confirm API health:

```bash
curl -i https://FINAL_API_DOMAIN/health
```

6. Start admin and user frontends:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  up -d admin user
```

7. Keep both side-effect workers stopped until their corresponding acceptance
   gates pass. The `fulfillment` profile submits and polls provider orders; the
   `inventory` profile performs provider inventory refreshes:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  --profile fulfillment --profile inventory \
  stop worker inventory-worker
```

## Bootstrap Admin

The backend creates the first admin only when no admin exists.

Rules:

- Use a unique strong temporary bootstrap password for the first boot.
- Log in immediately after first boot.
- Change the owner/admin password in admin settings.
- Enable 2FA for owner/admin accounts.
- Create named operator accounts and assign least-privilege roles.
- Remove `bootstrap.default_admin_password` from `config.yml`, or unset
  `DJ_DEFAULT_ADMIN_PASSWORD`, after the first admin exists.
- Restart API after clearing bootstrap credentials.

Useful emergency commands inside the API container:

```bash
./dujiao-api admin list-admins
./dujiao-api admin reset-2fa --username <name>
./dujiao-api admin reset-password --username <name>
```

Do not expose the admin domain publicly before the bootstrap password is changed
and 2FA is enabled.

## Post-Boot Site Settings

Configure these in admin after API health is stable:

| Area | Required value |
| --- | --- |
| Site currency | `USD` |
| Storefront domain | final `https://FINAL_DOMAIN` without trailing slash |
| API domain references | final `https://FINAL_API_DOMAIN` |
| Brand | final or approved temporary site name, favicon, logo, OG image |
| Public copy | no provider/API/procurement wording |
| Language | Simplified Chinese, Traditional Chinese, English enabled |
| Guest behavior | guests can browse only; order and order lookup require login |
| Telegram | Telegram auth and Telegram SKUs disabled |

Export or record the production `site_config` after editing, then re-run Gate 1
with the exported `site_config.json`.

## Payment Channel Initialization

Before enabling payment channels:

- complete `docs/30-payment-launch-workbook.md`;
- keep channels inactive while entering credentials;
- use `provider_type=official`;
- enable only Alipay, WeChat Pay, and PayPal for launch;
- set `payment_roles` to member only;
- set `payment_types` to order only unless wallet recharge is explicitly
  approved;
- verify callback/webhook URLs use the final API domain.

Do not start live provider fulfillment until at least one payment channel has
passed low-value acceptance.

## Provider Connection Initialization

Configure provider connections in admin:

| Provider | Required before sync |
| --- | --- |
| FansGurus | API key present server-side only |
| TGX Account | app ID and app key present server-side only |

Before first sync:

- confirm Telegram exclusion is enabled by policy;
- confirm independent provider allowlists are enabled;
- confirm FansGurus pricing uses the connection settings on the original quantity
  basis or retains approved manual SKU prices;
- confirm TGX pricing converts CNY to USD and uses the connection settings or
  retains approved manual SKU prices;
- keep `worker` stopped or fulfillment disabled while catalog is reviewed;
- keep `inventory-worker` stopped until provider inventory access is approved.

## First SKU Sync

Trigger the first sync from the admin connection management page, or through:

```text
POST /admin/provider-catalog/sync
```

Record the sync result:

| Metric | Expected |
| --- | --- |
| FansGurus pulled | greater than `0` |
| TGX pulled | greater than `0` |
| Supported platforms | union of active provider-allowed platforms |
| Filtered Telegram | reviewed and greater than or equal to `0` |
| Filtered provider-disallowed platforms | reviewed |
| Imported | greater than `0` for launch |
| Deactivated | reviewed, especially after repeat syncs |
| Sync status | `success` |

Catalog review pass criteria:

- no Telegram products or SKUs;
- no provider-disallowed platform appears publicly;
- FansGurus prices reflect its connection settings or approved manual prices;
- FansGurus minimums, maximums, and increments preserve the upstream quantity
  basis;
- TGX prices reflect CNY-to-USD conversion and its connection settings or approved manual prices;
- product titles and descriptions do not expose provider/internal wording;
- storefront browse works in `zh-CN`, `zh-TW`, and `en`;
- checkout requires login.

After catalog review passes, start `inventory-worker` when provider inventory
access is approved:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f ops/compose/docker-compose.production.yml \
  --profile inventory \
  up -d inventory-worker
```

Start `worker` only when payment acceptance and provider fulfillment acceptance
are ready:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f ops/compose/docker-compose.production.yml \
  --profile fulfillment \
  up -d worker
```

## Backup Before Live Traffic

Create a backup after migrations, admin setup, site settings, payment channel
drafts, and first catalog sync are complete.

PostgreSQL example:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f ops/compose/docker-compose.production.yml \
  exec postgres sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' \
  > /secure/backups/target-site-prelaunch.sql
```

Uploads example:

```bash
tar -C /var/lib/target-site -czf /secure/backups/target-site-uploads-prelaunch.tgz uploads
```

Backup acceptance:

- backup file exists outside git;
- backup file is readable only by operators;
- restore command has been dry-run on staging or a disposable database;
- backup timestamp and app version are recorded.

## Rollback And Restore Boundaries

Before public launch, record:

- `APP_VERSION`;
- backend image tag;
- user/admin frontend image tags;
- `compose.env` checksum or revision;
- `config.yml` checksum or revision;
- Nginx config checksum or revision;
- database backup path;
- uploads backup path.

Rules:

- Rolling back images is allowed when schema remains compatible.
- Do not roll back database schema blindly after migrations.
- If migrations changed data, prefer restoring the prelaunch database backup to
  manual reverse edits.
- Keep payment callback endpoints reachable for already-created payments.
- Stop `worker` before restoring data if provider fulfillment could create
  duplicate orders.

## Launch Blockers

Do not proceed to live traffic if any item is true:

- no verified database backup exists;
- bootstrap admin password remains in config or environment;
- owner/admin password was not changed after first boot;
- admin 2FA is not enabled;
- `worker` or `inventory-worker` is running before its acceptance gate;
- first SKU sync failed or imported zero launchable SKUs;
- Telegram or provider-disallowed SKUs appear publicly;
- payment channels allow guest payment;
- production config still references temporary domains;
- logs expose provider, payment, JWT, SMTP, or account delivery secrets.

## Evidence To Record

| Evidence | Owner | Status |
| --- | --- | --- |
| First boot completed and API health is `200` |  |  |
| Automatic migrations completed without errors |  |  |
| Bootstrap admin changed and 2FA enabled |  |  |
| Bootstrap password removed from config/env |  |  |
| Site settings exported and Gate 1 rerun |  |  |
| Payment channels configured but controlled |  |  |
| Provider connections configured server-side only |  |  |
| First provider catalog sync succeeded |  |  |
| Catalog review passed |  |  |
| Prelaunch database backup created and restore-tested |  |  |
| Worker start approved |  |  |
