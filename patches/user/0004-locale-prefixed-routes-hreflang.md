# User Frontend Patch 0004: Locale-Prefixed Routes And Hreflang

Date: 2026-07-10

## Scope

Adds public locale URL variants and SEO alternates in the user frontend.

## Changes

- Adds locale path mapping for `zh-CN`, `zh-TW`, and `en`.
- Adds localized copies of public routes before the catch-all route.
- Syncs active frontend locale from locale-prefixed URLs.
- Emits canonical and `hreflang` alternate links from page SEO metadata.
- Keeps canonical URLs unprefixed.
- Normalizes locale route names for product/category page title logic.

## Verification

```bash
cd user && ./node_modules/.bin/vue-tsc -b
```
