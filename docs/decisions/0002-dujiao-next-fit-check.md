# ADR 0002: Dujiao-Next Fit Check And Fansgurus Integration Map

Date: 2026-07-07

## Status

Accepted

## Context

Phase 1 requires checking Dujiao-Next before writing custom Website3 code.

Dujiao-Next was cloned outside this repository for source review:

```text
/private/tmp/dujiao-next-phase1
```

The source is intentionally not vendored into this repository.

Repository verified:

- GitHub: `https://github.com/dujiao-next/dujiao-next`
- Backend language: Go
- Frameworks and core libraries: Gin, GORM, Redis, Asynq, Viper,
  `shopspring/decimal`
- Databases: SQLite and PostgreSQL
- License: GPL-3.0
- Current source review date: 2026-07-07

The `find-skills` skill is installed, but `npx skills find fansgurus dujiao
integration` could not complete in this environment because npm registry DNS
resolution failed. This limitation is recorded rather than skipped.

## Findings

### Dujiao-Next Is A Fit For Commerce Core

Dujiao-Next already provides these Website3-relevant modules:

- Products and SKUs:
  - `internal/models/product.go`
  - `internal/models/product_sku.go`
  - `internal/service/product_service.go`
- Categories:
  - `internal/models/category.go`
  - `internal/service/category_service.go`
- Orders and order items:
  - `internal/models/order.go`
  - `internal/models/order_item.go`
  - `internal/service/order_service.go`
- Payment callbacks and idempotent payment handling:
  - `internal/service/payment_service_callback.go`
  - `internal/payment/provider/`
- Fulfillment records:
  - `internal/models/fulfillment.go`
  - `internal/service/fulfillment_service.go`
- Upstream product mapping:
  - `internal/models/product_mapping.go`
  - `internal/service/product_mapping_service.go`
  - `internal/service/product_mapping_sync.go`
- Procurement orders and upstream order polling:
  - `internal/models/procurement_order.go`
  - `internal/service/procurement_order_service.go`
- Redis/Asynq worker tasks:
  - `internal/queue/tasks.go`
  - `internal/worker/asynq_worker.go`
- Public, admin, channel, and upstream APIs:
  - `internal/router/router.go`
  - `internal/http/handlers/public/`
  - `internal/http/handlers/admin/`
  - `internal/http/handlers/channel/`
  - `internal/http/handlers/upstream/`
- i18n:
  - `internal/i18n/messages.go`
  - `internal/constants/constants.go`

The existing payment flow is especially important for Website3. When a payment
callback succeeds, Dujiao-Next updates the payment and order state idempotently,
then enqueues follow-up work. Orders containing upstream fulfillment items are
handed to `ProcurementOrderService.CreateForOrder`, which creates a procurement
record and queues upstream submission.

This matches Website3's requirement:

- Create local order first.
- Treat Dujiao-Next payment state as source of truth.
- After payment success, submit to upstream asynchronously.
- Poll upstream status until terminal state.
- Keep an audit trail.

### Existing Upstream Adapter Boundary

Dujiao-Next already defines an upstream adapter interface in
`internal/upstream/adapter.go`.

The interface includes:

- `Ping`
- `ListCategories`
- `ListProducts`
- `GetProduct`
- `CreateOrder`
- `GetOrder`
- `CancelOrder`
- `DownloadImage`

Current `NewAdapter` only supports the `dujiao-next` protocol through
`constants.ConnectionProtocolDujiaoNext`.

This means Fansgurus should be added as a new upstream protocol/provider instead
of replacing the order, payment, worker, or procurement flow.

### Existing Price Infrastructure

Dujiao-Next already uses decimal-safe money handling:

- `internal/models/money.go`
- `github.com/shopspring/decimal`

Dujiao-Next also has upstream connection price conversion and markup helpers in
`internal/service/price_markup.go`. Its markup model is percentage-based:

```text
local price = upstream price * exchange rate * (1 + markup_percent / 100)
```

Website3's fixed launch rule is:

```text
website3_rate = fansgurus_rate * 10
```

This can be represented as a 900 percent markup, but the implementation should
still name the business rule clearly as `PRICE_MULTIPLIER=10` or equivalent.
Using only a generic `PriceMarkupPercent=900` setting would be easy to misread
or misconfigure.

### Existing Manual Form Support

Fansgurus service types require different customer inputs. Dujiao-Next already
supports manual form schemas and stores submitted form data on order items:

- `Product.ManualFormSchemaJSON`
- `OrderItem.ManualFormSchemaSnapshotJSON`
- `OrderItem.ManualFormSubmissionJSON`
- `internal/service/manual_form_validator.go`

For Website3, Fansgurus service types should be mapped into Dujiao-Next manual
form schemas. Initial purchasable types:

- `Default`
- `Custom Comments`
- `Poll`
- `Mentions`

Unsupported Fansgurus service types should still sync into the catalog, but be
disabled for purchase until their form-to-payload mapping is defined.

### Locale Difference

Website3 requirements currently name supported public locales as:

- `en`
- `zh-CN`
- `zh-TW`

Dujiao-Next constants currently use:

- `zh-CN`
- `zh-TW`
- `en-US`

Decision: keep Website3 public URLs as `/en/`, `/zh-CN/`, and `/zh-TW/`, and
map `/en/` to Dujiao-Next's internal `en-US` locale at the API/frontend boundary
unless a later storefront decision chooses to align everything to `en-US`.

## Decision

1. Reuse Dujiao-Next as the commerce core for products, SKUs, orders, payments,
   admin APIs, fulfillment records, procurement records, and workers.
2. Implement Fansgurus as a Dujiao-Next upstream adapter/protocol rather than a
   separate order core.
3. Add a new protocol constant conceptually named `fansgurus`.
4. Extend `upstream.NewAdapter` to select a Fansgurus adapter when a connection
   uses the `fansgurus` protocol.
5. Reuse `ProductMapping`, `SKUMapping`, `SiteConnection`, and
   `ProcurementOrder` where possible.
6. Add Website3/Fansgurus-specific fields only where existing Dujiao-Next tables
   cannot represent required data, such as Fansgurus service type, min/max
   quantity, drip-feed/refill/cancel flags, raw upstream service payload, and a
   content hash.
7. Reuse the existing Asynq worker chain for paid-order procurement submission
   and polling.
8. Keep Fansgurus API keys in server-side connection/config storage only.
9. Keep the fixed launch price rule explicit as multiplier `10`, using decimal
   arithmetic.
10. Keep Dujiao-Next source external. This repository should store integration
    decisions and Website3-specific code or patch notes, not vendored upstream
    source.

## Integration Map

### Catalog Sync

Use or extend:

- `SiteConnection` for Fansgurus provider credentials and base URL.
- `ProductMapping` for local product to upstream service mapping.
- `SKUMapping` for local SKU to upstream service/SKU mapping.
- `Product` and `ProductSKU` for customer-facing catalog records.
- `ProductMappingService` or a Website3 sync service for full Fansgurus service
  import.

Required Fansgurus-specific additions:

- Store upstream service id from `service`.
- Store Fansgurus `type`.
- Store `rate` as upstream cost.
- Store Website3 sell rate as `rate * 10`.
- Store `min`, `max`, `dripfeed`, `refill`, `cancel`, `category`, raw payload,
  content hash, last seen timestamp, active/purchase-enabled status.
- Generate a manual form schema per supported Fansgurus service type.
- Mark unsupported service types not purchasable.
- Mark missing services inactive after a grace period instead of deleting them.

### Order Submission

Reuse:

- `PaymentService.HandleCallback`
- `PaymentService.enqueueProcurementAsync`
- `ProcurementOrderService.CreateForOrder`
- `ProcurementOrderService.SubmitToUpstream`
- `queue.TaskProcurementSubmit`

Fansgurus adapter work:

- Translate Dujiao-Next `CreateUpstreamOrderReq` into Fansgurus `action=add`.
- Build the Fansgurus payload from `ManualFormData` and service type.
- Return upstream order id and upstream charge.
- Treat upstream validation/configuration errors as non-retryable.
- Treat network/timeouts as retryable.

Open implementation detail:

- Fansgurus order ids may exceed or not fit Dujiao-Next's current `uint`
  `UpstreamOrderID` assumptions. Confirm with real payloads before coding.

### Status Polling

Reuse:

- `ProcurementOrderService.PollUpstreamStatus`
- `ProcurementOrderService.SyncAcceptedOrders`
- `queue.TaskProcurementPollStatus`
- `queue.TaskProcurementSyncAccepted`

Fansgurus adapter work:

- Translate `GetOrder` to Fansgurus `action=status`.
- Map Fansgurus statuses into Dujiao-Next procurement statuses:
  - completed/delivered -> fulfilled/delivered
  - canceled -> canceled
  - refunded/partial -> refunded or partially_refunded, if upstream exposes it
  - pending/in progress/processing -> accepted and keep polling
- Store upstream charge, start count, remains, and raw status payload if needed.

### Storefront

Dujiao-Next exposes public catalog/order/payment APIs, but Website3 still needs a
custom SEO storefront.

Recommended direction:

- Build a separate SSR/SSG-capable storefront in `apps/storefront/`.
- Fetch normalized catalog/order APIs from Dujiao-Next or a Website3 API layer.
- Do not call Fansgurus from browser code.
- Keep public locale prefixes as `/en/`, `/zh-CN/`, and `/zh-TW/`.
- Map public `/en/` to internal `en-US` where Dujiao-Next APIs expect it.

### Admin

Reuse Dujiao-Next admin concepts for:

- Product/category management.
- Payment channel management.
- Procurement order visibility.
- Manual retry/cancel.
- Site connections.

Website3-specific admin additions likely needed:

- Fansgurus sync run history.
- Fansgurus service payload inspection.
- Unsupported service type visibility.
- Purchase-enabled toggles by service/category.
- Price multiplier visibility.

## Gaps And Risks

- `find-skills` search could not complete because npm registry DNS failed in the
  current environment.
- Dujiao-Next currently supports only the `dujiao-next` upstream protocol in
  `upstream.NewAdapter`; Fansgurus requires a new adapter.
- Dujiao-Next internal English locale is `en-US`, while Website3 public
  requirement says `en`.
- Fansgurus service type payload requirements must be explicitly mapped before
  enabling purchase.
- Dujiao-Next existing upstream product list shape is product/SKU-oriented;
  Fansgurus `services` is a flat service list, so import code must normalize
  categories/products/SKUs carefully.
- License implications of modifying and distributing GPL-3.0 Dujiao-Next must be
  reviewed before production distribution.
- The initial baseline check did not report a Git repository, but the current
  workspace now has Git metadata and `git status` is available.

## Next Implementation Step

Phase 2 should start with the Fansgurus data model delta and adapter design,
not with frontend UI.

Minimum next deliverable:

1. Draft the exact schema/migration additions required for Fansgurus service
   metadata and sync runs.
2. Draft the Fansgurus adapter method contract:
   - `ListServices`
   - `AddOrder`
   - `GetOrderStatus`
   - optional `GetBalance`
3. Define the service type to manual form schema mapping for:
   - `Default`
   - `Custom Comments`
   - `Poll`
   - `Mentions`
4. Decide whether the first implementation patches Dujiao-Next directly outside
   this repository or builds a Website3 sidecar that writes to the same database.

Recommended first implementation path:

```text
Dujiao-Next backend extension + Asynq worker reuse
```

This is simpler than a separate sidecar because Dujiao-Next already owns payment
callbacks, procurement records, retries, polling, and admin visibility.
