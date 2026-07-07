# Website3 Requirements Document

## 1. Project Overview

Website3 is a reseller storefront for social media and digital growth services. It uses Fansgurus as the upstream service provider and uses Dujiao-Next as the commerce/order foundation where practical.

Website3 must provide a custom, fast, SEO-friendly public storefront, support desktop and mobile users, synchronize Fansgurus SKUs and prices, and sell every synchronized SKU at 10x the upstream Fansgurus price.

## 2. Business Goals

- Launch a standalone reseller website with all available Fansgurus SKUs.
- Automatically reflect upstream SKU additions, removals, metadata changes, and price changes.
- Maintain a fixed pricing rule: Website3 price equals Fansgurus upstream price multiplied by 10.
- Provide a better public browsing and purchase experience than a raw SMM panel.
- Build SEO/GEO landing pages for organic acquisition.
- Support Simplified Chinese, Traditional Chinese, and English.
- Automatically choose the initial display language based on visitor IP while still allowing manual language switching.

## 3. Users

## 3.1 Visitor

A non-logged-in user who browses SEO pages, categories, SKUs, pricing, FAQ, and policies.

## 3.2 Customer

A user who places and pays for orders, views order status, requests support, and may reorder previous services.

## 3.3 Admin

An operator who manages Website3 settings, reviews orders, monitors upstream sync, handles support, and manages SEO content.

## 4. Functional Requirements

## 4.1 Catalog And SKU Sync

Website3 must synchronize Fansgurus service data from `https://fansgurus.com/api/v2` using the `services` action.

Required upstream fields:

- `service`
- `name`
- `type`
- `rate`
- `min`
- `max`
- `dripfeed`
- `refill`
- `cancel`
- `category`

Required behavior:

- Import every upstream Fansgurus SKU unless explicitly disabled by admin rules.
- Preserve upstream service id as the canonical provider identifier.
- Store upstream raw service payload for debugging and reconciliation.
- Normalize categories for browsing.
- Store upstream price and Website3 sell price separately.
- Detect SKU additions, metadata changes, price changes, and missing services.
- Mark missing upstream services inactive after a configurable grace period instead of immediate hard deletion.
- Record sync run history, including start time, end time, result, changed count, error count, and upstream response size.

Acceptance criteria:

- A full sync can populate all Fansgurus services into the local catalog.
- If Fansgurus changes a service price, Website3 updates the upstream price and recalculates the sell price.
- If Fansgurus removes a service, Website3 eventually hides it from customer purchase.
- The storefront never needs to call Fansgurus directly.

## 4.2 Pricing

All Website3 SKU prices must be 10x the upstream Fansgurus price.

Formula:

```text
website3_rate = fansgurus_rate * 10
```

Rules:

- Use decimal arithmetic.
- Do not use binary floating point for money.
- Keep the original upstream rate for audit.
- Apply the multiplier consistently in storefront, order calculation, admin views, and API responses.
- Support future admin-visible multiplier configuration, but launch default must be `10`.

Acceptance criteria:

- If upstream `rate` is `5.00`, Website3 displays and charges `50.00`.
- If upstream `rate` changes to `6.25`, Website3 displays and charges `62.50` after sync.
- Historical paid order amounts do not change after upstream price updates.

## 4.3 Product And Category Browsing

Website3 must provide:

- Home page.
- Platform pages.
- Category pages.
- SKU listing pages.
- SKU detail pages.
- Search and filtering.
- Sort by popularity, price, platform, service type, refill support, and delivery speed where extractable from SKU text.

Required SKU display fields:

- Service name.
- Category.
- Price.
- Minimum quantity.
- Maximum quantity.
- Refill support.
- Cancel support.
- Drip-feed support.
- Required input fields based on service type.

Acceptance criteria:

- Large catalogs do not render all SKUs at once.
- Users can find services by platform, category, and keyword.
- Inactive services are not purchasable.

## 4.4 Order And Fulfillment

Website3 must create local orders first and forward paid orders to Fansgurus asynchronously.

Required behavior:

- Customer selects SKU, enters required service fields, quantity, and submits order.
- Website3 validates quantity against SKU `min` and `max`.
- Website3 calculates final amount from locked sell price at checkout time.
- After payment success, Website3 queues upstream fulfillment.
- Adapter calls Fansgurus `add` action with the correct service type payload.
- Website3 stores upstream order id after successful forwarding.
- Website3 polls upstream order status until terminal state.
- Customer can view local and upstream-derived order status.

Supported initial Fansgurus service types:

- `Default`
- `Custom Comments`
- `Poll`
- `Mentions`

Other service types must be stored and displayed but may be disabled from purchase until mapped.

Acceptance criteria:

- A paid order is never lost if the upstream API is temporarily unavailable.
- Retrying order forwarding does not create duplicate upstream orders.
- Unsupported service types cannot be purchased until their payload requirements are implemented.

## 4.5 Payments

Website3 should use Dujiao-Next payment capabilities where practical.

Payment requirements:

- Payment provider configuration must stay server-side.
- Payment callbacks must be idempotent.
- Payment success must trigger asynchronous fulfillment, not synchronous upstream blocking.
- Customer must see clear payment success, payment pending, payment failed, and order processing states.

Launch payment providers are an open decision and must be finalized before implementation.

## 4.6 Multi-Language And IP-Based Default Language

Website3 must support three languages:

- Simplified Chinese: `zh-CN`
- Traditional Chinese: `zh-TW`
- English: `en`

Dujiao-Next already has Simplified Chinese, Traditional Chinese, and English language support. Website3 should reuse or extend that language structure where practical.

Required behavior:

- Visitors can manually switch language at any time.
- Manual language choice must override IP-based detection.
- Manual language choice should be stored in a cookie or equivalent browser persistence.
- First-time visitors without a saved language preference should receive a default language based on IP geolocation.
- The system must also consider `Accept-Language` as a fallback if IP geolocation is unavailable.
- Search engines should have stable crawlable language URLs and must not depend only on IP redirects.

Default language rules:

- If user has saved language preference, use that language.
- Else if URL contains explicit language prefix, use that language.
- Else if IP geolocation country or region is Mainland China, use `zh-CN`.
- Else if IP geolocation country or region is Taiwan, Hong Kong, or Macau, use `zh-TW`.
- Else if `Accept-Language` strongly prefers Chinese, map Simplified Chinese variants to `zh-CN` and Traditional Chinese variants to `zh-TW`.
- Else use `en`.

Recommended URL structure:

- `/en/...`
- `/zh-CN/...`
- `/zh-TW/...`

SEO rules:

- Each language version must have its own URL.
- Add `hreflang` tags for all supported language alternates.
- Avoid forcing search engine crawlers into one IP-based language.
- IP detection should choose the initial entry language, not prevent access to other languages.

Acceptance criteria:

- A first-time Mainland China visitor lands on Simplified Chinese by default.
- A first-time Taiwan, Hong Kong, or Macau visitor lands on Traditional Chinese by default.
- A first-time US visitor lands on English by default.
- A user who manually selects English keeps English on the next visit even from a Chinese IP.
- A user can directly open `/zh-TW/...` and see Traditional Chinese regardless of IP.
- Search engines can crawl all three language versions through stable URLs.

## 4.7 SEO/GEO Requirements

Website3 must be designed for organic search acquisition.

Required page groups:

- Platform landing pages.
- Service-intent landing pages.
- Country or language-targeted pages where relevant.
- SKU detail pages.
- FAQ pages.
- Policy pages.

Technical requirements:

- Server-render or statically generate important landing pages.
- Generate XML sitemap for active pages.
- Add canonical URLs.
- Add hreflang URLs for language variants.
- Add structured data where accurate.
- Avoid duplicate thin pages.
- Avoid copying Fansgurus SKU text as the only unique page content.

Acceptance criteria:

- Core landing pages are indexable without client-side API execution.
- Sitemap includes language-specific URLs.
- Category pages remain fast even with a large SKU count.

## 4.8 Admin Requirements

Admin must be able to:

- View synchronized categories and SKUs.
- See upstream rate and Website3 sell rate.
- See sync status and last sync time.
- Disable specific SKUs or categories locally.
- Review orders and upstream order ids.
- Retry failed upstream fulfillment.
- View upstream API errors.
- Configure sync interval and price multiplier if permitted.
- Manage SEO pages and language content.

Acceptance criteria:

- Admin can diagnose whether an order failed due to payment, local validation, upstream API, or status polling.
- Admin can disable a problematic SKU without deleting upstream sync history.

## 4.9 Customer Support And Policy Pages

Required pages:

- Terms of service.
- Privacy policy.
- Refund policy.
- Delivery policy.
- Contact or support page.
- FAQ.

Policy requirements:

- Explain that delivery depends on upstream availability.
- Explain refund/refill limitations.
- Avoid unsupported guarantees such as guaranteed account safety or guaranteed platform ranking.

## 5. Non-Functional Requirements

## 5.1 Performance

- Public pages should load quickly on desktop and mobile.
- Avoid rendering thousands of SKU cards in one response.
- Use cached catalog APIs.
- Use CDN for static assets.
- Use background jobs for sync and upstream order polling.
- Payment callback response should not wait on Fansgurus fulfillment.

## 5.2 Reliability

- SKU sync failures must not take the storefront down.
- Last known good catalog should remain available.
- Failed upstream order forwarding must be retryable.
- Duplicate upstream order creation must be prevented.
- Sync jobs should use locks to prevent overlapping runs.

## 5.3 Security

- Fansgurus API key must remain server-side.
- Do not commit `.env` files.
- Protect admin endpoints.
- Validate all order input server-side.
- Rate-limit order creation, login, and API endpoints.
- Sanitize SKU names and generated content before rendering.

## 5.4 Observability

Monitor:

- SKU sync success/failure.
- Upstream API latency.
- Upstream API error rate.
- Number of active/inactive SKUs.
- Price change count per sync.
- Order forwarding success/failure.
- Order status polling lag.
- Payment callback failures.

## 6. Constraints

- Dujiao-Next source code is not vendored into this project structure.
- Dujiao-Next is used as an external open-source base/reference during implementation.
- Fansgurus does not appear to provide SKU webhooks, so SKU updates are near-real-time polling.
- Real upstream order tests require funded Fansgurus balance and explicit approval.

## 7. Launch Acceptance Checklist

- Fansgurus API key stored only in server-side secret management.
- Full SKU sync works.
- Price multiplier is exactly 10x.
- Unsupported service types are safely disabled.
- Checkout validates quantity and required fields.
- Paid orders queue upstream fulfillment.
- Upstream status polling updates customer order status.
- Desktop and mobile storefront are usable and fast.
- All three languages are available.
- IP-based initial language selection works without blocking manual switching.
- SEO landing pages are server-rendered or statically generated.
- Sitemap, canonical, and hreflang are generated.
- Admin can monitor sync and order failures.
