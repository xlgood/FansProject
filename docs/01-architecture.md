# Architecture

## Baseline

Dujiao-Next is the foundation. Its official docs describe a split architecture:

- `api/`: Go + Gin + GORM backend.
- `user/`: Vue 3 + Vite + TypeScript storefront.
- `admin/`: Vue 3 + Vite + TypeScript admin.
- `Document/`: VitePress docs.

The target platform should extend that architecture rather than introduce a parallel commerce stack.

## Recommended Shape

```text
Browser
  |
  | /zh-CN, /zh-TW, /en
  v
Dujiao-Next User Frontend
  |
  | /api/v1
  v
Dujiao-Next API
  |
  +-- Local database: products, SKUs, orders, payments, upstream mappings
  +-- Queue/worker: sync jobs, fulfillment jobs, status polling
  +-- Provider adapter: FansGurus
  +-- Provider adapter: TGX Account
  |
  +--> FansGurus API
  +--> TGX Shared API
```

## Core Modules To Add Or Extend

- Provider credentials management:
  - server-side only;
  - encrypted at rest using Dujiao-Next secret facilities where available.
- Provider catalog sync:
  - `fansgurus_services_sync`;
  - `tgx_items_sync`;
  - platform normalization;
  - Telegram exclusion;
  - provider-specific allowlist evaluation.
- Unified catalog:
  - platform;
  - provider;
  - upstream ID/code;
  - upstream price;
  - target price;
  - raw payload;
  - active/inactive state;
  - purchase form schema.
- Fulfillment worker:
  - after local payment success;
  - create upstream order;
  - store upstream order number;
  - poll or query upstream status;
  - deliver returned card/account secret for TGX automatic delivery.
- Admin tools:
  - sync status;
  - provider SKU mapping;
  - exclusion and override rules;
  - failed fulfillment retry;
  - upstream error logs.

## Data Flow

1. Scheduled jobs pull FansGurus and TGX catalogs.
2. Each provider adapter stores raw payloads and normalized provider SKUs.
3. A normalization job extracts platform names and removes Telegram-related SKUs.
4. The system applies each provider's explicit allowlist after Telegram exclusion.
5. Only active, provider-allowed SKUs become storefront-visible.
6. Connection price settings calculate local USD prices; manual SKU prices can be retained.
7. Customer creates a local Dujiao-Next order and pays locally.
8. Payment callback marks the local order paid.
9. Queue worker sends the fulfillment request to FansGurus or TGX.
10. Worker stores upstream IDs, returned card/account secrets, and status changes.
11. Customer and admin see local status plus upstream-derived status.

## Why Not Direct Frontend API Calls

Upstream APIs require secrets. Browser calls would expose API keys, make SEO and checkout depend on third-party availability, and prevent durable retry/idempotency. All upstream calls must stay server-side.

## Runtime Dependencies

- Go runtime matching Dujiao-Next backend requirements.
- Node.js 20 LTS or newer for frontend/admin.
- PostgreSQL for production.
- Redis for queue, cache, rate limiting, and async fulfillment.
- HTTPS endpoints for payment callbacks and any upstream callbacks.

## Deployment Shape

Production should use:

- one public storefront domain;
- one admin domain or protected admin path;
- reverse proxy to Dujiao-Next API;
- PostgreSQL;
- Redis;
- background worker enabled;
- explicit CORS allowlist;
- provider API keys only in server-side config or encrypted admin settings.
