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

- Add locale-prefixed public routes such as `/zh-CN`, `/zh-TW`, and `/en`.
- Add canonical and `hreflang` metadata for locale variants.
- Decide the final primary domain and placeholder domain text replacement plan.
- Add production favicon/logo/OG image assets per domain once domains are known.
- Re-run browser smoke after locale-prefixed routing is implemented.

## Verification

```bash
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go test ./internal/http/handlers/public -run 'Test(LocaleFromCountryCode|ResolvePublicDefaultLocale)'

cd user && ./node_modules/.bin/vue-tsc -b
```
