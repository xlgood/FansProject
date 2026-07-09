# Patch 0001: Provider Fulfillment Error Message

Date: 2026-07-09

Source tree:

```text
user/
```

## Purpose

This patch shows a localized customer-facing message when fulfillment submission
cannot be completed temporarily.

## Scope

- Adds `fulfillmentErrorText()` to shared order display helpers.
- Shows `order.fulfillment_error` on classic signed-in order detail.
- Shows `order.fulfillment_error` on classic guest order detail.
- Shows `order.fulfillment_error` once in the shared vault order body.
- Adds Simplified Chinese, Traditional Chinese, and English messages that do not
  mention internal technical details.

The UI does not mention manual confirmation or raw internal errors.

## Verification

Passed:

```text
cd user && ./node_modules/.bin/vue-tsc -b
cd user && ./node_modules/.bin/vite build
```

Build note:

- Vite emitted existing third-party Browserslist/Rollup annotation warnings; the
  build completed successfully.
