# Project Scope

## Goal

Build Website3 as a reseller storefront with all available Fansgurus SKUs, priced at 10x the upstream Fansgurus rate, using Dujiao-Next as the commerce/order foundation where practical.

## In Scope

- Mandatory build-vs-reuse review for new requirements.
- Fansgurus SKU sync.
- Fansgurus price sync.
- Website3 price calculation at 10x upstream rate.
- Custom frontend UI/UX.
- Desktop and mobile optimization.
- SEO/GEO landing page strategy.
- Simplified Chinese, Traditional Chinese, and English language support.
- IP-based first-visit default language detection with manual language switching.
- Order forwarding to Fansgurus after successful Website3 payment.
- Order status polling and customer-facing status updates.

## Out of Scope For This Repo Structure

- Vendoring Dujiao-Next source code.
- Storing real API keys.
- Real order placement without funded upstream balance and explicit approval.

## Open Decisions

- Whether the custom storefront should be SSR/SSG or a Vue SPA with prerendered landing pages.
- Whether the Fansgurus adapter should be embedded in Dujiao-Next backend or run as a separate sidecar worker.
- Which payment providers are required for launch.
- Which languages and countries are targeted first for SEO/GEO.
- Which GeoIP method will be used in production.
