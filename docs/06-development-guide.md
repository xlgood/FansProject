# Development Guide

## Phase 0: Source And Baseline

1. Use the Dujiao-Next source already cloned into the project:
   - backend: `dujiao-next/`
   - user frontend: `user/`
   - admin frontend: `admin/`
   - docs: `document/`
2. Confirm Go, Node, PostgreSQL, Redis versions.
3. Start the unmodified system locally.
4. Verify frontend, admin, API, login, product list, order creation, and payment sandbox flow.

No provider integration should start until the base system is running.

The cloned source directories are not tracked by the root repository. Keep their nested upstream git histories intact. Project-level integration settings should live in the root `.env`; if Dujiao-Next requires per-service config files, generate or copy values from the root `.env` during local setup.

## Phase 1: Provider Adapter Design

Create provider adapters behind a small internal contract:

- `SyncCatalog(ctx)`.
- `Normalize(raw)`.
- `Quote(sku, variant)`.
- `CreateUpstreamOrder(ctx, localOrder)`.
- `GetUpstreamStatus(ctx, upstreamRef)`.

Do not force FansGurus and TGX into one leaky data model. Normalize at catalog boundary, keep provider-specific raw payloads.

## Phase 2: Database Additions

Likely additions:

- provider table;
- provider credentials/settings;
- provider raw catalog table;
- unified SKU mapping table;
- platform normalization table;
- sync run table;
- upstream fulfillment table;
- upstream event/error log table.

Prefer extending Dujiao-Next tables if they already support equivalent fields. Add new tables only where needed.

## Phase 3: Sync Jobs

FansGurus:

- POST `action=services`.
- Store raw services.
- Normalize platform.
- Apply Telegram filter.
- Apply the FansGurus allowlist.
- Calculate price from the connection's exchange-rate, markup, and rounding settings.

TGX:

- POST `/shared/commodity/items`.
- Store raw categories and children.
- Parse `config`.
- Parse `widget`.
- Normalize platform.
- Apply Telegram filter.
- Apply the TGX allowlist.
- Convert its `price` from CNY to USD with the connection exchange rate, then
  apply the connection markup and rounding settings.

Currency:

- target site display currency: USD;
- target site settlement currency: USD;
- no automatic provider currency conversion during sync;
- document any future payment-channel currency conversion separately in payment configuration.

## Phase 4: Storefront

Use Dujiao-Next user frontend as the base:

- add platform navigation based on active, provider-allowed SKUs;
- show two service groups per platform: fan/growth and account products;
- render provider-specific form fields through normalized schema;
- hide unsupported SKUs from purchase;
- implement locale-prefixed routes and language switch.

## Phase 5: Checkout And Fulfillment

- Customer pays locally.
- Payment callback marks order paid.
- Queue job calls provider adapter.
- Store upstream ID and response.
- Poll or query status.
- Deliver TGX secret where returned.
- Update Dujiao-Next delivery state.

## Phase 6: Admin

Add admin screens or extend existing ones:

- provider settings;
- sync dashboard;
- SKU mapping and filters;
- provider allowlist outcomes;
- provider order status;
- retry tools;
- pricing, exchange-rate, rounding, and automatic-price-sync visibility.

## Phase 7: Verification

Minimum checks:

- unit tests for platform normalization and Telegram exclusion;
- unit tests for price math;
- adapter signing tests for TGX;
- mocked FansGurus order payload tests;
- mocked TGX purchase/query tests;
- local checkout-to-queued-fulfillment test;
- admin retry test;
- multilingual route and cookie override test.

## Working Rule

When implementing, use `karpathy-guidelines`: keep changes small, explicit, and verified. Avoid building a new framework around Dujiao-Next.
