# Development Roadmap

This roadmap is the execution order for formal development.

## Phase 1: Local Dujiao-Next Baseline

Status: baseline verified on 2026-07-08. Details are recorded in
`docs/12-local-baseline.md`.

Goal: run the unmodified Dujiao-Next source locally before provider integration.

Tasks:

- Map root `.env` values to Dujiao-Next backend, user frontend, and admin frontend config.
- Start backend from `dujiao-next/`.
- Start user frontend from `user/`.
- Start admin frontend from `admin/`.
- Verify database and Redis requirements.
- Verify login, product list, order creation path, and payment configuration pages where possible.

Success criteria:

- Backend health/API endpoint responds locally.
- User frontend loads locally.
- Admin frontend loads locally.
- Required runtime config gaps are documented.

## Phase 2: Source Fit Plan

Goal: identify exact Dujiao-Next extension points before business changes.

Tasks:

- Inspect product, SKU, order, payment callback, fulfillment, upstream, and queue modules.
- Decide whether FansGurus/TGX adapters fit existing upstream/procurement abstractions.
- Produce a file-level implementation plan with required models, services, routes, workers, and admin screens.

Success criteria:

- Implementation plan names files/modules to change.
- Data model changes are explicit.
- Risky assumptions are called out before coding.

## Phase 3: Provider Clients

Goal: add isolated provider clients with tests and no real orders.

Tasks:

- FansGurus client: `services`, `balance`, `add`, `status`.
- TGX client: signing, authentication, items, inventory, trade, query.
- Mock upstream responses for tests.
- Redact secrets in errors/logs.

Success criteria:

- Signing and request construction are tested.
- Price parsing uses decimal math.
- No real upstream purchase is made.

## Phase 4: SKU Sync And Filtering

Goal: build the catalog pipeline.

Tasks:

- Store raw FansGurus and TGX catalog payloads.
- Normalize platforms.
- Exclude Telegram-related SKUs.
- Compute cross-provider platform intersection.
- Apply pricing:
  - FansGurus: upstream rate * 5.
  - TGX: `price` * 1.2.
- Map active SKUs into Dujiao-Next product/SKU structures.

Success criteria:

- Telegram SKUs are hidden.
- Non-intersection platforms are hidden.
- USD target prices are stored and reproducible.

## Phase 5: Order Fulfillment

Goal: connect paid local orders to upstream fulfillment.

Tasks:

- Queue upstream fulfillment after local payment success.
- Submit FansGurus orders and poll status.
- Submit TGX trades and store delivered secrets.
- Add retry and idempotency.
- Expose fulfillment status to customer and admin.

Success criteria:

- Paid order is not lost on upstream failure.
- Retry does not duplicate upstream orders.
- TGX delivered secrets are access-controlled.

## Phase 6: Frontend And Admin

Goal: make the integrated catalog usable.

Tasks:

- User frontend platform navigation from intersection platforms.
- Product detail forms from normalized provider schemas.
- Admin sync dashboard.
- Admin SKU mapping and disable controls.
- Admin upstream error and retry tools.

Success criteria:

- Customers cannot buy hidden or unsupported SKUs.
- Admin can diagnose sync and fulfillment failures.

## Phase 7: Language, SEO, And Branding

Goal: prepare public launch surface.

Tasks:

- Locale-prefixed routes for `zh-CN`, `zh-TW`, and `en`.
- IP-based first-visit language default.
- Manual language override.
- Sitemap and `hreflang`.
- Domain-driven favicon, logo, OG image, site name, and public text.

Success criteria:

- Each locale is directly accessible.
- Placeholder domains and assets are replaceable before launch.
- No Telegram or non-intersection platform pages are published.
