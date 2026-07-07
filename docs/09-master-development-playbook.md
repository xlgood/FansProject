# Website3 Master Development Playbook

## 1. Purpose

This document is the execution playbook for Website3. It converts the product requirements into implementation steps, expected results, error handling, disaster recovery, desktop/mobile optimization, page speed optimization, testing, deployment, and launch operations.

Use this document together with:

- `docs/05-requirements.md`
- `docs/06-development-guide.md`
- `docs/07-implementation-policy.md`
- `docs/08-coding-standards.md`

## 2. Mandatory Development Principles

## 2.1 Build-Vs-Reuse Rule

For every new requirement:

1. Check Dujiao-Next first.
2. If Dujiao-Next does not support it, use the installed `find-skills` skill.
3. Research mature open-source frameworks and libraries.
4. Prefer existing proven implementations when they satisfy security, license, maintainability, and integration requirements.
5. Write custom code only after better existing options are rejected.

Expected result:

- Every non-trivial feature has a short decision note explaining why it is reused, adapted, or custom-built.

Failure handling:

- If `find-skills` is unavailable, record the limitation and use fallback research tools.
- Do not skip the research step silently.

## 2.2 Coding Standard

Use `karpathy-guidelines` for all non-trivial coding work.

Required behavior:

- Think before coding.
- Keep implementation simple.
- Make surgical changes.
- Define verifiable success criteria.
- Avoid speculative abstractions.

Expected result:

- Small diffs.
- Clear verification.
- No unrelated refactors.

## 3. Target Architecture

## 3.1 Components

Website3 should run as these logical components:

- Public storefront: SEO/GEO pages, category pages, SKU pages, checkout entry, language routing.
- Dujiao-Next backend: products, orders, payments, admin, user/order lifecycle.
- Dujiao-Next admin frontend: operations, order review, manual retries, catalog visibility.
- Fansgurus adapter: SKU sync, price multiplier, upstream order forwarding, upstream status polling.
- Worker process: scheduled jobs, retry queues, polling.
- PostgreSQL: durable catalog/order/sync/payment state.
- Redis: locks, queues, rate limits, hot cache.
- CDN/edge layer: static assets, country header, redirects, caching.

## 3.2 Request Flow

Visitor flow:

1. User requests `/`.
2. Edge/app detects language using URL, cookie, IP country, and `Accept-Language`.
3. User is redirected with 302 to `/en/`, `/zh-CN/`, or `/zh-TW/`.
4. Storefront serves SSR/SSG HTML for SEO-critical pages.
5. Browser fetches paginated catalog API from Website3 local backend.

Order flow:

1. User selects a SKU.
2. Backend validates SKU active status, purchase eligibility, quantity, and required fields.
3. Backend locks current sell price into local order.
4. User pays through Dujiao-Next-supported payment flow.
5. Payment callback marks order paid idempotently.
6. Fulfillment job is queued.
7. Worker forwards order to Fansgurus.
8. Worker stores upstream order id.
9. Status poller updates local order until terminal state.

Expected result:

- Public browsing never depends on direct Fansgurus calls.
- Payment callback does not wait for Fansgurus.
- Every upstream order has a local audit trail.

## 4. Implementation Phases

## 4.1 Phase 0: Repository And Decision Baseline

Tasks:

- Keep this project repo as Website3 orchestration and documentation workspace.
- Keep Dujiao-Next source external unless explicitly approved.
- Keep real secrets out of the repo.
- Confirm `find-skills` and `karpathy-guidelines` are installed.
- Create decision records for framework, hosting, payment provider, and GeoIP provider.

Expected result:

- Project has documented architecture and standards.
- No real API key is committed.
- Dujiao-Next is referenced, not vendored.

Verification:

```bash
rg "FANSGURUS_API_KEY=." .
test -f ~/.codex/skills/find-skills/SKILL.md
test -f ~/.codex/skills/karpathy-guidelines/SKILL.md
```

Error handling:

- If a real key is found, remove it immediately, rotate the key, and document the incident.
- If a required skill is missing, install it before coding.

## 4.2 Phase 1: Upstream Research And Dujiao-Next Fit Check

Tasks:

- Clone Dujiao-Next externally.
- Read backend product/order/payment/admin models.
- Identify extension points for product sync and post-payment fulfillment.
- Confirm Dujiao-Next language file structure and routing approach.
- Confirm Dujiao-Next queue/scheduler support, if any.
- Use `find-skills` for any new capability not native to Dujiao-Next.

Expected result:

- A written integration map: which Dujiao modules are reused, extended, or bypassed.
- A list of required migrations or extension tables.

Verification:

- Every Website3 requirement maps to one of: Dujiao-native, Dujiao-extension, Fansgurus-adapter, custom storefront.

Error handling:

- If Dujiao-Next lacks clean extension points, prefer sidecar adapter over invasive core rewrites.
- If Dujiao-Next schema conflicts with SKU sync needs, use separate mapping tables.

## 4.3 Phase 2: Data Model And Migrations

Required tables or equivalent schema:

- `upstream_providers`
- `upstream_service_mappings`
- `sync_runs`
- `upstream_order_mappings`
- `catalog_sync_events`
- `user_language_preferences`, if user profile persistence is needed

Key constraints:

- Unique `provider_id + upstream_service_id`.
- Unique `local_order_id` in upstream order mapping.
- Unique `idempotency_key` for fulfillment jobs.
- Index active/purchasable catalog fields.

Expected result:

- Database can represent every Fansgurus SKU.
- Local products can be traced to upstream service ids.
- Orders can be retried without duplicate upstream submission.

Verification:

- Migration applies cleanly on empty database.
- Migration applies cleanly on staging-like database.
- Rollback strategy is documented.

Error handling:

- If migration fails before writing data, rollback and fix.
- If migration fails after partial writes, restore from pre-migration backup or run forward-fix migration.
- Never manually edit production data without an audit note.

Disaster recovery:

- Take database snapshot before schema changes.
- Keep migrations idempotent where possible.
- Maintain a restore rehearsal environment.

## 4.4 Phase 3: Fansgurus API Client

Implementation details:

- Server-side only.
- POST to `https://fansgurus.com/api/v2`.
- Timeout: 30 seconds for services sync, 10-20 seconds for order/status calls.
- Retry network failures with exponential backoff.
- Do not retry invalid request errors blindly.
- Redact API key in logs.
- Parse all prices as decimal strings.

Client methods:

- `GetBalance()`
- `ListServices()`
- `AddOrder(payload)`
- `GetOrderStatus(upstreamOrderID)`
- `GetBatchOrderStatus(upstreamOrderIDs)` if supported.
- `RequestRefill(upstreamOrderID)` if required later.
- `CancelOrder(upstreamOrderID)` if required later.

Expected result:

- Typed client errors distinguish auth, network, timeout, validation, bad JSON, and upstream business errors.

Verification:

- Balance call returns USD balance.
- Services call returns JSON array.
- Mock tests cover invalid JSON, timeout, auth error, and missing fields.

Error handling:

- Auth error: stop jobs, alert admin, do not keep retrying aggressively.
- Timeout/network error: retry with backoff and keep last known catalog.
- Invalid JSON: fail current sync, do not deactivate services.
- Empty service list: treat as suspicious and fail sync unless confirmed by admin.

Disaster recovery:

- Store raw successful service payload snapshots for recent syncs.
- If Fansgurus is down, continue serving last known active catalog but disable checkout only if order forwarding cannot be safely queued.

## 4.5 Phase 4: SKU Sync

Sync cadence:

- Default: every 5 minutes.
- Aggressive launch monitoring: every 1-2 minutes if upstream allows.
- Full sync lock: only one sync per provider at a time.

Algorithm:

1. Acquire Redis/database lock.
2. Create `sync_run`.
3. Call Fansgurus `services`.
4. Validate payload shape.
5. Normalize each service.
6. Compute content hash from fields affecting display/order.
7. Calculate `sell_rate = upstream_rate * 10`.
8. Upsert service mapping.
9. Create or update local product/SKU.
10. Mark unseen SKUs as inactive after grace period.
11. Write sync events.
12. Finish `sync_run`.
13. Release lock.

Expected result:

- New SKUs appear.
- Changed SKUs update.
- Removed SKUs become inactive safely.
- Prices always reflect 10x upstream rate.

Verification:

- Initial sync imports all upstream services.
- A mocked price change updates sell price.
- A mocked missing service does not delete immediately.
- Storefront reads local catalog only.

Error handling:

- Partial service validation failure: skip bad item, record error, continue if error count is low.
- High validation failure rate: fail sync and keep old catalog.
- Database deadlock: retry transaction.
- Lock stuck: expire lock with TTL and alert if repeated.

Disaster recovery:

- Keep previous catalog state.
- Use sync event log to reconstruct what changed.
- Provide admin action to pause sync if upstream sends bad data.

## 4.6 Phase 5: Catalog Normalization

Normalization tasks:

- Preserve original Fansgurus category and name.
- Derive platform where safe, for example Telegram, TikTok, Instagram, YouTube, X, Facebook.
- Derive service intent where safe, for example followers, likes, views, comments, members, traffic.
- Do not overfit parsing rules to one language.
- Store original text for audit.

Expected result:

- Users can browse by platform/category/intent.
- SEO pages can map to filtered SKU groups.

Error handling:

- If platform cannot be confidently derived, use original category only.
- If parsing creates wrong mappings, allow admin overrides.

## 4.7 Phase 6: Pricing And Checkout Calculation

Pricing rules:

- Upstream rate is stored unchanged.
- Sell rate is always upstream rate multiplied by 10.
- Use decimal arithmetic.
- Lock checkout price at order creation.
- Historical order price never changes after payment.

Quantity rules:

- Validate quantity >= `min`.
- Validate quantity <= `max`.
- Validate service type required fields.

Expected result:

- Display price and charged price match.
- Upstream price change affects new orders only.

Verification:

- Unit tests for decimal edge cases.
- Checkout tests for min/max validation.
- Price snapshot remains stable after SKU update.

Error handling:

- If SKU becomes inactive during checkout, block payment and show a clear message.
- If price changes before payment, either recalculate before payment or require user confirmation.
- If payment amount does not match order amount, mark for manual review.

## 4.8 Phase 7: Service Type Mapping

Initial supported types:

- `Default`
- `Custom Comments`
- `Poll`
- `Mentions`

Default behavior:

- Unsupported types are visible only if useful, but not purchasable.
- Purchase form fields are generated from verified type mapping.

Expected result:

- No malformed upstream orders are submitted.

Error handling:

- Unknown type: set `purchase_enabled=false`.
- Mapping uncertainty: require admin verification before enabling.
- Upstream validation error: mark fulfillment failed and expose retry only after correction.

## 4.9 Phase 8: Payment Integration

Use Dujiao-Next payment integrations where practical.

Payment callback requirements:

- Idempotent.
- Validates provider signature.
- Updates local order state once.
- Queues fulfillment asynchronously.
- Returns quickly.

Expected result:

- Paid orders are durable before Fansgurus forwarding.

Error handling:

- Duplicate callback: return success without duplicate state change.
- Invalid signature: reject and alert.
- Payment success but fulfillment queue unavailable: store paid state and enqueue recovery job.
- Payment amount mismatch: hold fulfillment and alert admin.

Disaster recovery:

- Reconciliation job checks paid orders without fulfillment jobs.
- Admin can manually requeue fulfillment.
- Payment provider records can be compared to local order records.

## 4.10 Phase 9: Upstream Fulfillment

Fulfillment algorithm:

1. Worker loads paid local order.
2. Worker checks idempotency key.
3. Worker verifies no upstream order id exists.
4. Worker builds Fansgurus payload.
5. Worker submits order.
6. Worker stores upstream order id and raw response.
7. Worker marks forwarding status submitted.

Expected result:

- Each local paid order creates at most one upstream order.

Error handling:

- Network timeout before response: mark as uncertain and require safe reconciliation before retry.
- Upstream validation error: mark failed, show admin reason.
- Upstream balance insufficient: pause fulfillment, alert admin, keep orders queued.
- Upstream duplicate uncertainty: avoid blind retry; use status/reconciliation where possible.

Disaster recovery:

- Fulfillment queue is durable.
- Admin can retry failed jobs.
- Uncertain jobs are separated from retryable jobs.

## 4.11 Phase 10: Order Status Polling

Polling cadence:

- First 30 minutes: every 1 minute.
- Active orders: every 5-15 minutes.
- Old orders: every 30-60 minutes.
- Terminal orders: stop polling.

Expected result:

- Customer order status remains close to upstream status.

Error handling:

- Status API timeout: retry later.
- Unknown upstream status: store raw value and map to `processing` until reviewed.
- Repeated polling failures: alert admin and show customer a stable processing state.

Disaster recovery:

- Polling can resume after downtime using `last_status_poll_at`.
- Terminal status is durable.

## 4.12 Phase 11: Multi-Language And IP Default

Supported locales:

- `en`
- `zh-CN`
- `zh-TW`

Priority:

1. Explicit URL locale.
2. Saved user/browser preference.
3. Logged-in profile preference.
4. IP country.
5. `Accept-Language`.
6. Default `en`.

IP mapping:

- `CN` -> `zh-CN`
- `TW`, `HK`, `MO` -> `zh-TW`
- Other -> `en`

Redirect rules:

- Only redirect non-prefixed public paths.
- Use 302, not 301.
- Do not redirect API, admin, assets, webhooks, or payment callbacks.
- Keep all locale URLs directly accessible.

Expected result:

- First-time visitors get a sensible default language.
- Manual switching persists.
- Search engines can crawl all languages.

Error handling:

- Missing GeoIP header: use `Accept-Language`.
- Invalid locale cookie: ignore and reset.
- Missing translation key: fall back to English and log.

Verification:

- Simulated CN request lands on `/zh-CN/...`.
- Simulated TW/HK/MO request lands on `/zh-TW/...`.
- Simulated US request lands on `/en/...`.
- Manual switch overrides IP.
- `hreflang` exists for all language variants.

## 4.13 Phase 12: Storefront UI/UX

Desktop requirements:

- Clear platform/category navigation.
- High-value landing pages above the fold.
- Search and filters visible on catalog pages.
- SKU comparison signals: price, min/max, refill, cancel, delivery hints.
- Checkout form explains required fields.

Mobile requirements:

- Mobile-first navigation.
- Sticky checkout summary where appropriate.
- Large tap targets.
- Avoid horizontal overflow.
- Keep filters collapsible.
- Checkout form should be short and progressive.

Expected result:

- Users can browse, choose, and checkout without understanding SMM panel internals.

Error handling:

- Empty category: show related categories and search.
- Inactive SKU: show unavailable state, not broken checkout.
- Slow API: show skeleton/loading and cached fallback.

## 4.14 Phase 13: SEO/GEO Pages

Page groups:

- Home page.
- Platform pages.
- Service intent pages.
- Platform + intent pages.
- Country/language pages where supply supports them.
- SKU detail pages.
- FAQ and policy pages.

Technical rules:

- SSR/SSG for important pages.
- Locale-prefixed URLs.
- Canonical URL per language.
- `hreflang` for `en`, `zh-CN`, `zh-TW`, and `x-default`.
- XML sitemap by locale.
- Product/Offer schema only where accurate.
- FAQ schema only for real FAQ content.

Expected result:

- Core pages are indexable without client-side JavaScript.

Error handling:

- Thin duplicate pages: noindex or merge.
- Missing localized content: fallback carefully, avoid indexing machine-empty pages.
- Outdated SKU page: show inactive state or redirect to category if permanently removed.

## 4.15 Phase 14: Admin And Operations

Admin capabilities:

- View SKU sync status.
- View active/inactive SKU counts.
- See upstream and sell rates.
- Disable SKU/category.
- View failed sync events.
- View paid orders awaiting fulfillment.
- Retry failed fulfillment.
- Pause upstream sync or fulfillment.
- View upstream balance.

Expected result:

- Operator can diagnose common issues without database access.

Error handling:

- Admin retry must be idempotent.
- Dangerous actions require confirmation.
- All admin changes are audit logged.

## 5. Error Taxonomy

## 5.1 User-Facing Errors

Use clear messages:

- SKU unavailable.
- Quantity below minimum.
- Quantity above maximum.
- Required field missing.
- Payment pending.
- Payment failed.
- Order paid and processing.
- Delivery delayed, support notified.

Do not expose:

- API keys.
- Raw upstream stack traces.
- Internal request payloads.

## 5.2 Internal Error Types

Use typed errors:

- `UpstreamAuthError`
- `UpstreamTimeoutError`
- `UpstreamNetworkError`
- `UpstreamInvalidResponseError`
- `UpstreamValidationError`
- `PaymentSignatureError`
- `PaymentAmountMismatchError`
- `FulfillmentDuplicateRiskError`
- `CatalogSyncSuspiciousPayloadError`

Expected result:

- Retry policy is based on error type, not string matching.

## 6. Retry And Backoff

Retryable:

- Network timeout.
- Temporary 5xx.
- Redis lock conflict after short wait.
- Database serialization/deadlock error.

Not automatically retryable:

- Invalid API key.
- Invalid order field.
- Unsupported service type.
- Payment amount mismatch.
- Duplicate-risk uncertain upstream submission.

Backoff:

- Start with 30 seconds.
- Double up to 15 minutes.
- Add jitter.
- Cap retry attempts by job type.

Expected result:

- Temporary failures recover without creating duplicate orders or overwhelming upstream.

## 7. Disaster Recovery

## 7.1 Backup Strategy

PostgreSQL:

- Daily full backup.
- Point-in-time recovery if hosting supports it.
- Backup before migrations.
- Monthly restore rehearsal.

Redis:

- Treat queues as important but reconstructable where possible.
- Persist queue state if selected queue supports it.

Files/assets:

- Store uploaded assets in durable object storage.
- Keep CDN cache disposable.

## 7.2 Recovery Scenarios

Database loss:

- Restore latest backup.
- Re-run SKU sync.
- Reconcile paid orders with payment provider.
- Reconcile upstream order ids where available.

Fansgurus outage:

- Keep browsing online from cache/database.
- Keep paid orders queued.
- Show processing/delay notice.
- Resume fulfillment when upstream recovers.

Bad upstream SKU payload:

- Fail sync.
- Keep last known good catalog.
- Alert admin.
- Do not mass deactivate SKUs.

Payment callback outage:

- Use provider reconciliation.
- Reprocess missed callbacks if provider supports replay.
- Manually mark verified paid orders only with audit log.

Deployment failure:

- Roll back app version.
- Do not roll back database blindly after destructive migrations.
- Prefer forward-fix migrations after data changes.

## 8. Performance Requirements

## 8.1 Frontend Page Speed Targets

Targets for key landing pages:

- LCP under 2.5 seconds on good mobile 4G.
- CLS under 0.1.
- INP under 200 ms where measurable.
- HTML is useful without waiting for full catalog API.
- Initial JavaScript budget should stay small for SEO pages.

## 8.2 Storefront Optimization

Required:

- SSR/SSG high-value pages.
- CDN static assets.
- Critical CSS for above-the-fold content.
- Image compression and responsive sizes.
- Lazy-load below-the-fold sections.
- Paginate SKU lists.
- Cache category API responses.
- Avoid shipping admin libraries to public frontend.
- Avoid rendering 5000+ SKUs in a single page.

Expected result:

- Mobile users see useful content quickly.
- Search crawlers receive meaningful HTML.

## 8.3 Backend Optimization

Required:

- Index catalog filters.
- Cache popular category queries.
- Use database pagination.
- Use queue workers for slow upstream calls.
- Use connection pooling.
- Use read-through cache for stable catalog data.

Expected result:

- Catalog pages remain fast under high SKU count.
- Payment callbacks are fast and durable.

## 8.4 Cache Strategy

Cache layers:

- CDN cache for static assets.
- SSR/SSG output cache for landing pages.
- Redis cache for category/SKU API responses.
- Database as source of truth.

Invalidation:

- SKU sync price/category changes invalidate affected category and SKU caches.
- Manual admin disable invalidates affected pages.
- Locale pages cache separately.

Error handling:

- If Redis fails, fall back to database with rate protection.
- If CDN serves stale page, SKU detail API must still prevent checkout for inactive SKU.

## 9. Desktop And Mobile QA

Desktop checks:

- 1366x768 layout.
- 1440x900 layout.
- 1920x1080 layout.
- Keyboard navigation.
- Search/filter usability.
- Checkout summary visibility.

Mobile checks:

- 375x667 iPhone-sized layout.
- 390x844 modern iPhone layout.
- 412x915 Android layout.
- Touch targets >= 44px.
- No horizontal scroll.
- Form input types correct.
- Payment flow returns to correct order status.

Expected result:

- Same core flow works on desktop and mobile.

## 10. Security Requirements

Required:

- Fansgurus API key server-side only.
- Payment secrets server-side only.
- Admin protected by strong auth.
- CSRF protection where applicable.
- Rate limit login, checkout, and order creation.
- Validate all form fields server-side.
- Sanitize upstream SKU text before rendering.
- Redact secrets from logs.
- Audit admin changes.

High-risk areas:

- Payment callback.
- Order forwarding.
- Admin retry.
- API key storage.
- Upstream raw payload rendering.

Expected result:

- User input and upstream text cannot create XSS.
- Payment cannot be spoofed.
- Duplicate upstream orders are prevented.

## 11. Observability

Metrics:

- SKU sync success/failure.
- SKU sync duration.
- Upstream service count.
- SKU created/updated/deactivated count.
- Fansgurus API latency and error rate.
- Paid orders awaiting fulfillment.
- Fulfillment success/failure.
- Order status polling lag.
- Payment callback failures.
- Cache hit rate.
- Frontend Core Web Vitals.

Logs:

- Structured JSON logs.
- Include request id.
- Include local order id and upstream order id where safe.
- Never log API keys or payment secrets.

Alerts:

- SKU sync failed 3 times.
- Fansgurus auth error.
- Upstream balance low.
- Fulfillment queue backlog high.
- Payment callback failures.
- Database backup failed.
- Error rate spike.

## 12. Testing Strategy

## 12.1 Unit Tests

Cover:

- Decimal price multiplier.
- SKU normalization.
- Content hash.
- Locale detection priority.
- IP-to-locale mapping.
- Quantity validation.
- Payload building by service type.
- Error classification.

## 12.2 Integration Tests

Cover:

- Mock services sync creates catalog.
- Mock price change updates sell price.
- Mock missing SKU becomes inactive after grace period.
- Payment success queues fulfillment.
- Fulfillment stores upstream id.
- Duplicate callback does not duplicate fulfillment.
- Status polling updates local state.

## 12.3 End-To-End Tests

Cover:

- CN visitor -> `/zh-CN/`.
- TW/HK/MO visitor -> `/zh-TW/`.
- US visitor -> `/en/`.
- Manual language switch persists.
- Desktop catalog browse.
- Mobile catalog browse.
- Checkout validation.
- Paid order processing state.

## 12.4 Load Tests

Scenarios:

- Home page traffic.
- Category page traffic.
- Search/filter traffic.
- Checkout bursts.
- SKU sync during browsing.

Expected result:

- Browsing performance remains acceptable while sync jobs run.
- Checkout and payment callbacks are not starved by catalog traffic.

## 13. Deployment Plan

## 13.1 Environments

Local:

- Development only.
- Mock payments preferred.
- Real Fansgurus read-only calls allowed.

Staging:

- Production-like database.
- Mock or sandbox payments.
- Real Fansgurus services sync.
- No real upstream order unless explicitly approved.

Production:

- Real payment.
- Real Fansgurus order forwarding.
- Monitoring and backups enabled.

## 13.2 Release Steps

1. Confirm current backup.
2. Run migrations.
3. Deploy backend.
4. Deploy workers.
5. Deploy storefront.
6. Run health checks.
7. Run smoke tests.
8. Enable SKU sync.
9. Enable payment callbacks.
10. Enable fulfillment.
11. Monitor for at least 60 minutes.

Expected result:

- Release can be rolled back or forward-fixed safely.

## 13.3 Rollback Plan

Safe rollback:

- Revert app version.
- Keep database if migrations are backward compatible.
- Pause workers if duplicate-risk exists.

Unsafe rollback:

- Do not roll back database after irreversible data migration unless restore plan is confirmed.

## 14. Launch Checklist

Catalog:

- Full sync completes.
- SKU count matches upstream expectation.
- 10x price rule verified.
- Inactive SKU behavior verified.

Checkout:

- Min/max validation works.
- Unsupported types blocked.
- Payment success creates fulfillment job.
- Duplicate payment callback safe.

Fulfillment:

- Upstream add payload verified for supported types.
- Failed fulfillment retry works.
- Insufficient upstream balance alert works.

Language:

- `/en/`, `/zh-CN/`, `/zh-TW/` work.
- IP default works.
- Manual switch persists.
- `hreflang` works.

SEO:

- Sitemap generated.
- Robots configured.
- Canonical URLs correct.
- Core pages SSR/SSG.

Performance:

- Mobile landing page passes target checks.
- Category pages paginate.
- CDN cache configured.
- API cache configured.

Ops:

- Backups enabled.
- Alerts enabled.
- Admin account secured.
- Secrets stored outside repo.

## 15. Runbooks

## 15.1 Fansgurus API Key Invalid

Symptoms:

- Balance call fails auth.
- Services sync fails auth.
- Fulfillment fails auth.

Actions:

1. Pause sync and fulfillment.
2. Verify key in secret manager.
3. Rotate key if leaked or invalid.
4. Run balance check.
5. Resume sync.
6. Resume fulfillment queue.

## 15.2 Upstream Balance Is Zero Or Low

Symptoms:

- Fulfillment fails due to insufficient balance.
- Admin balance check shows low USD balance.

Actions:

1. Pause fulfillment if needed.
2. Keep paid orders queued.
3. Refill Fansgurus balance.
4. Run balance check.
5. Resume fulfillment.
6. Monitor backlog.

## 15.3 SKU Sync Fails

Actions:

1. Check sync run error.
2. Check Fansgurus API status with balance/services read-only call.
3. Keep last known catalog live.
4. Do not mass deactivate SKUs.
5. Fix parser/client issue.
6. Re-run sync manually.

## 15.4 Duplicate Fulfillment Risk

Symptoms:

- Timeout after submitting upstream order.
- Local job has no upstream id but request may have reached Fansgurus.

Actions:

1. Mark job `uncertain`.
2. Do not auto-retry.
3. Check upstream manually if possible.
4. Attach upstream id if found.
5. Only retry after confirming no upstream order exists.

## 15.5 Payment Provider Callback Failure

Actions:

1. Check provider dashboard.
2. Replay callback if supported.
3. Run reconciliation job.
4. For manual correction, verify provider transaction first.
5. Audit every manual status change.

## 16. Definition Of Done

A feature is done only when:

- It satisfies documented requirements.
- It follows build-vs-reuse policy.
- It follows coding standards.
- It has appropriate tests or verification.
- It has error handling.
- It does not expose secrets.
- It does not break desktop/mobile flows.
- It does not degrade SEO-critical pages.
- Operational impact is documented.

