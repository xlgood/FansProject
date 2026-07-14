# Production Readiness Review

Date: 2026-07-11

## Brand Convention

- Public brand, logo, page titles, structured data, payment merchant display,
  and advertising: `Social Gurus Hub`.
- Storefront domain: `socialgurushub.com`.
- API and admin origins: `api.socialgurushub.com` and
  `admin.socialgurushub.com`.
- Technical identifiers, container/project prefixes, and local file names:
  lowercase `socialgurushub`.

## Executive Summary

The current codebase is ready to enter VPS deployment and staging acceptance.
It is not yet ready for an immediate public transaction launch because the
checked local deployment draft still uses reserved example domains, production
site/legal content has not been initialized, and payment/provider/backup
acceptance requires a running production-like environment and real external
credentials.

Recommended decision: **proceed with VPS deployment preparation, but keep all
payment channels inactive and keep the worker stopped until every P0 gate below
has passed.**

This review distinguishes active behavior from inherited code. Guest order
handlers and models still exist, but every `/guest/*` route is guarded by a
middleware that always returns `401`; guests can browse but cannot create, pay,
or query orders. That inherited code is technical debt, not an active launch
vulnerability.

## Verified Baseline

- All five repositories inspected were clean and synchronized with their
  tracked `origin/main` branches at review time.
- `bash ops/prelaunch-audit.sh ...` against the local production draft reported
  `0` failures and `0` warnings.
- `bash ops/check-runtime-dry-run.sh deploy/production-local` reported `0`
  failures and seven expected local-host warnings: five relative data paths,
  Docker Compose unavailable locally, and Nginx unavailable locally.
- Backend `go test ./...` passed after allowing its `httptest` cases to bind
  loopback ports.
- Storefront `npm test` passed all 28 tests; storefront and admin production
  builds passed.
- The deployment serves static production bundles through Nginx rather than a
  Vite development server (`user/Dockerfile:17`, `admin/Dockerfile:19`).
- API, storefront, and admin container ports are designed to bind only to
  loopback (`ops/compose/.env.production.example:35`).

## P0: Launch Blockers

### P0-1 Replace all example domains with the actual domains

Evidence: the checked deployment draft still uses `target.example.com` for the
storefront, admin, API, support address, CORS, TLS paths, and SEO canonical base
(`deploy/production-local/compose.env:10`,
`deploy/production-local/site_config.json:5`).

Impact: certificates, CORS, callbacks, canonical URLs, sitemap URLs, and browser
API requests will be wrong if this draft is deployed unchanged.

Required action:

1. Choose three final origins: storefront, admin, and API.
2. Replace them consistently in Compose env, backend config, frontend build
   env, site config, Nginx, payment return URLs, and payment webhooks.
3. Issue TLS certificates and run public HTTPS/CORS checks.

### P0-2 Harden the prelaunch audit against reserved example domains

Evidence: placeholder checks reject `CHANGE_ME` and `FINAL_*`, but accept any
syntactically valid HTTPS URL (`ops/prelaunch-audit.sh:178`,
`ops/prelaunch-audit.sh:190`). Therefore the current example-domain draft
passes Gate 1.

Impact: Gate 1 can produce a false green result even though the deployment
cannot be launched on the intended domain.

Required fix: fail on `.example`, `.test`, `.invalid`, localhost, and known
project sample hosts in backend config, site config, frontend env, Compose env,
and Nginx runtime files. Add shell-level regression fixtures for valid and
invalid production inputs.

### P0-3 Initialize production data and lock down the first admin

Evidence: the repository provides the process, but completion can only be
verified after first boot. Required controls include changing the bootstrap
password, enabling admin 2FA, exporting the actual site configuration, and
reviewing the first catalog sync (`docs/31-production-data-initialization.md:135`,
`docs/31-production-data-initialization.md:153`).

Required action: boot PostgreSQL/Redis/API first, run migrations, create the
owner account, change credentials, enable 2FA, remove bootstrap credentials,
then expose the admin domain.

### P0-4 Complete payment acceptance for every enabled channel

Evidence: code and configuration templates cannot prove live callback
registration, signature verification, merchant-account currency handling, or
settlement reconciliation. The launch runbook explicitly blocks cutover until
each enabled channel passes acceptance (`docs/33-launch-cutover-runbook.md:39`).

Required action: keep channels inactive; test Alipay, WeChat Pay, and PayPal one
at a time with a logged-in low-value order. Confirm member-only/order-only
roles, signature verification, callback/webhook delivery, amount and currency,
idempotency, and secret-redacted logs.

### P0-5 Complete real provider sync and fulfillment acceptance

Evidence: unit/integration tests pass, but real FansGurus/TGX availability,
credentials, pricing, inventory, delivery, and status behavior are external.
The required first-sync review is defined at
`docs/31-production-data-initialization.md:190`.

Required action: keep `worker` stopped; sync the catalog, verify the platform
provider allowlists and Telegram exclusion, inspect both pricing configurations, then execute
one controlled low-value fulfillment per provider. Start the worker only after
payment acceptance and duplicate-submission checks pass.

### P0-6 Establish and restore-test backups

Evidence: Compose persists database, Redis, uploads, and logs, but the repo has
no scheduled backup service or job (`ops/compose/docker-compose.production.yml:1`).
The runbook requires a database/uploads backup and restore dry-run before live
traffic (`docs/31-production-data-initialization.md:233`).

Required action: configure automated encrypted off-host PostgreSQL and upload
backups, retention, failure alerting, and a restore test. Record the prelaunch
backup and current/previous image tags.

## P1: Complete Before or Immediately After Launch

### P1-1 Finalize legal, refund, support, and acceptable-use content

The local site config has no `legal` block, so the existing `/terms` and
`/privacy` routes will render empty content (`deploy/production-local/site_config.json:1`,
`user/src/composables/useLegal.ts:29`). Finalize all three locales and ensure
refund, digital delivery, platform non-affiliation, acceptable use, privacy,
and support contacts match actual operations. This should be treated as P0 if
payment is enabled at initial launch.

### P1-2 Add runtime monitoring and actionable alerts

Health checks and log rotation exist, but no monitoring/alerting stack is
declared in Compose. At minimum monitor external HTTP health, container
restarts, disk/database capacity, HTTP 5xx, payment callback failures, provider
submission/status failures, and backup failures. Avoid logging credentials or
delivered account secrets.

### P1-3 Add CI gates and dependency vulnerability scanning

Current workflows are release-oriented; no project CI gate runs backend tests,
both frontend builds, storefront tests, production audit, or vulnerability
scans on every change. Add `go test ./...`, `govulncheck`, frontend builds/tests,
lockfile audits, and secret scanning before production deployments.

### P1-4 Make admin tests a supported command

Five admin test files exist, but `admin/package.json:7` has no `test` script.
Add a deterministic test runner command and include it in CI. This removes the
need for operators to know an ad hoc invocation.

## P2: Non-Blocking Technical Debt

### P2-1 Remove dormant guest-order surfaces in a dedicated cleanup

The `/guest/*` route group is deliberately blocked by an unconditional `401`
middleware (`dujiao-next/internal/router/router.go:105`,
`dujiao-next/internal/router/middleware.go:31`). The old handlers, repository
queries, frontend API client, composables, password persistence, and related
tests remain. They are not reachable through the registered API routes, but
they make audits confusing and increase future regression risk.

Remove them only as a coordinated backend/frontend/schema migration after
confirming there is no historical guest-order data that must remain readable.
Until then, retain the route-level denial regression test.

### P2-2 Review browser token storage and custom-script policy

User/admin bearer tokens are inherited in `localStorage`
(`user/src/stores/userAuth.ts:9`, `admin/src/stores/auth.ts:85`). Also, site
configuration can execute administrator-supplied custom scripts
(`user/src/utils/customScripts.ts:48`). This makes any storefront/admin XSS or
compromised site-setting account more damaging.

For launch, keep custom scripts empty, keep the strict CSP, use short token
lifetimes, enable admin 2FA, and allow only trusted administrators to edit site
settings. A later auth redesign can move sessions to Secure, HttpOnly,
SameSite cookies with an explicit CSRF model.

### P2-3 Pin runtime container images more tightly

The backend runtime uses `alpine:latest` (`dujiao-next/Dockerfile:25`), while
frontend Nginx images use mutable minor tags. Pin reviewed versions or image
digests and document the update cadence for reproducible rollback builds.

## Go-Live Decision

Current state: **GO for VPS/staging deployment; NO-GO for public paid traffic
today.**

The code baseline is sufficiently mature to begin production-host preparation.
No unresolved code defect found in this review requires another feature cycle
before staging. Public transaction launch becomes GO only when:

1. Real domains/TLS/CORS/callback URLs replace every example value.
2. Gate 1 and Gate 2 pass on the VPS, including `docker compose config` and
   `nginx -t`.
3. Admin bootstrap, 2FA, legal content, production site config, and first SKU
   sync are complete.
4. Every enabled payment channel passes real acceptance.
5. Provider fulfillment passes acceptance or remains disabled with the worker
   stopped.
6. Database/uploads backup and restore testing are complete.
7. Production browser E2E and public smoke tests pass across desktop/mobile and
   all supported locales.

Follow `docs/29-production-environment-checklist.md`, then
`docs/31-production-data-initialization.md`, and finally
`docs/33-launch-cutover-runbook.md` in that order.
