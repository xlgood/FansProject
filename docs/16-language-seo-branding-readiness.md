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

- Execute the production domain and branding checklist in
  `docs/17-production-domain-branding-checklist.md` once the final domain is
  known.
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

## Browser Smoke

Local services:

```bash
cd dujiao-next
GOPROXY=https://goproxy.cn,direct \
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go run ./cmd/server -mode api

cd user
VITE_API_BASE_URL=http://127.0.0.1:8080 ./node_modules/.bin/vite --host 127.0.0.1 --port 5173
```

Checked URLs:

- `http://127.0.0.1:5173/zh-CN`
- `http://127.0.0.1:5173/zh-TW/products`
- `http://127.0.0.1:5173/en/products`

Result:

- All checked locale URLs returned `200 OK`.
- Browser-rendered pages mounted Vue app content.
- `/zh-CN` set `html lang="zh-CN"` and saved locale `zh-CN`.
- `/zh-TW/products` set `html lang="zh-TW"` and saved locale `zh-TW`.
- `/en/products` set `html lang="en-US"` and saved locale `en-US`.
- Product pages rendered localized page titles:
  - `商品中心`
  - `Products`
- Canonical links stayed unprefixed.
- `hreflang` alternates were present for `zh-CN`, `zh-TW`, `en`, and
  `x-default`.
- `sitemap.xml` included locale-prefixed static URLs such as `/zh-CN`,
  `/zh-TW`, `/en`, and `/zh-CN/products`.

Finding fixed during smoke:

- Initial browser run failed before Vue mount with `TypeError: aliases is not
  iterable`.
- Cause: localized route copies set `alias: undefined`.
- Fix: omit the `alias` field on localized route copies instead of setting it
  to `undefined`.
