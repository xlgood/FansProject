# Source Fit Plan

Date: 2026-07-08

This is the Phase 2 file-level implementation plan for integrating FansGurus
and TGX Account into the cloned Dujiao-Next codebase. It is based on source
inspection only. No upstream order or payment call was made.

## Decision

Use Dujiao-Next's existing upstream procurement abstraction as the integration
surface.

Dujiao-Next already has:

- `SiteConnection` for upstream credentials and markup settings.
- `ProductMapping` and `SKUMapping` for local-to-upstream SKU mapping.
- `ProductMappingService` for import, price sync, and stock sync.
- `ProcurementOrderService` for paid-order upstream submission, polling, retry,
  local fulfillment creation, and admin retry/cancel.
- Admin pages for site connections, product mappings, procurement orders, and
  payment channels.

The clean path is to add FansGurus and TGX Account as new upstream protocols,
then normalize their catalogs and orders into `internal/upstream.Adapter`.

## Required Source Changes

### Constants

Files:

- `dujiao-next/internal/constants/constants.go`

Add protocols:

- `fansgurus`
- `tgx-account`

Keep `dujiao-next` unchanged for existing B2B behavior.

### Upstream Adapters

Files:

- `dujiao-next/internal/upstream/adapter.go`
- `dujiao-next/internal/upstream/fansgurus.go`
- `dujiao-next/internal/upstream/tgx_account.go`
- `dujiao-next/internal/upstream/tgx_signer.go`
- `dujiao-next/internal/upstream/*_test.go`

Change `NewAdapter` to dispatch by `SiteConnection.Protocol`.

FansGurus adapter maps:

- `services` -> `ListProducts`
- one `service` id -> `GetProduct`
- `add` -> `CreateOrder`
- `status` -> `GetOrder`
- `balance` -> `Ping`

FansGurus API shape:

- Base endpoint: `POST https://fansgurus.com/api/v2`
- API key field: `key`
- Actions include `services`, `add`, `status`, `balance`
- Balance response includes USD currency
- `rate` is price per 1000 units. Keep this upstream quantity basis unchanged;
  calculate the local USD price using the connection's configured pricing rules.
  Preserve upstream min/max quantity and quantity-step semantics.

TGX adapter maps:

- `/shared/authentication/connect` -> `Ping`
- `/shared/commodity/items` -> `ListProducts`
- `/shared/commodity/item` -> `GetProduct`
- `/shared/commodity/inventory` and `/shared/commodity/inventoryState` -> stock
- `/shared/commodity/trade` -> `CreateOrder`
- `/shared/commodity/query` -> `GetOrder`

TGX API shape:

- Auth fields: `app_id`, `app_key`, `sign`
- Signature: remove `sign`, sort params by key, drop empty-string values, append
  `&key=<app_key>`, URL-decode, then MD5
- Product key: `shared_code`
- Product variation: `race`
- Idempotency key: `request_no`
- Delivered account payload: `secret`
- Widget fields must be passed as extra request params
- Price rule: local price = upstream `price` * 1.2

### Mapping IDs

Files:

- `dujiao-next/internal/models/product_mapping.go`
- `dujiao-next/internal/models/migrations.go`
- `dujiao-next/internal/repository/product_mapping_repository.go`
- `dujiao-next/internal/repository/sku_mapping_repository.go`
- affected service tests

Current mapping IDs are numeric:

- `ProductMapping.UpstreamProductID uint`
- `SKUMapping.UpstreamSKUID uint`
- `ProcurementOrder.UpstreamOrderID uint`

TGX needs string IDs:

- `shared_code`
- `race`
- `trade_no`

Do not overload numeric fields with hashes. Add string fields while keeping
existing numeric fields for Dujiao/FansGurus compatibility:

- `ProductMapping.UpstreamProductCode string`
- `SKUMapping.UpstreamSKUCode string`
- `ProcurementOrder.UpstreamOrderCode string`

Adapter usage:

- FansGurus can store numeric `service` in existing numeric fields and also copy
  it into string fields for display/debugging.
- TGX stores `shared_code` in product code and `shared_code|race` in SKU code.
  The numeric fields remain zero.

### Catalog Normalization

Files:

- `dujiao-next/internal/upstream/adapter.go`
- `dujiao-next/internal/service/product_mapping_import.go`
- `dujiao-next/internal/service/product_mapping_sync.go`
- `dujiao-next/internal/service/product_mapping_batch_import.go`

Keep the public `UpstreamProduct` shape but add optional string identity fields:

- `ExternalProductCode`
- `ExternalSKUCode`
- `Provider`
- `Platform`

Normalization rules:

- Exclude any upstream product/SKU where normalized title, platform, category,
  tags, code, or description contains Telegram-related terms.
- Apply the FansGurus and TGX allowlists separately after Telegram filtering.
- Only import active products whose platform is allowed for that provider.
- Store platform as a tag and/or a structured value in SEO/meta JSON until a
  dedicated platform field is added.

Platform aliases should normalize at least:

- `x`, `twitter` -> `x`
- `instagram`, `ig` -> `instagram`
- `tiktok`, `tik tok` -> `tiktok`
- `facebook`, `fb` -> `facebook`
- `youtube`, `yt` -> `youtube`

### Pricing

Files:

- `dujiao-next/internal/service/product_mapping_import.go`
- `dujiao-next/internal/service/product_mapping_sync.go`
- `dujiao-next/internal/service/product_mapping_markup.go`
- `dujiao-next/internal/service/price_markup.go`

Existing connection pricing supports the required administrator controls:

- FansGurus: use an exchange rate of `1`, then configure markup and rounding.
- TGX: configure the CNY-to-USD `exchange_rate`, then configure markup and
  rounding. Disable automatic price sync to retain a manually set SKU price.

FansGurus `rate` is per 1000 units. Do not normalize it to a one-unit price.
The adapter and product import must preserve the upstream quantity basis, so the
customer sees and buys on the same quantity scale as FansGurus. Import must also
preserve upstream minimum quantity, maximum quantity, and quantity increment or
step rules where the API exposes them.

Use USD target currency. If the upstream does not provide currency, normalize as
USD and document the assumption.

### Manual Form Schema

Files:

- `dujiao-next/internal/upstream/fansgurus.go`
- `dujiao-next/internal/upstream/tgx_account.go`
- `dujiao-next/internal/service/procurement_order_service.go`

FansGurus services need a target link/profile field. Represent as
`ManualFormSchemaJSON`, for example:

- `link` or `target_url`

TGX `widget` JSON should be converted into Dujiao manual form schema fields.
TGX `race` should be modeled as SKU selection, not a free-form field.

When submitting to upstream:

- FansGurus: pass manual form target value as `link`, plus quantity.
- TGX: pass manual widget submissions as extra POST params, plus `race`.

### Procurement

Files:

- `dujiao-next/internal/service/procurement_order_service.go`
- `dujiao-next/internal/models/procurement_order.go`
- `dujiao-next/internal/repository/procurement_order_repository.go`

Current procurement assumes numeric upstream order IDs. Extend it to use string
order codes for TGX:

- Store TGX `trade_no` in `UpstreamOrderCode`.
- Poll TGX using `tradeNo`.
- Keep `UpstreamOrderNo` as human-readable display if useful.

Fulfillment mapping:

- TGX delivered `secret` becomes `UpstreamFulfillment.Payload`.
- FansGurus completed orders should create a delivered fulfillment payload with
  a concise status summary.
- In-progress FansGurus statuses continue polling.
- Failed/canceled/refunded upstream statuses map to existing procurement failure
  or refund states.

### Queue Runtime

Files:

- `dujiao-next/internal/queue/tasks.go`
- `dujiao-next/internal/worker/asynq_worker.go`
- `dujiao-next/internal/worker/service.go`
- `dujiao-next/config.yml`

No new queue type is required for order fulfillment. Existing tasks cover:

- procurement submit
- procurement poll status
- procurement accepted-order periodic sync
- upstream stock sync

Phase 5 requires Redis/queue enabled. The Phase 1 API-only baseline is not
enough for end-to-end paid order fulfillment.

### Admin Frontend

Files:

- `admin/src/views/admin/SiteConnections.vue`
- `admin/src/views/admin/ProductMappings.vue`
- `admin/src/views/admin/ProcurementOrders.vue`
- `admin/src/api/types.ts`
- `admin/src/i18n/index.ts`

Minimum admin changes:

- Add protocol select options for `fansgurus` and `tgx-account`.
- Label credentials by protocol:
  - FansGurus: API key
  - TGX: app_id / app_key
- Show external product/SKU string codes in mapping detail.
- Keep existing procurement retry/cancel screens.

### User Frontend

Files:

- `user/src/api/product.ts`
- `user/src/composables/useProductList*.ts`
- `user/src/templates/vault/Products.vue`
- `user/src/templates/vault/ProductDetail.vue`
- `user/src/components/ProductCard.vue`
- `user/src/components/ProductQuickBuy.vue`

Minimum user changes:

- Platform navigation should be generated from active, provider-allowed SKUs.
- Hide all Telegram content and routes.
- Render Dujiao manual form schema for FansGurus link input and TGX widget
  fields.
- SKU selection should handle TGX `race` values as normal SKUs.

## Open Technical Risks

- Existing mapping tables are numeric-first; TGX requires string IDs. This is
  the biggest unavoidable model change.
- FansGurus quantity-basis handling needs explicit UI and validation support:
  pricing is per 1000 units, and upstream min/max/step rules must not be
  flattened to local one-unit pricing.
- FansGurus may support min/max quantity per service; import must map these to
  `MinPurchaseQuantity` and `MaxPurchaseQuantity`.
- TGX docs show prices in examples without explicit currency. Unless a live
  response proves otherwise, target settlement should remain USD by platform
  rule.
- Provider allowlists are explicit business policy. Do not infer an allowlist
  from the other provider's current catalog.
- Existing Telegram login/bot code remains in Dujiao-Next. The target website
  must hide Telegram products/services, but removing Telegram auth/bot internals
  is a separate hardening step if required.

## Test Plan

Backend tests:

- FansGurus client request construction and response parsing.
- FansGurus per-1000 price preservation and connection pricing.
- TGX signer against documented examples.
- TGX client request construction with string fields and widget params.
- Product import creates local product/SKU/mapping records.
- Telegram filter rejects product, SKU, category, tag, and description matches.
- Provider allowlists hide disallowed platforms.
- Procurement submit is idempotent and stores upstream order code.
- Procurement poll maps delivered, pending, canceled, and failed statuses.

Frontend checks:

- Site connection protocol selector includes all three protocols.
- Product list contains no Telegram entries.
- Platform navigation only shows active provider-allowed platforms.
- TGX race SKUs and widget fields render correctly.
- FansGurus target URL input is required before checkout.

Operational checks:

- Redis/queue enabled for fulfillment phases.
- Real credentials remain in local `.env` only.
- No real upstream order test without explicit approval.
