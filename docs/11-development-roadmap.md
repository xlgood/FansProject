# Development Roadmap

This roadmap is the execution order for formal development.

## Phase 1: Local Dujiao-Next Baseline

Status: baseline verified on 2026-07-08. Details are recorded in
`docs/12-local-baseline.md`.

Goal: run the unmodified Dujiao-Next source locally before provider integration.

Tasks:

- Map root `.env` values to Dujiao-Next backend, user frontend, and admin frontend config.
- Start backend from `dujiao-next/`.
- Start user frontend from `user/`.
- Start admin frontend from `admin/`.
- Verify database and Redis requirements.
- Verify login, product list, order creation path, and payment configuration pages where possible.

Success criteria:

- Backend health/API endpoint responds locally.
- User frontend loads locally.
- Admin frontend loads locally.
- Required runtime config gaps are documented.

## Phase 2: Source Fit Plan

Status: source fit plan completed on 2026-07-08. Details are recorded in
`docs/13-source-fit-plan.md`.

Goal: identify exact Dujiao-Next extension points before business changes.

Tasks:

- Inspect product, SKU, order, payment callback, fulfillment, upstream, and queue modules.
- Decide whether FansGurus/TGX adapters fit existing upstream/procurement abstractions.
- Produce a file-level implementation plan with required models, services, routes, workers, and admin screens.

Success criteria:

- Implementation plan names files/modules to change.
- Data model changes are explicit.
- Risky assumptions are called out before coding.

## Phase 3: Provider Clients

Status: completed on 2026-07-08.

Goal: add isolated provider clients with tests and no real orders.

Tasks:

- FansGurus client: `services`, `balance`, `add`, `status`.
- TGX client: signing, authentication, items, inventory, trade, query.
- Mock upstream responses for tests.
- Redact secrets in errors/logs.

Success criteria:

- Signing and request construction are tested.
- Price parsing uses decimal math.
- No real upstream purchase is made.

Verification:

- `dujiao-next/internal/upstream` now has isolated FansGurus and TGX clients.
- FansGurus tests cover `services`, `balance`, `add`, `status`, error redaction,
  and `rate * 5` while preserving the upstream per-1000 basis.
- TGX tests cover signing, authentication, items, inventory, inventory state,
  trade, query, widget form parameters, error redaction, and `price * 1.2`.
- Targeted test passed: `go test ./internal/upstream`.

## Phase 4: SKU Sync And Filtering

Status: catalog policy, database import, TGX race/widget handling, live sync orchestration, sync history, and stale deactivation completed on 2026-07-09; admin/worker entry points remain pending.

Goal: build the catalog pipeline.

Tasks:

- Store raw FansGurus and TGX catalog payloads.
- Normalize platforms.
- Exclude Telegram-related SKUs.
- Compute cross-provider platform intersection.
- Apply pricing:
  - FansGurus: upstream rate * 5, preserving the upstream per-1000 quantity basis.
  - TGX: `price` * 1.2.
- Map active SKUs into Dujiao-Next product/SKU structures.

Success criteria:

- Telegram SKUs are hidden.
- Non-intersection platforms are hidden.
- USD target prices are stored and reproducible.

Completed verification:

- Added a pure catalog policy layer for platform normalization, Telegram
  exclusion, active-only filtering, cross-provider platform intersection, and
  provider price helpers.
- Added base database import for filtered provider catalog items into
  Dujiao-Next categories, products, SKUs, product mappings, and SKU mappings.
- Extended mapping tables with provider/platform/string upstream code fields so
  TGX `shared_code` and future race SKU codes do not need to be forced into
  numeric IDs.
- Added TGX `config` race parsing into multiple SKU variants.
- Added TGX `widget` conversion into Dujiao manual form schema.
- Added provider catalog sync orchestration that pulls FansGurus/TGX catalog
  clients, builds the filtered intersection catalog, and imports by provider
  connection ID.
- Added provider catalog sync run history with raw upstream payload snapshots
  and summary counts.
- Added stale mapping deactivation for provider records that disappear or leave
  the filtered intersection.
- Added an admin manual trigger endpoint for provider catalog sync:
  `POST /admin/provider-catalog/sync`.
- Added RBAC coverage for the manual trigger under the `integration` role.
- Added an admin frontend manual sync button on the connection management page,
  including provider protocol selection options for `fansgurus` and
  `tgx-account`.
- Tests cover platform aliases, Telegram English and Chinese tokens, `tg`
  boundary matching, inactive upstream items, non-intersection filtering, and
  FansGurus/TGX price rules.
- Targeted tests passed:
  - `go test ./internal/upstream`
  - `go test ./internal/service -run 'Test(SyncProviderCatalog|ImportProviderCatalog)'`
  - `go test ./internal/http/handlers/admin -run 'TestSyncProviderCatalog'`
  - `go test ./internal/router`
  - `go test ./internal/repository -run 'TestSQLDialect|TestProduct'`
  - `cd admin && ./node_modules/.bin/vue-tsc -b`
  - `cd admin && ./node_modules/.bin/vite build`

Remaining implementation:

- Add worker/queue or scheduled sync if automatic refresh is required.

## Phase 5: Order Fulfillment

Status: provider procurement submit path started on 2026-07-09.

Goal: connect paid local orders to upstream fulfillment.

Tasks:

- Queue upstream fulfillment after local payment success.
- Submit FansGurus orders and poll status.
- Submit TGX trades and store delivered secrets.
- Add retry and idempotency.
- Expose fulfillment status to customer and admin.

Success criteria:

- Paid order is not lost on upstream failure.
- Retry does not duplicate upstream orders.
- TGX delivered secrets are access-controlled.

Completed verification:

- Existing paid-order hook already creates procurement orders for upstream
  fulfillment items.
- Added provider-specific procurement submit handling for `fansgurus` and
  `tgx-account` connections.
- FansGurus submit uses the mapped service ID, order quantity, and manual form
  `link`.
- TGX submit uses mapped `shared_code|race`, order quantity, order number as
  `request_no`, and manual form widget fields.
- TGX immediate secrets are stored as upstream fulfillment payloads.
- Added provider status polling for accepted procurement orders:
  - FansGurus `status`
  - TGX `query`
- Provider polling maps delivered/canceled/refunded states into the existing
  local procurement callback flow.
- TGX pending query results keep procurement orders in `accepted`.
- Hardened provider submit retry/idempotency behavior:
  - FansGurus temporary unavailable submit results stop in `failed` with a
    user-safe error code instead of auto-retrying and risking duplicate upstream
    orders.
  - TGX ambiguous submit results first query by `request_no`; recovered trades
    continue through the normal accepted/delivered flow.
  - TGX unresolved unavailable submits use the same user-safe failed state
    without `next_retry_at`.
  - Public order detail responses expose `fulfillment_error` for localized
    customer-facing messages.
- Added a customer-side retry path for temporary fulfillment submission
  failures:
  - logged-in and guest order detail APIs expose `fulfillment_retryable`;
  - logged-in and guest order details can trigger `fulfillment/retry`;
  - parent order details surface retryable child-order fulfillment failures;
  - classic and vault frontends show a localized `重新提交` / `Retry submission`
    action without exposing upstream/API/provider wording.
- Added an admin-side manual procurement status sync action:
  - backend exposes `POST /admin/procurement-orders/:id/sync-status`;
  - integration role can call the new endpoint;
  - admin procurement list/detail show `同步状态` / `Sync Status` for accepted
    procurement orders.
- Tightened provider procurement cancellation:
  - FansGurus/TGX submitted or accepted procurement orders no longer get marked
    locally canceled without a provider-side cancel capability;
  - admin cancel actions are limited to pending, failed, and rejected
    procurement orders.
- Improved admin procurement diagnostics:
  - procurement list/detail errors now show a diagnosis title, suggested
    operator action, and the original raw error message;
  - diagnostic labels cover mapping, form data, service codes, credentials,
    connection config, balance/quota, stock, unsupported cancellation, and
    unknown fallback cases in Simplified Chinese, Traditional Chinese, and
    English.
- Confirmed automatic periodic status sync/worker coverage:
  - worker startup registers `procurement:sync_accepted` every 30 minutes when
    `ProcurementOrderService` is available;
  - the worker task calls `SyncAcceptedOrders()` without admin interaction;
  - service coverage verifies accepted FansGurus procurement orders advance to
    fulfilled and the local order advances to delivered.
- Added local mock end-to-end provider fulfillment coverage:
  - a paid local order creates a pending procurement order through
    `CreateForOrder()`;
  - mocked FansGurus `add` accepts the order and moves the local order to
    fulfilling;
  - mocked FansGurus `status` completes the procurement order through
    `SyncAcceptedOrders()`;
  - the local order reaches delivered without calling any real upstream API.
- Added TGX local mock end-to-end account fulfillment coverage:
  - mocked TGX `/commodity/trade` accepts the account order and returns a
    pending trade number;
  - mocked TGX `/commodity/query` later returns completed status and account
    secret;
  - the procurement order reaches fulfilled, the local order reaches delivered,
    and the account secret is stored in fulfillment payload.
- Targeted tests passed:
  - `go test ./internal/service -run 'TestSubmitToUpstream_(FansGurusProvider|TGXProviderImmediateSecret|Success|NonRetryableError_Rejects|RetryableError_Retries)'`
  - `go test ./internal/service -run 'TestPollUpstreamStatus_(FansGurusCompleted|TGXQueryDeliveredSecret|TGXQueryPendingKeepsAccepted|Delivered|FulfilledMappedToDelivered)'`
  - `go test ./internal/service -run 'Test(SyncProviderCatalog|ImportProviderCatalog|CreateForOrder)'`
  - `go test ./internal/upstream`
  - `go test ./internal/service -run 'TestSubmitToUpstream_(FansGurusProvider|FansGurusUnavailableFailsForUserWithoutRetry|TGXProviderImmediateSecret|TGXProviderRecoversByRequestNo)'`
  - `go test ./internal/http/handlers/public ./internal/dto`
  - `go test ./internal/http/handlers/admin ./internal/router`
  - `go test ./internal/service -run 'TestPollUpstreamStatus_(FansGurusCompleted|TGXQueryDeliveredSecret|TGXQueryPendingKeepsAccepted|Delivered|FulfilledMappedToDelivered)'`
  - `go test ./internal/service -run 'TestCancelManual_(ProviderAcceptedUnsupported|FailedLocalOnlyCancels)'`
  - `go test ./internal/service -run 'TestSyncAcceptedOrders_FansGurusCompleted|TestPollUpstreamStatus_(FansGurusCompleted|TGXQueryDeliveredSecret|TGXQueryPendingKeepsAccepted|Delivered|FulfilledMappedToDelivered)'`
  - `go test ./internal/service -run 'TestProviderFulfillmentEndToEnd_FansGurusMock|TestSyncAcceptedOrders_FansGurusCompleted|TestSubmitToUpstream_FansGurusProvider|TestPollUpstreamStatus_FansGurusCompleted'`
  - `go test ./internal/service -run 'TestProviderFulfillmentEndToEnd_TGXMockDelayedSecret|TestSubmitToUpstream_TGXProviderImmediateSecret|TestPollUpstreamStatus_TGXQueryDeliveredSecret|TestPollUpstreamStatus_TGXQueryPendingKeepsAccepted'`
  - `go test ./internal/service -run 'Test(ProviderFulfillmentEndToEnd|CreateForOrder|SubmitToUpstream|PollUpstreamStatus|SyncAcceptedOrders|CancelManual)'`
  - `go test ./internal/worker`
  - `cd user && ./node_modules/.bin/vue-tsc -b`
  - `cd user && ./node_modules/.bin/vite build`
  - `cd admin && ./node_modules/.bin/vue-tsc -b`
  - `cd admin && ./node_modules/.bin/vite build`

Remaining implementation:

- No additional fulfillment-specific smoke item remains in this phase.

## Phase 6: Frontend And Admin

Status: frontend/admin smoke verification and browser runtime smoke completed
on 2026-07-10. Details are recorded in `docs/14-frontend-admin-smoke.md` and
`docs/15-browser-runtime-smoke.md`.

Goal: make the integrated catalog usable.

Tasks:

- User frontend platform navigation from intersection platforms.
- Product detail forms from normalized provider schemas.
- Admin sync dashboard.
- Admin SKU mapping and disable controls.
- Admin upstream error and retry tools.

Success criteria:

- Customers cannot buy hidden or unsupported SKUs.
- Admin can diagnose sync and fulfillment failures.

Completed verification:

- User frontend typecheck passed:
  - `cd user && ./node_modules/.bin/vue-tsc -b`
- User frontend production build passed:
  - `cd user && ./node_modules/.bin/vite build`
- Admin frontend typecheck passed:
  - `cd admin && ./node_modules/.bin/vue-tsc -b`
- Admin frontend production build passed:
  - `cd admin && ./node_modules/.bin/vite build`
- Browser runtime smoke passed after adding backend CORS support for the
  frontend `X-Lang` request header:
  - backend `/health` returned `200 OK`;
  - user frontend and admin frontend returned `200 OK`;
  - Chrome headless rendered the user home page and admin login page;
  - CORS preflight for `x-lang` now includes `X-Lang` in
    `Access-Control-Allow-Headers`.

Remaining implementation:

- Validate language, SEO, and branding launch readiness.

## Phase 7: Language, SEO, And Branding

Status: default first-visit locale, locale-prefixed public routes,
`hreflang`, locale sitemap URLs, and production branding checklist completed
on 2026-07-10. Details are recorded in
`docs/16-language-seo-branding-readiness.md` and
`docs/17-production-domain-branding-checklist.md`.

Goal: prepare public launch surface.

Tasks:

- Locale-prefixed routes for `zh-CN`, `zh-TW`, and `en`.
- IP-based first-visit language default.
- Manual language override.
- Sitemap and `hreflang`.
- Domain-driven favicon, logo, OG image, site name, and public text.

Success criteria:

- Each locale is directly accessible.
- Placeholder domains and assets are replaceable before launch.
- No Telegram or non-intersection platform pages are published.

Completed verification:

- Backend public config now exposes `default_locale` from country headers or
  `Accept-Language`.
- User frontend applies server default locale only when no manual language
  override exists.
- User frontend supports locale-prefixed public routes for `zh-CN`, `zh-TW`,
  and `en`.
- Public pages emit canonical links plus `hreflang` alternates for `zh-CN`,
  `zh-TW`, `en`, and `x-default`.
- Backend sitemap generation includes unprefixed and locale-prefixed variants
  for public static pages, categories, products, and posts.
- Browser smoke confirmed `/zh-CN`, `/zh-TW/products`, and `/en/products`
  render with the expected locale and `hreflang` metadata.
- Existing branding and SEO config surfaces were confirmed for launch asset
  replacement.
- Production domain and branding replacement checklist is documented in
  `docs/17-production-domain-branding-checklist.md`.
- Targeted checks passed:
  - `go test ./internal/http/handlers/public -run 'Test(LocaleFromCountryCode|ResolvePublicDefaultLocale)'`
  - `cd user && ./node_modules/.bin/vue-tsc -b`
  - `go test ./internal/service -run TestSitemapService`
  - browser smoke through local Chrome DevTools on locale-prefixed URLs

Remaining implementation:

- Execute the production domain and branding checklist after the final domain
  is selected.
- Repeat browser smoke on the final production domain before launch.

## Phase 8: Production Security And Compliance

Status: launch security checklist, production config template, and app-level
HTTP server timeout configuration added on 2026-07-10. Details are recorded in
`docs/18-production-security-compliance-checklist.md` and
`docs/19-production-config-template.md`.

Goal: make production launch blockers explicit before live traffic or payments.

Tasks:

- Rotate and externalize all production secrets.
- Lock CORS and public origins to final domains.
- Configure final payment/webhook/callback domains.
- Verify frontend bundles contain no provider/payment secrets.
- Verify public copy does not expose upstream/API/procurement details.
- Confirm admin 2FA, RBAC, and rate limiting.
- Confirm browser security headers at CDN/reverse proxy.
- Add app-level HTTP server timeouts and request header size limits before
  direct internet exposure.
- Document production config placeholders for release mode, CORS, final
  domains, payment callbacks, Redis/queue, secrets, USD site currency, and
  provider operating switches.

Success criteria:

- No default secrets or placeholder credentials remain.
- Live payment, provider sync, and order fulfillment can be disabled quickly.
- Final domain runtime smoke passes.
- Public users cannot see Telegram SKUs, non-intersection platforms, or
  internal fulfillment wording.

Completed verification:

- Backend `http.Server` now applies configurable `ReadHeaderTimeout`,
  `ReadTimeout`, `WriteTimeout`, `IdleTimeout`, and `MaxHeaderBytes` from
  `server.*` config.
- Default config values are present in `dujiao-next/config.yml` and Viper
  defaults.
- Production configuration template is documented in
  `docs/19-production-config-template.md`.
- Targeted tests passed:
  - `cd dujiao-next && GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/app ./internal/config`
