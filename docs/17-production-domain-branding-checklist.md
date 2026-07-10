# Production Domain And Branding Checklist

Date: 2026-07-10

## Purpose

Make the final domain, brand assets, public text, and SEO metadata replaceable
before launch without changing code.

## Configuration Sources

Primary site configuration is stored in Dujiao-Next setting key
`site_config`.

The public frontend consumes these values through:

- `GET /api/v1/public/config`
- frontend `appStore.config`
- frontend `usePageSeo()`
- frontend favicon/head handling in `user/src/stores/app.ts`

Reseller or domain-specific storefronts can overlay the primary config through
`reseller_site_configs` when a request resolves to a reseller tenant.

## Primary Domain Inputs

Decide these before launch:

- Primary public domain, for example `https://example.com`.
- Whether `www` redirects to apex or apex redirects to `www`.
- Whether locale-prefixed URLs stay under the same domain:
  - `/zh-CN`
  - `/zh-TW`
  - `/en`
- CDN/proxy country header source for first-visit locale:
  - `CF-IPCountry`
  - `CloudFront-Viewer-Country`
  - `X-Vercel-IP-Country`
  - `X-Country-Code`

## Main Site Config Fields

Set these in `site_config` for the primary domain:

```json
{
  "brand": {
    "site_name": "FINAL_SITE_NAME",
    "site_url": "https://FINAL_DOMAIN",
    "site_icon": "/uploads/brand/favicon.png",
    "site_description": {
      "zh-CN": "",
      "zh-TW": "",
      "en-US": ""
    }
  },
  "seo": {
    "title": {
      "zh-CN": "",
      "zh-TW": "",
      "en-US": ""
    },
    "keywords": {
      "zh-CN": "",
      "zh-TW": "",
      "en-US": ""
    },
    "description": {
      "zh-CN": "",
      "zh-TW": "",
      "en-US": ""
    },
    "default_og_image": "/uploads/brand/og-default.png"
  },
  "contact": {
    "telegram": "",
    "whatsapp": ""
  },
  "footer_links": [],
  "nav_config": {
    "builtin": {
      "blog": true,
      "notice": true,
      "about": true
    },
    "custom_items": []
  }
}
```

Notes:

- `brand.site_url` drives sitemap and canonical fallback. It must be absolute,
  HTTPS, and have no trailing slash.
- `brand.site_icon` drives frontend favicon. If empty, frontend falls back to
  `/dj.svg`.
- `seo.title`, `seo.description`, and `seo.keywords` are localized by
  `zh-CN`, `zh-TW`, and `en-US`.
- `seo.default_og_image` is used as the fallback Open Graph image.
- Public user-facing text must not mention upstream providers or API routing.

## Required Assets

Prepare production files before launch:

- Favicon:
  - PNG or ICO.
  - Square, at least `512x512`.
  - Transparent background preferred.
- Header/logo image:
  - PNG, WebP, or SVG if the asset is already vector-native.
  - Must work on light and dark backgrounds.
- Default OG image:
  - `1200x630`.
  - Contains final brand name and generic storefront value proposition.
  - No upstream provider names.
- Optional social/share variants:
  - Square `1200x1200`.
  - Locale-specific text variants if marketing wants different copy.

Allowed asset URL formats:

- Uploaded local path: `/uploads/...`
- Absolute HTTPS URL: `https://...`

For reseller/domain overlays, image fields currently accept `/uploads/...` or
absolute `http(s)` URLs. Prefer `/uploads/...` for operational control.

## Contact And Public Text

Before launch, replace placeholders:

- Support email.
- WhatsApp link, if used:
  - `https://wa.me/...`
  - `https://api.whatsapp.com/...`
- Telegram support links should remain disabled unless business explicitly
  wants support over Telegram. Telegram SKUs remain excluded either way.
- About page localized content.
- Terms of service.
- Privacy policy.
- Footer custom links.
- Blog/notice launch posts, if enabled.

## Multi-Domain Overlay Fields

For each reseller or future domain-specific storefront, configure:

- `site_name`
- `logo`
- `favicon`
- `support`
  - `telegram`
  - `whatsapp`
  - `email`
  - `support_url`
- `seo`
  - localized `title`
  - localized `keywords`
  - localized `description`
  - `default_og_image`
- `footer_links`
- `nav_config`
- `announcement`, if needed

Validation constraints already enforced by backend:

- Images: `/uploads/...`, `http://...`, or `https://...`.
- Support URL/footer links: HTTPS, `mailto:...`, or `tg://...`.
- WhatsApp: `https://wa.me/...` or `https://api.whatsapp.com/...`.
- Telegram: `https://t.me/...` or `tg://...`.
- Locales: `zh-CN`, `zh-TW`, `en-US`.

## Launch Verification

Run after final domain and assets are configured:

```bash
curl -I https://FINAL_DOMAIN/
curl -I https://FINAL_DOMAIN/zh-CN
curl -I https://FINAL_DOMAIN/zh-TW/products
curl -I https://FINAL_DOMAIN/en/products
curl -i https://FINAL_DOMAIN/api/v1/public/config
curl -i https://FINAL_DOMAIN/sitemap.xml
curl -i https://FINAL_DOMAIN/robots.txt
```

Browser checks:

- Home page renders with final logo/favicon.
- Product list renders in all three locale URL variants.
- `html lang` matches active locale.
- Canonical links use the final domain.
- `hreflang` alternates use the final domain and correct locale paths.
- `sitemap.xml` uses the final domain, not localhost or a temporary domain.
- Open Graph image URL loads with HTTP `200`.
- Payment checkout pages show final brand name and support links.

## Rollback Criteria

Do not launch if any of these are true:

- `brand.site_url` is empty or points at localhost/staging.
- Favicon or OG image returns `404`.
- Public pages mention upstream providers, API routing, or internal
  procurement wording.
- Telegram SKUs are visible in catalog or navigation.
- Sitemap publishes non-intersection platform pages.
- Locale URL variants return `404` or render the wrong language.
- Payment channel branding still shows placeholder merchant information.
