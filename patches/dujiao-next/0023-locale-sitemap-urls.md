# Dujiao-Next Patch 0023: Locale Sitemap URLs

Date: 2026-07-10

## Scope

Expands sitemap generation to include locale-prefixed public URL variants.

## Changes

- Adds locale-prefixed sitemap entries for `zh-CN`, `zh-TW`, and `en`.
- Covers static pages, categories, products, and published posts.
- Keeps existing unprefixed URLs in the sitemap.
- Extends sitemap service tests for localized product, category, and blog URLs.

## Verification

```bash
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go test ./internal/service -run TestSitemapService
```
