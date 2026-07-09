# Admin Patch 0004: Procurement Error Diagnostics

## Purpose

Add operator-facing diagnostics for procurement order errors without changing
the stored raw error message or backend order state.

## Changes

- Adds a small error classifier in `src/views/admin/ProcurementOrders.vue`.
- Shows a diagnosis title, suggested action, and raw message in the procurement
  order list error card.
- Shows the same diagnosis block in the procurement order detail dialog.
- Adds Simplified Chinese, Traditional Chinese, and English translations for
  all diagnosis labels and next-action hints.

## Classified Cases

- Temporary submit unavailable.
- Product mapping missing.
- SKU mapping missing.
- Manual form or submitted field mismatch.
- Provider service/shared code configuration issue.
- Credential encryption/configuration issue.
- Site connection configuration issue.
- Balance/quota issue.
- Stock/inventory issue.
- Unsupported cancellation.
- Unknown fallback.

## Verification

- `cd admin && ./node_modules/.bin/vue-tsc -b`
- `cd admin && ./node_modules/.bin/vite build`

