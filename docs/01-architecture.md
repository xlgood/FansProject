# Architecture

## Recommended Shape

Website3 should be composed of three layers:

1. Custom storefront for public SEO pages, product discovery, and checkout entry.
2. Dujiao-Next commerce foundation for products, orders, payments, admin, and delivery lifecycle.
3. Fansgurus adapter for upstream service sync, order forwarding, and status polling.

## Data Flow

1. Scheduled sync calls Fansgurus `action=services`.
2. Adapter normalizes upstream services into Website3 catalog records.
3. Adapter applies `rate * 10` to create Website3 sell price.
4. Locale detection chooses the initial language for first-time visitors.
5. Storefront reads Website3 catalog data from local database/API, not directly from Fansgurus.
6. Customer pays on Website3.
7. Paid order is queued for upstream fulfillment.
8. Adapter calls Fansgurus `action=add`.
9. Adapter stores upstream order id.
10. Poller updates order status until terminal state.

## Why Not Direct Frontend API Calls

Direct browser calls would expose the Fansgurus API key, add latency, prevent durable sync history, and make SEO pages dependent on third-party uptime.

## Performance Requirements

- Cache category and SKU lists.
- Paginate or virtualize large SKU lists.
- Pre-render high-value SEO landing pages.
- Keep order forwarding asynchronous so payment callbacks return quickly.
- Use idempotency keys for order forwarding and sync jobs.

## Locale Requirements

- Supported locales are `en`, `zh-CN`, and `zh-TW`.
- Public URLs should use explicit locale prefixes, for example `/en/...`, `/zh-CN/...`, and `/zh-TW/...`.
- IP-based detection should redirect only first-time non-prefixed entry requests.
- Manual language choice must override IP detection.
- SEO crawlers must be able to access every locale directly through stable URLs and `hreflang` alternates.
