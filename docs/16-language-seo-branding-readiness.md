# Language, SEO, And Branding Readiness

Date: 2026-07-10

## Scope

Start Phase 7 by making first-visit language selection deployment-ready and
recording the remaining launch-surface work.

## Completed

- Backend public config now returns `default_locale`.
- Default locale is resolved from common edge/CDN country headers first:
  - `CF-IPCountry`
  - `CloudFront-Viewer-Country`
  - `X-Vercel-IP-Country`
  - `X-Country-Code`
- Country mapping currently routes:
  - `CN` to `zh-CN`
  - `HK`, `MO`, `TW` to `zh-TW`
  - common English-region country codes to `en-US`
- If no country header is available, backend falls back to existing
  `Accept-Language` handling.
- User frontend applies `default_locale` only when the visitor has not already
  selected and saved a language manually.
- Manual language override continues to use `localStorage.locale`.
- User frontend now supports locale-prefixed public routes:
  - `/zh-CN`
  - `/zh-TW`
  - `/en`
- Locale-prefixed variants are also available for public child pages such as
  products, categories, product detail, blog, notice, and static content pages.
- Visiting a locale-prefixed route updates the active frontend locale.
- Page SEO now emits canonical links plus `hreflang` alternates for `zh-CN`,
  `zh-TW`, `en`, and `x-default`.
- Canonical URLs stay unprefixed so the current primary URL structure remains
  stable.
- Sitemap generation now includes unprefixed and locale-prefixed variants for
  public static pages, categories, products, and posts.

## Existing Capabilities Confirmed

- Frontend already has `zh-CN`, `zh-TW`, and `en-US` language packs.
- Frontend already sends `X-Lang` on API requests.
- Backend already supports `X-Lang`, query `lang`, and `Accept-Language` for
  response localization.
- Public config already exposes configurable site branding and SEO data.
- Frontend already applies site title, description, keywords, favicon, and page
  SEO metadata through reactive head management.
- Backend already exposes `/sitemap.xml` and `/robots.txt`.
- Reseller/domain site config already has fields for site name, logo, favicon,
  support, SEO, footer links, and navigation config.

## Remaining

- Decide the final primary domain and placeholder domain text replacement plan.
- Add production favicon/logo/OG image assets per domain once domains are known.
- Re-run browser smoke on locale-prefixed URLs before production launch.

## Verification

```bash
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go test ./internal/http/handlers/public -run 'Test(LocaleFromCountryCode|ResolvePublicDefaultLocale)'

cd user && ./node_modules/.bin/vue-tsc -b

GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go test ./internal/service -run TestSitemapService
```
