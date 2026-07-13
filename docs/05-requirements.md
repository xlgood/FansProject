# Requirements

## 1. Project Overview

The target site is a Dujiao-Next-based commerce platform aggregating FansGurus fan/growth services and TGX Account account-purchase products.

Customers should see a unified marketplace by platform. For each supported platform, the site can offer:

- fan/growth services from FansGurus;
- account products from TGX.

Only platforms available from both providers after Telegram exclusion are visible.

## 2. Roles

Visitor:

- browses public pages, platforms, SKUs, FAQ, policies.

Customer:

- registers or checks out as allowed by Dujiao-Next configuration;
- places orders;
- pays;
- views fulfillment and delivery status.

Admin:

- manages provider credentials;
- runs sync;
- reviews SKU mappings and exclusions;
- manages orders and upstream fulfillment;
- retries failed jobs;
- manages SEO and multilingual content.

## 3. Catalog Requirements

- Import FansGurus services from `services`.
- Import TGX commodities from `/shared/commodity/items`.
- Store raw upstream payloads.
- Normalize platforms.
- Exclude Telegram-related SKUs.
- Compute platform intersection.
- Publish only intersection platform SKUs.
- Keep provider-specific upstream identifiers:
  - FansGurus `service`;
  - TGX `code`.
- Record upstream price and target price separately.
- Support local disable rules.
- Keep historical paid order amounts immutable.

Acceptance:

- A sync can populate both provider catalogs.
- Telegram SKUs are absent from storefront navigation, search, sitemap, and checkout.
- YouTube appears only if TGX also has YouTube and FansGurus has YouTube after filtering.
- Price calculations match configured multipliers.

## 4. Pricing Requirements

FansGurus:

```text
target_price = upstream_rate * 5
```

TGX:

```text
target_price_usd = upstream.price_cny * tgx_connection.exchange_rate * 1.2
```

Rules:

- decimal math only;
- display and settlement currency is USD;
- FansGurus prices are USD; TGX prices are CNY and must use the configured
  CNY-to-USD connection exchange rate during catalog sync;
- round according to USD site currency policy;
- persist multiplier used at order time;
- expose upstream cost and margin in admin only, not public UI.

Acceptance:

- FansGurus rate `2.00` displays as `10.00`.
- TGX base price `100.00` displays as `120.00`.
- Existing orders keep the original charged amount after upstream price changes.

## 4.1 Payment Requirements

Launch payment channels:

- Alipay.
- WeChat Pay.
- PayPal.

Implementation should reuse Dujiao-Next payment integrations where available. Payment credentials and callback secrets must be configured server-side only.

## 5. Checkout And Fulfillment

Common:

- Create local order before upstream order.
- Charge customer locally.
- After payment success, enqueue provider fulfillment.
- Use idempotency keys.
- Store upstream order/trade ID.
- Retry transient failures.
- Show local order status and provider-derived status.

FansGurus:

- Send `add` request using service-type-specific payload.
- Poll `status`.
- Support refill/cancel display where upstream supports it.

TGX:

- Check inventory where practical.
- Send `/shared/commodity/trade`.
- Store returned `trade_no`.
- Deliver returned `secret` for automatic delivery.
- Poll `/shared/commodity/query` for manual or delayed delivery.

Acceptance:

- A paid local order is not lost if upstream is temporarily unavailable.
- Retry does not create duplicate TGX purchases or duplicate FansGurus orders.
- Unsupported FansGurus service types cannot be purchased until form mapping exists.

## 6. Multi-Language Requirements

- Locales: `zh-CN`, `zh-TW`, `en`.
- Explicit locale URLs.
- First visit default by IP.
- Manual switch overrides IP.
- `Accept-Language` fallback.
- Admin content supports all three locales.

Acceptance:

- Mainland China IP defaults to `zh-CN`.
- Taiwan/Hong Kong/Macau IP defaults to `zh-TW`.
- US IP defaults to `en`.
- Direct `/zh-TW/...` access always shows Traditional Chinese.

## 7. Admin Requirements

Admin must be able to:

- configure provider credentials;
- run provider sync;
- see sync errors;
- inspect raw upstream payloads;
- override platform mappings;
- disable SKU/category/platform;
- view upstream and target prices;
- review local orders and upstream IDs;
- retry failed fulfillment;
- view TGX delivered secrets with proper access controls;
- configure multipliers if business allows.

## 8. Non-Functional Requirements

- Upstream secrets server-side only.
- PostgreSQL recommended for production.
- Redis queue enabled for fulfillment.
- Payment callbacks idempotent.
- Large catalogs paginated and searchable.
- Critical flows covered by tests before launch.
- No real upstream order placement without explicit approval.
- Domain is not fixed during development. Use placeholder domain text and make all domain-dependent branding replaceable before launch.
- The frontend should support domain-driven favicon, logo, site name, SEO images, and public text selection.
- Use one root `.env` for integration settings.
- Keep cloned Dujiao-Next source directories out of the root repository's tracked files.
