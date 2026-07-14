# SEO, GEO, And Language Plan

## Supported Locales

- Simplified Chinese: `zh-CN`
- Traditional Chinese: `zh-TW`
- English: `en`

## URL Strategy

Use explicit locale prefixes:

- `/zh-CN/...`
- `/zh-TW/...`
- `/en/...`

Every public page should have stable language-specific URLs.

## Initial Language Selection

Priority:

1. Existing user-selected language cookie or user profile setting.
2. Explicit URL locale prefix.
3. IP geolocation:
   - Mainland China -> `zh-CN`
   - Taiwan, Hong Kong, Macau -> `zh-TW`
   - other regions -> `en`
4. `Accept-Language` fallback:
   - `zh-CN`, `zh-SG`, simplified Chinese preference -> `zh-CN`
   - `zh-TW`, `zh-HK`, `zh-MO`, traditional Chinese preference -> `zh-TW`
5. Default: `en`

IP detection should redirect only first-time non-prefixed entry requests. It must not block users or crawlers from directly accessing other locale URLs.

## SEO Requirements

- Server-render or prerender important landing pages.
- Generate multilingual XML sitemaps.
- Add canonical URLs.
- Add `hreflang` alternates for each locale page.
- Avoid making duplicated thin pages.
- Do not rely only on upstream SKU names as page content.
- Keep Telegram-related pages out of sitemap and navigation.

## Page Groups

- Home page.
- Platform landing pages, only for active platforms with provider-allowed SKUs.
- Service intent pages:
  - buy followers;
  - buy likes;
  - buy views;
  - buy social accounts;
  - account packages by platform.
- SKU detail pages for active SKUs.
- FAQ pages.
- Terms, privacy, refund/service policy.
- Payment and order status pages.

## GEO Content Rules

GEO pages may target language or region intent, but they must remain true to available inventory:

- do not create platform pages for platforms with no active provider-allowed SKUs;
- do not create Telegram pages;
- do not imply guaranteed third-party platform outcomes unless upstream explicitly guarantees them;
- disclose delivery method, refill/cancel support, and after-sales scope per SKU where available.

## Compliance And Risk Notes

The target site operates in a sensitive category: social growth services and account sales may violate some third-party platform terms. Public copy and policies should avoid deceptive claims, impersonation claims, or guarantees that cannot be fulfilled. Admin should be able to disable risky SKUs quickly.
