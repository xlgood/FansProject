# Go-Live Runbook

Date: 2026-07-10

## Purpose

This is the final launch sequence for the target site. It turns the production
checklists into a fixed gate order.

Launch is blocked if any required gate reports `FAIL`.

## Inputs

Prepare these production-only files or exported values before running the
gates:

- Backend production config:
  - `dujiao-next/config.yml`
  - or another production config path passed to the audit script
- Exported `site_config` JSON from production settings.
- User frontend production env file.
- Admin frontend production env file.
- Final storefront, admin, and API domains.
- Production or explicitly selected sandbox payment credentials.
- Production provider credentials.
- Deployment topology and image/process plan from
  `docs/21-production-deployment-plan.md`.
- Production config mapping from `docs/22-production-config-mapping.md`.
- Reverse proxy/CDN plan from `docs/23-reverse-proxy-cdn.md`.
- Operations runbook from `docs/24-operations-runbook.md`.
- Final acceptance checklist from `docs/25-launch-acceptance-checklist.md`.
- Gate 1 production config workbook from
  `docs/27-gate1-production-config-workbook.md`.

Input templates:

- `ops/compose/config.yml.production.example`
- `ops/gate1/site_config.json.example`
- `ops/gate1/user.env.production.example`
- `ops/gate1/admin.env.production.example`

Copy these outside git-tracked paths and replace all placeholders before Gate 1.
Use `docs/27-gate1-production-config-workbook.md` to track owners, required
values, and validation evidence.

Do not commit these files when they contain real secrets.

## Gate 1: Configuration Audit

Run the read-only audit:

```bash
bash ops/prelaunch-audit.sh \
  --backend-config /path/to/production/config.yml \
  --site-config /path/to/site_config.json \
  --user-env /path/to/user.env.production \
  --admin-env /path/to/admin.env.production
```

Pass criteria:

- `FAIL` count is `0`.
- Every `WARN` has an explicit owner decision.
- `site_config.currency` is `USD`.
- `server.mode` is `release`.
- CORS has no wildcard origin and includes `X-Lang`.
- Frontend `VITE_API_BASE_URL` is an HTTPS origin and does not include
  `/api/v1`.
- Public wording does not expose provider, API routing, or procurement
  internals.

Do not continue to build, payment testing, or live provider testing while this
gate has any `FAIL`.

## Gate 2: Runtime Dry-Run, Automated Tests, And Builds

Build and runtime topology must follow `docs/21-production-deployment-plan.md`
unless operations explicitly approves a different deployment model.

Run runtime dry-run before build/up:

```bash
bash ops/check-runtime-dry-run.sh /path/to/production-config-dir
```

Pass criteria:

- no `FAIL` output;
- Compose render exits `0` when Docker Compose is available;
- API/user/admin host ports bind to loopback;
- Nginx draft files have no launch placeholders.

Run backend tests:

```bash
cd dujiao-next
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go test ./internal/router ./internal/http/handlers/public ./internal/http/handlers/admin ./internal/service ./internal/upstream
```

Run user frontend checks:

```bash
cd user
./node_modules/.bin/vue-tsc -b
./node_modules/.bin/vite build
```

Run admin frontend checks:

```bash
cd admin
./node_modules/.bin/vue-tsc -b
./node_modules/.bin/vite build
```

Pass criteria:

- All commands exit `0`.
- Build artifacts are produced from production env values.
- No frontend bundle contains provider, payment, SMTP, JWT, or admin secrets.

## Gate 3: Domain And Runtime Smoke

Run after deployment to the final domain:

```bash
curl -I https://FINAL_DOMAIN/
curl -I https://FINAL_DOMAIN/zh-CN
curl -I https://FINAL_DOMAIN/zh-TW/products
curl -I https://FINAL_DOMAIN/en/products
curl -i https://FINAL_API_DOMAIN/api/v1/public/config
curl -i https://FINAL_DOMAIN/sitemap.xml
curl -i https://FINAL_DOMAIN/robots.txt
```

Run CORS checks:

```bash
curl -i -X OPTIONS \
  -H "Origin: https://FINAL_DOMAIN" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: x-lang,authorization" \
  https://FINAL_API_DOMAIN/api/v1/public/config

curl -i -X OPTIONS \
  -H "Origin: https://UNTRUSTED_EXAMPLE_DOMAIN" \
  -H "Access-Control-Request-Method: GET" \
  https://FINAL_API_DOMAIN/api/v1/public/config
```

Pass criteria:

- Public pages return HTTP `200`.
- Public config returns final brand fields and `currency: "USD"`.
- Unknown CORS origins are not allowed.
- Sitemap, canonical links, and `hreflang` use the final HTTPS domain.
- Locale-prefixed pages render in the expected language.
- Favicon, logo, and OG image return HTTP `200`.

## Gate 4: Payment Verification

For each enabled payment channel:

- Alipay
- WeChat Pay
- PayPal

Run a sandbox or low-value production checkout.

Pass criteria:

- Customer can create a payment.
- Return/callback/webhook uses final HTTPS URLs.
- Signature verification succeeds where supported.
- Local payment status reaches success.
- Payment amount and currency match the channel configuration.
- No callback logs expose secrets.

If Alipay or WeChat Pay converts USD to CNY, verify the stored payment row uses
the actual gateway amount/currency and that callback matching still succeeds.

## Gate 5: Provider Fulfillment Verification

Only run live provider submission with explicit approval and low-value orders.

Pass criteria:

- Telegram SKUs are absent.
- Non-intersection platforms are absent.
- FansGurus pricing preserves upstream quantity basis and applies `rate * 5`.
- TGX pricing applies `price * 1.2`.
- Paid order creates procurement once.
- Provider completion updates the local order to delivered.
- TGX account secrets are visible only to the buyer and authorized admins.
- Public order pages do not expose provider or upstream wording.

## Gate 6: Launch Decision

Launch can proceed only when:

- Gate 1 has `0` failures.
- Gates 2 through 5 pass.
- `docs/18-production-security-compliance-checklist.md` launch blockers are
  closed.
- Operations confirms rollback controls:
  - disable payment channels;
  - disable provider connections or stop live order submission;
  - stop queue workers;
  - rotate provider/payment/JWT/SMTP secrets;
  - roll back frontend and backend versions.
  Operational procedures are documented in `docs/24-operations-runbook.md`.
- Final human acceptance is recorded in
  `docs/25-launch-acceptance-checklist.md`.

## Post-Launch

After launch:

- Rotate any staging or shared secret.
- Monitor payment callbacks, provider submission failures, accepted-order sync,
  auth failures, and rate-limit blocks.
- Review audit warnings after every config or domain change.
- Re-run Gate 1 before enabling any new payment channel, provider connection,
  or public domain.
