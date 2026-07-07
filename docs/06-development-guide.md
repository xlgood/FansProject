# Website3 Development Guide

## 1. Implementation Strategy

Use Dujiao-Next as the commerce foundation and add a Website3-specific Fansgurus integration layer plus a custom SEO storefront.

Do not copy Dujiao-Next source into this repository unless the project strategy changes. During implementation, keep the upstream Dujiao-Next checkout external and track Website3-specific integration notes or patches in `patches/dujiao-next/`.

Before implementing any new requirement from scratch, follow `docs/07-implementation-policy.md`: verify whether Dujiao-Next already supports it, then use the installed `find-skills` skill to search for mature existing skills/frameworks, and only write custom code after rejecting better existing options.

For all non-trivial coding, refactoring, debugging, or review work, follow `docs/08-coding-standards.md` and use the local `karpathy-guidelines` skill.

## 2. Recommended System Components

## 2.1 Storefront

Purpose:

- Public website.
- SEO/GEO landing pages.
- Category/SKU browsing.
- Checkout entry.
- Language selection.

Implementation guidance:

- Prefer SSR or SSG for important public pages.
- Use stable language-prefixed URLs.
- Fetch catalog data from local Website3 APIs, not Fansgurus.
- Use pagination, search indexes, or virtualized lists for large SKU collections.

## 2.2 Dujiao-Next Commerce Foundation

Purpose:

- Product/order/payment/admin foundation.
- User account and order history.
- Payment callback handling.
- Admin operations.

Integration guidance:

- Add fields or mapping tables for Fansgurus upstream service ids.
- Keep Dujiao-Next payment lifecycle as source of truth for paid/unpaid order state.
- Trigger upstream fulfillment after local payment success.
- Keep local order ids separate from upstream Fansgurus order ids.

## 2.3 Fansgurus Adapter

Purpose:

- API client.
- SKU sync worker.
- Price multiplier application.
- Order forwarding.
- Status polling.

The adapter can be implemented as:

- A module inside the Dujiao-Next backend.
- A sidecar worker that talks to the same database.
- A separate internal service with authenticated internal APIs.

Recommended first implementation: backend module plus scheduled workers. This is simpler operationally than a separate service.

## 3. Environment Variables

Required:

```text
FANSGURUS_API_BASE_URL=https://fansgurus.com/api/v2
FANSGURUS_API_KEY=
PRICE_MULTIPLIER=10
DISPLAY_CURRENCY=USD
SKU_SYNC_INTERVAL_SECONDS=300
SKU_SYNC_TIMEOUT_SECONDS=30
ORDER_STATUS_FAST_INTERVAL_SECONDS=60
ORDER_STATUS_SLOW_INTERVAL_SECONDS=900
```

Optional later:

```text
GEOIP_PROVIDER=
GEOIP_API_KEY=
DEFAULT_LANGUAGE=en
SUPPORTED_LANGUAGES=en,zh-CN,zh-TW
LANGUAGE_COOKIE_NAME=website3_locale
```

Rules:

- Never expose `FANSGURUS_API_KEY` to browser code.
- Never log secrets.
- Never commit real `.env` files.

## 4. Data Model Additions

The exact table names should follow the final Dujiao-Next schema. Conceptually, Website3 needs these records.

## 4.1 Upstream Provider

Fields:

- `id`
- `name`
- `api_base_url`
- `is_active`
- `created_at`
- `updated_at`

Initial provider:

```text
name = fansgurus
api_base_url = https://fansgurus.com/api/v2
```

## 4.2 Upstream Service Mapping

Fields:

- `id`
- `provider_id`
- `upstream_service_id`
- `local_product_id`
- `local_sku_id`
- `category_name`
- `service_name`
- `service_type`
- `upstream_rate`
- `sell_rate`
- `min_quantity`
- `max_quantity`
- `supports_dripfeed`
- `supports_refill`
- `supports_cancel`
- `raw_payload_json`
- `content_hash`
- `is_active`
- `purchase_enabled`
- `last_seen_at`
- `created_at`
- `updated_at`

Indexes:

- Unique index on `provider_id + upstream_service_id`.
- Index on `category_name`.
- Index on `is_active`.
- Index on `purchase_enabled`.

## 4.3 Sync Run

Fields:

- `id`
- `provider_id`
- `status`
- `started_at`
- `finished_at`
- `fetched_count`
- `created_count`
- `updated_count`
- `deactivated_count`
- `error_count`
- `error_message`

## 4.4 Order Upstream Mapping

Fields:

- `id`
- `local_order_id`
- `provider_id`
- `upstream_service_id`
- `upstream_order_id`
- `forwarding_status`
- `upstream_status`
- `upstream_charge`
- `upstream_start_count`
- `upstream_remains`
- `last_forward_attempt_at`
- `last_status_poll_at`
- `idempotency_key`
- `error_message`
- `created_at`
- `updated_at`

Indexes:

- Unique index on `local_order_id`.
- Unique index on `idempotency_key`.
- Index on `forwarding_status`.
- Index on `upstream_order_id`.

## 4.5 Language Preference

If anonymous users are cookie-based only, this may not need a database table.

For logged-in users, store:

- `user_id`
- `preferred_language`
- `updated_at`

Supported values:

- `en`
- `zh-CN`
- `zh-TW`

## 5. Fansgurus API Client

## 5.1 Client Rules

- Use server-side HTTP client only.
- Send POST requests to `FANSGURUS_API_BASE_URL`.
- Use timeouts.
- Parse money values as decimal strings.
- Return typed errors for network failure, auth failure, upstream validation failure, and unexpected payload.
- Redact API key in logs.

## 5.2 Services Sync Call

Request:

```text
key=<secret>
action=services
```

Expected response:

```json
[
  {
    "service": 16252,
    "name": "Telegram ...",
    "type": "Default",
    "rate": "0.30",
    "min": 500,
    "max": 100000,
    "dripfeed": false,
    "refill": false,
    "cancel": false,
    "category": "Telegram ..."
  }
]
```

## 5.3 Balance Call

Use this for admin diagnostics only.

Request:

```text
key=<secret>
action=balance
```

## 5.4 Add Order Call

Only call after local payment success.

Common fields:

- `key`
- `action=add`
- `service`
- `link`
- `quantity`

Additional fields depend on `service_type`.

Initial type mapping:

- `Default`: `link`, `quantity`
- `Custom Comments`: `link`, `comments`
- `Poll`: `link`, `quantity`, `answer_number` if required by upstream docs
- `Mentions`: `link`, `quantity`, `usernames` or keyword/mentions field depending on upstream service requirements

Implementation note:

Do not enable purchase for a service type until its exact upstream payload requirements are verified.

## 6. SKU Sync Algorithm

Pseudo-flow:

```text
acquire provider sync lock
create sync_run(status=running)
fetch Fansgurus services
validate response is array
for each upstream service:
  normalize fields
  calculate content_hash
  calculate sell_rate = decimal(rate) * decimal(PRICE_MULTIPLIER)
  upsert mapping by provider_id + upstream_service_id
  create or update local Dujiao product/SKU
mark services not seen in this run as inactive after grace period
finish sync_run(status=success)
release lock
```

Failure behavior:

- If fetch fails, keep last known catalog.
- If one service fails validation, count error and continue if safe.
- If response is invalid or suspiciously empty, fail the whole run and do not deactivate all services.
- Never delete catalog records during normal sync.

## 7. Price Calculation

Use decimal operations.

Rules:

- Store upstream `rate` as decimal.
- Store sell `rate` as decimal.
- Lock final order amount at checkout.
- Do not recalculate a paid order if upstream price changes later.

Example:

```text
upstream_rate = 0.30
PRICE_MULTIPLIER = 10
sell_rate = 3.00
```

If the upstream price is per 1000 units, keep the same unit convention in Website3 and make the UI explicit.

## 8. Order Forwarding Algorithm

Pseudo-flow:

```text
on payment_success(local_order_id):
  verify order is paid
  verify upstream mapping exists
  verify service purchase_enabled
  create fulfillment job with idempotency_key

fulfillment worker:
  load local order and upstream mapping
  if upstream_order_id exists, do not submit again
  build Fansgurus add payload based on service_type
  call Fansgurus add
  store upstream_order_id
  set forwarding_status=submitted
```

Retry behavior:

- Retry network failures with backoff.
- Do not retry validation errors without admin intervention.
- Use idempotency in local job processing to prevent duplicate upstream orders.

## 9. Order Status Polling

Polling cadence:

- New submitted orders: every 1 minute for the first 30 minutes.
- Active in-progress orders: every 5 to 15 minutes.
- Old non-terminal orders: every 30 to 60 minutes.
- Terminal orders: stop polling.

Terminal states should be mapped after observing Fansgurus status values.

Store raw upstream status for debugging and normalized local status for UI.

## 10. Language Detection Design

## 10.1 Supported Languages

```text
en
zh-CN
zh-TW
```

## 10.2 Language Priority

Use this priority order:

1. Explicit URL language prefix.
2. User saved preference cookie.
3. Logged-in user profile preference.
4. IP geolocation.
5. `Accept-Language` header.
6. Default language `en`.

Note:

If the user explicitly changes language, update the saved preference and redirect to the equivalent language-prefixed URL.

## 10.3 IP Mapping

Recommended mapping:

```text
CN -> zh-CN
TW -> zh-TW
HK -> zh-TW
MO -> zh-TW
else -> en
```

If an IP provider returns only language/region hints instead of country code:

- Simplified Chinese regions map to `zh-CN`.
- Traditional Chinese regions map to `zh-TW`.
- Unknown maps to `en`.

## 10.4 GeoIP Provider

Options:

- CDN header such as Cloudflare `CF-IPCountry`.
- Server-side MaxMind GeoLite2 database.
- Paid geolocation API.

Recommended first implementation:

Use CDN country header in production and a local override header in development. This avoids adding an external latency dependency to every first request.

## 10.5 Redirect Rules

For first request to a non-language-prefixed URL:

```text
/some-page -> /{detected-locale}/some-page
```

Rules:

- Use 302 for detection-based redirects.
- Do not use permanent 301 for IP-based language redirects.
- Do not redirect if URL already contains a supported language prefix.
- Do not redirect static assets, API routes, payment callbacks, or admin routes unless explicitly designed.
- Search engine crawlers should be able to access all language URLs directly.

## 10.6 Caching Rules

Avoid caching one user's detected language for all users.

If language detection happens at the edge:

- Vary cache by language path, not by raw IP.
- Prefer redirecting to language-prefixed URLs, then cache those URLs normally.

If language detection happens in the app:

- Set `Vary: Accept-Language` only where needed.
- Do not cache root detection responses aggressively.

## 10.7 SEO Language Tags

Each localized page should include alternate links:

```html
<link rel="alternate" hreflang="en" href="https://example.com/en/path" />
<link rel="alternate" hreflang="zh-CN" href="https://example.com/zh-CN/path" />
<link rel="alternate" hreflang="zh-TW" href="https://example.com/zh-TW/path" />
<link rel="alternate" hreflang="x-default" href="https://example.com/en/path" />
```

## 11. Frontend Development Notes

Required frontend behaviors:

- Language switcher visible on public pages.
- Selected language persists.
- Product/category URLs include language prefix.
- Mobile navigation must support large category sets.
- SKU cards must show price, min/max, and support badges.
- Checkout forms must render fields based on service type.
- Unsupported service types must show "temporarily unavailable" or be hidden from checkout.

Performance:

- Avoid fetching the full service list on every page.
- Use category-specific APIs.
- Lazy-load below-the-fold SKU groups.
- Generate static metadata for SEO pages.

## 12. Backend Development Notes

Required backend behaviors:

- Server-side input validation.
- Decimal money calculations.
- Background job locking.
- Idempotent payment callbacks.
- Idempotent upstream forwarding.
- Structured logs with secret redaction.
- Admin-visible sync and order diagnostics.

Suggested service boundaries:

- `FansgurusClient`
- `CatalogSyncService`
- `PriceService`
- `OrderFulfillmentService`
- `OrderStatusPoller`
- `LocaleDetectionService`

## 13. Testing Plan

## 13.1 Unit Tests

Cover:

- Price multiplier decimal calculations.
- Service normalization.
- Content hash generation.
- Language detection priority.
- IP country to locale mapping.
- Quantity validation.
- Order payload building by service type.

## 13.2 Integration Tests

Cover:

- Mock Fansgurus `services` response imports SKUs.
- Changed upstream rate updates sell rate.
- Missing SKU becomes inactive after grace period.
- Payment success queues fulfillment.
- Fulfillment success stores upstream order id.
- Fulfillment retry does not duplicate upstream order submission.

## 13.3 End-To-End Tests

Cover:

- First-time visitor from CN lands on `zh-CN`.
- First-time visitor from TW/HK/MO lands on `zh-TW`.
- First-time visitor from US lands on `en`.
- Manual language switching persists.
- SKU browsing and checkout flow works on desktop.
- SKU browsing and checkout flow works on mobile.

## 14. Deployment Notes

Recommended production dependencies:

- PostgreSQL.
- Redis.
- CDN with country header support.
- Background worker process.
- Secret manager.
- Error tracking and uptime monitoring.

Deployment checks:

- API key configured.
- SKU sync job enabled.
- Payment callback URLs configured.
- Language redirects tested behind CDN.
- Sitemap generated.
- Admin account secured.

## 15. Open Questions Before Coding

- Which frontend framework will be used for the custom storefront if not using the Dujiao-Next user frontend directly?
- Which payment providers are required at launch?
- Should all Fansgurus categories be public, or should some high-risk/custom categories be hidden by default?
- What domain will be used for canonical and hreflang URLs?
- Which GeoIP method will production hosting provide?
