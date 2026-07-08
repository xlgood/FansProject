# ADR 0003: Fansgurus Data Model And Adapter Contract

Date: 2026-07-07

## Status

Superseded by 2026-07-08 scope reset.

This ADR is preserved as historical context only. It covers a FansGurus-only adapter with outdated `* 10` pricing. Current implementation must follow `docs/02-upstream-apis.md`, `docs/03-sku-sync.md`, and `docs/05-requirements.md`.

## Context

Phase 2 starts from the Fansgurus-specific data model delta and adapter contract.
ADR 0002 found that Dujiao-Next already provides the commerce core, payment
callbacks, procurement order flow, and upstream adapter boundary.

Dujiao-Next uses GORM `AutoMigrate` in `internal/models/db.go`, so the first
backend implementation should add Go model structs and include them in
`AutoMigrate`, matching the existing project style.

Fansgurus exposes a pull-based SMM API at:

```text
https://fansgurus.com/api/v2
```

Known actions:

- `services`
- `balance`
- `add`
- `status`

Website3 launch pricing rule:

```text
sell_rate = upstream_rate * 10
```

## Decision

Add Fansgurus as a Dujiao-Next upstream protocol named `fansgurus`, backed by
Fansgurus-specific metadata tables and an adapter that implements Dujiao-Next's
existing `upstream.Adapter` interface.

Do not store Fansgurus-only service metadata only inside generic Product/SKU
JSON fields. Keep a normalized Fansgurus mapping table so sync, audit,
purchase-enable rules, and debugging remain reliable.

## Data Model Delta

### Reused Dujiao-Next Tables

Reuse these existing tables:

- `site_connections`
- `categories`
- `products`
- `product_skus`
- `product_mappings`
- `sku_mappings`
- `orders`
- `order_items`
- `payments`
- `procurement_orders`
- `fulfillments`

### New Table: `fansgurus_service_mappings`

Purpose:

- Store Fansgurus `services` rows and link them to Dujiao-Next catalog records.
- Preserve upstream metadata that Dujiao-Next generic product/SKU tables do not
  represent.
- Support change detection, audit, and purchase gating.

Fields:

```text
id
connection_id
upstream_service_id
local_product_id
local_sku_id
category_name
service_name
service_type
upstream_rate
sell_rate
min_quantity
max_quantity
supports_dripfeed
supports_refill
supports_cancel
raw_payload_json
content_hash
is_active
purchase_enabled
last_seen_at
created_at
updated_at
deleted_at
```

Suggested indexes:

```text
unique(connection_id, upstream_service_id)
index(local_product_id)
index(local_sku_id)
index(category_name)
index(service_type)
index(is_active)
index(purchase_enabled)
index(last_seen_at)
```

Money fields:

- `upstream_rate`: decimal/money type, rounded consistently with Dujiao-Next.
- `sell_rate`: decimal/money type.

Implementation note:

- Fansgurus rates are decimal strings. Parse with `shopspring/decimal`.
- Do not parse money with `float64`.
- If Dujiao-Next `models.Money` remains fixed to two decimals, confirm that
  Fansgurus rates do not require more precision before storing final cost data.

### New Table: `fansgurus_sync_runs`

Purpose:

- Record each `services` sync attempt.
- Keep audit history for sync quality, upstream failures, and catalog changes.

Fields:

```text
id
connection_id
status
started_at
finished_at
fetched_count
created_count
updated_count
deactivated_count
unsupported_count
error_count
response_bytes
error_message
created_at
updated_at
```

Suggested indexes:

```text
index(connection_id)
index(status)
index(started_at)
```

Allowed statuses:

```text
running
succeeded
failed
```

### Optional Later Table: `fansgurus_order_status_snapshots`

Do not add this table in the first implementation unless needed.

Use it only if operators need a full raw status-poll history for every upstream
order. The first implementation can store normalized procurement state in
`procurement_orders` and log raw status payloads for failures.

Potential fields:

```text
id
procurement_order_id
upstream_order_id
status
charge
start_count
remains
raw_payload_json
polled_at
created_at
```

## Adapter Contract

### Internal Fansgurus Client

Create a focused Fansgurus client used by the adapter.

Required methods:

```text
GetBalance(ctx) -> Balance
ListServices(ctx) -> []Service
AddOrder(ctx, AddOrderRequest) -> AddOrderResponse
GetOrderStatus(ctx, upstreamOrderID) -> OrderStatus
```

Optional later:

```text
GetBatchOrderStatus(ctx, upstreamOrderIDs)
RequestRefill(ctx, upstreamOrderID)
CancelOrder(ctx, upstreamOrderID)
```

Client rules:

- POST to `FANSGURUS_API_BASE_URL`.
- Send `key=<secret>` server-side only.
- Use timeouts:
  - `services`: 30 seconds
  - `add`: 20 seconds
  - `status`: 15 seconds
  - `balance`: 10 seconds
- Redact API key from logs.
- Distinguish auth/config errors, validation errors, upstream business errors,
  bad JSON, network errors, and timeouts.
- Treat empty `services` result as suspicious and fail the sync unless
  explicitly confirmed later.

### Dujiao-Next Upstream Adapter

Add a Fansgurus adapter that implements Dujiao-Next's existing
`upstream.Adapter`.

Mapping:

```text
Ping          -> Fansgurus balance
ListProducts  -> Fansgurus services transformed to Dujiao upstream products
GetProduct    -> one mapped Fansgurus service transformed to one product/SKU
CreateOrder   -> Fansgurus add
GetOrder      -> Fansgurus status
CancelOrder   -> unsupported unless Fansgurus cancel is confirmed
DownloadImage -> no-op or unsupported; Fansgurus services do not currently
                 provide product images
```

Important mismatch:

- Dujiao-Next upstream IDs are currently `uint`.
- Fansgurus `service` and order ids must be confirmed against real payloads.
- If they are larger than Go `uint` assumptions or are string-like, add a
  string external id field instead of forcing lossy conversion.

## SKU Sync Algorithm

One sync run should:

1. Acquire a lock per Fansgurus connection.
2. Create a `fansgurus_sync_runs` row with `running`.
3. Call `services`.
4. Validate every service has required fields:
   - `service`
   - `name`
   - `type`
   - `rate`
   - `min`
   - `max`
   - `category`
5. Normalize each service.
6. Compute a stable `content_hash` from fields that affect display, order
   validation, price, and purchase support.
7. Calculate `sell_rate = upstream_rate * 10` with decimal arithmetic.
8. Upsert `fansgurus_service_mappings`.
9. Create or update Dujiao-Next category/product/SKU records.
10. Create or update `product_mappings` and `sku_mappings`.
11. Generate `ManualFormSchemaJSON` from the Fansgurus service type.
12. Set `purchase_enabled=false` for unsupported service types.
13. Mark missing services inactive after a grace period.
14. Finish the sync run with counts and status.

Locking:

- Prefer Redis lock if Dujiao-Next Redis is enabled.
- Fall back to database-level locking or a sync-run guard if Redis is disabled.
- Never run two full Fansgurus syncs for the same connection concurrently.

## Service Type To Manual Form Mapping

Dujiao-Next manual form supports:

```text
text
textarea
phone
email
number
select
radio
checkbox
```

Use these initial mappings.

### `Default`

Purchase enabled: yes.

Fields:

```text
link: text, required
```

Fansgurus `add` payload:

```text
action=add
service=<upstream_service_id>
link=<link>
quantity=<quantity>
```

### `Custom Comments`

Purchase enabled: yes.

Fields:

```text
link: text, required
comments: textarea, required
```

Fansgurus `add` payload:

```text
action=add
service=<upstream_service_id>
link=<link>
comments=<comments>
```

Quantity rule:

- Confirm whether Fansgurus expects `quantity` for this type or derives quantity
  from comment line count.
- Until confirmed, derive quantity from non-empty comment lines for validation
  but do not assume final upstream payload behavior in code.

### `Poll`

Purchase enabled: yes after payload is confirmed.

Fields:

```text
link: text, required
answer_number: number, required
```

Potential Fansgurus `add` payload:

```text
action=add
service=<upstream_service_id>
link=<link>
quantity=<quantity>
answer_number=<answer_number>
```

Open point:

- Confirm the exact Fansgurus field name for poll answer selection before
  enabling production purchase.

### `Mentions`

Purchase enabled: yes after payload is confirmed.

Fields:

```text
link: text, required
usernames: textarea, required
```

Potential Fansgurus `add` payload:

```text
action=add
service=<upstream_service_id>
link=<link>
usernames=<usernames>
```

Quantity rule:

- Confirm whether quantity is explicit or derived from username line count.

### Unsupported Types

Purchase enabled: no.

Behavior:

- Sync the service.
- Show it to admin.
- Keep it inactive or not purchasable on storefront.
- Record unsupported service type counts in `fansgurus_sync_runs`.

## Order Status Mapping

Fansgurus status values should be normalized case-insensitively.

Initial mapping:

```text
Completed       -> delivered / fulfilled
Partial         -> partially_refunded or fulfilled with remains, confirm policy
Processing      -> accepted, keep polling
In progress     -> accepted, keep polling
Pending         -> accepted, keep polling
Canceled        -> canceled
Refunded        -> refunded
```

Persist if available:

```text
charge
start_count
remains
currency
raw status payload for error/debug paths
```

## Error Policy

Retryable:

- Network failure.
- Timeout.
- HTTP 5xx if Fansgurus ever returns HTTP status codes.
- Temporary invalid JSON only for status/order calls, not full catalog sync.

Non-retryable:

- Invalid API key.
- Insufficient balance.
- Invalid service id.
- Quantity outside min/max.
- Unsupported service type.
- Missing required customer input.

Catalog sync safety:

- Do not deactivate all services if `services` returns invalid JSON.
- Do not deactivate all services on network failure.
- Do not treat an empty service list as a successful full sync by default.

## First Implementation Slice

The first code slice should be backend-only and small:

1. Add constants and model structs:
   - `ConnectionProtocolFansgurus`
   - `FansgurusServiceMapping`
   - `FansgurusSyncRun`
2. Add the models to Dujiao-Next `AutoMigrate`.
3. Implement decimal price calculation for `rate * 10`.
4. Implement manual form schema generation for the four initial service types.
5. Add unit tests for:
   - price multiplier
   - content hash stability
   - service type support gating
   - manual form schema generation

Only after that should the HTTP client and live sync worker be implemented.

## Verification Targets

Before considering Phase 2 complete:

- Migration applies cleanly on a fresh SQLite database.
- Migration applies cleanly on a fresh PostgreSQL database or is documented as
  pending if local PostgreSQL is unavailable.
- Unit tests pass for Fansgurus normalization and price calculation.
- No Fansgurus API key appears in frontend code or committed files.
- Unsupported service types cannot be purchased.
