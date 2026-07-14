# Launch Cutover Runbook

Date: 2026-07-10

## Purpose

Use this runbook for the final launch window. It turns the completed gates into
a timed cutover plan with DNS/CDN, TLS, Nginx, service sequencing, monitoring,
rollback, and post-launch controls.

Do not start launch cutover until every required gate in
`docs/20-go-live-runbook.md` has passed and the sign-off table in
`docs/25-launch-acceptance-checklist.md` is ready for final approval.

## Roles

Assign named owners before the launch window:

| Role | Owner | Contact | Backup |
| --- | --- | --- | --- |
| Launch commander |  |  |  |
| Backend/operator |  |  |  |
| Frontend/operator |  |  |  |
| DNS/CDN owner |  |  |  |
| Payment owner |  |  |  |
| Provider owner |  |  |  |
| Support/content owner |  |  |  |

Only the launch commander calls proceed, pause, rollback, or no-go.

## Required Green Gates

Cutover is blocked unless all items are true:

- Gate 1 config audit has `0` failures.
- Gate 2 runtime dry-run, tests, and builds pass.
- Production data initialization is complete.
- Prelaunch E2E acceptance is complete.
- Payment acceptance is complete for every enabled channel.
- Provider fulfillment acceptance is complete or explicitly deferred with
  provider submission disabled.
- Prelaunch database and uploads backups exist and restore was dry-run.
- Current and previous image tags are recorded.
- Payment channels can be disabled quickly.
- Provider fulfillment can be disabled quickly or `worker` can be stopped.
- Final domains, certificate paths, and Nginx config contain no placeholders.

## Cutover Inputs

Record final values before starting:

| Input | Value |
| --- | --- |
| `APP_VERSION` launching |  |
| Previous `APP_VERSION` |  |
| Storefront domain |  |
| Admin domain |  |
| API domain |  |
| DNS TTL before cutover |  |
| CDN zone/provider |  |
| TLS certificate path/status |  |
| Database backup path |  |
| Uploads backup path |  |
| Payment channels enabled at launch |  |
| Provider fulfillment enabled at launch |  |

## T-24h To T-2h Preparation

1. Lower DNS TTL for storefront, admin, and API records.
2. Confirm final DNS targets or CDN origins.
3. Confirm TLS certificate issuance or renewal.
4. Confirm CDN rules:
   - cache static assets only;
   - do not cache `/api/v1/*`;
   - do not cache payment callbacks or webhooks;
   - preserve `Host`;
   - pass callback/webhook bodies unchanged;
   - pass trusted country headers only from the CDN/proxy.
5. Confirm Nginx config paths and upstream ports.
6. Confirm production backups are present and readable.
7. Confirm rollback image tags and previous configs are available.
8. Confirm payment channels are disabled unless payment owner approves launch
   enablement.
9. Confirm provider fulfillment is disabled or `worker` is stopped unless
   provider owner approves launch enablement.
10. Freeze non-launch changes.

## T-60m Final Preflight

Run from `/srv/target-site/FansProject` or the approved deployment root:

```bash
git status --short --branch
bash ops/prelaunch-audit.sh \
  --backend-config /etc/target-site/config.yml \
  --site-config /etc/target-site/site_config.json \
  --user-env /etc/target-site/user.env.production \
  --admin-env /etc/target-site/admin.env.production
bash ops/check-runtime-dry-run.sh /etc/target-site
```

Validate Compose and Nginx:

```bash
cd ops/compose
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  config
nginx -t
```

No-go if any command fails.

## Service Start Sequence

Use this sequence for first public cutover:

1. Start PostgreSQL and Redis.
2. Start API and confirm health.
3. Start admin and user frontends.
4. Keep `worker` stopped until payment/provider launch decision.
5. Reload Nginx.
6. Run internal smoke through host or staging DNS.
7. Switch DNS/CDN to production host.
8. Run public smoke.
9. Enable payment channels approved for launch.
10. Enable `worker` or provider fulfillment only after payment smoke passes.

Commands:

```bash
cd /srv/target-site/FansProject/ops/compose
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  up -d postgres redis
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  up -d api
curl -i https://FINAL_API_DOMAIN/health
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  up -d user admin
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  stop worker
nginx -t
nginx -s reload
```

Start worker only when approved:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  up -d worker
```

## DNS/CDN Cutover

DNS/CDN owner executes:

1. Point storefront domain to the launch CDN/origin.
2. Point admin domain to the launch CDN/origin.
3. Point API domain to the launch CDN/origin.
4. Confirm HTTPS redirect behavior.
5. Confirm CDN cache bypass for API/payment/webhook paths.
6. Confirm country header behavior for first-visit locale.

Verification:

```bash
curl -I https://FINAL_DOMAIN/
curl -I https://FINAL_ADMIN_DOMAIN/
curl -i https://FINAL_API_DOMAIN/health
curl -i https://FINAL_API_DOMAIN/api/v1/public/config
```

## Public Smoke

Run immediately after DNS/CDN cutover:

```bash
curl -I https://FINAL_DOMAIN/
curl -I https://FINAL_DOMAIN/zh-CN
curl -I https://FINAL_DOMAIN/zh-TW/products
curl -I https://FINAL_DOMAIN/en/products
curl -i https://FINAL_DOMAIN/sitemap.xml
curl -i https://FINAL_DOMAIN/robots.txt
curl -i https://FINAL_API_DOMAIN/api/v1/public/config
```

Browser checks:

- storefront home loads;
- product list loads;
- product detail loads;
- checkout redirects logged-out users to login;
- admin login loads on admin domain;
- no Telegram SKU appears;
- public copy does not expose provider/internal wording.

## Payment And Provider Enablement

Enable payment channels one at a time:

1. Enable one approved payment channel.
2. Run a low-value checkout.
3. Confirm callback/webhook succeeds.
4. Confirm payment/order status.
5. Confirm logs have no secrets.
6. Leave enabled only if payment owner approves.

Enable provider fulfillment only after payment acceptance:

1. Confirm launch commander approval.
2. Start `worker`.
3. Run one low-value provider-backed order if approved.
4. Confirm no duplicate provider submission.
5. Confirm order status sync.
6. Stop `worker` again if provider launch is deferred.

## Monitoring Window

Monitor continuously for the first 2 hours, then at 24 hours:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f /srv/target-site/FansProject/ops/compose/docker-compose.production.yml \
  ps
docker compose \
  --env-file /etc/target-site/compose.env \
  -f /srv/target-site/FansProject/ops/compose/docker-compose.production.yml \
  logs --since 30m api worker
```

Watch:

- HTTP 5xx rate;
- admin login failures;
- customer auth failures;
- payment callback/webhook errors;
- provider submission failures;
- duplicate fulfillment attempts;
- accepted-order sync failures;
- unexpected Telegram/provider-disallowed catalog exposure;
- logs containing secrets or delivery data.

## Rollback Decision Matrix

| Symptom | First action | Rollback action |
| --- | --- | --- |
| Storefront down, API healthy | Roll back user image or CDN route | Restore previous user image/config |
| API health down | Keep CDN up but block checkout | Restore previous API image/config |
| Admin inaccessible | Keep public site read-only if needed | Restore previous admin image/config |
| Payment callback failing | Disable affected payment channel | Restore previous payment config after reconciliation |
| Duplicate provider submission risk | Stop `worker` | Disable provider connection and preserve logs |
| Wrong catalog exposed | Stop `worker`, disable affected products | Restore previous DB backup if edits/sync cannot be reversed |
| Secret exposed | Disable affected channel/provider | Rotate secret and restart API/worker |

Rollback rule:

- Prefer disabling payment/provider controls before restoring the database.
- Do not run destructive database restore while callbacks or fulfillment are in
  progress.
- Keep API callback/webhook endpoints reachable for already-created payments.
- Stop `worker` before any data restore.

## Rollback Commands

Stop fulfillment first:

```bash
cd /srv/target-site/FansProject/ops/compose
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  stop worker
```

Rollback images after restoring previous `APP_VERSION` in
`/etc/target-site/compose.env`:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  up -d api user admin
```

Rollback backend config after restoring previous `/etc/target-site/config.yml`:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  up -d api
```

Rollback Nginx after restoring previous config:

```bash
nginx -t
nginx -s reload
```

Database restore is a separate incident action. Use only when the launch
commander and operations owner approve restoring from the recorded backup.

## Go / No-Go Checklist

| Item | Status |
| --- | --- |
| Final domains point to intended target |  |
| TLS valid for all domains |  |
| Nginx reload succeeded |  |
| API health is `200` |  |
| Storefront and admin load |  |
| Public config returns final brand and `USD` |  |
| Guest checkout/order lookup blocked |  |
| Payment channel enablement approved |  |
| Provider fulfillment enablement approved or deferred |  |
| Logs reviewed for first 30 minutes |  |
| Rollback controls tested or confirmed |  |

## Post-Launch

Within 24 hours:

1. Restore DNS TTL to the normal value.
2. Review payment and provider logs.
3. Review customer support messages.
4. Confirm backups are scheduled.
5. Confirm no placeholder domains remain in public pages.
6. Confirm no Telegram or provider-disallowed SKUs appear in sitemap/catalog.
7. Record final launch approval and any deferred risks.
8. Re-run Gate 1 after any domain, config, payment, or provider change.
