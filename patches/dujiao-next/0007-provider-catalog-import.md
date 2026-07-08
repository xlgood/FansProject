# Patch 0007: Provider Catalog Import

Date: 2026-07-08

Source tree:

```text
dujiao-next/
```

## Purpose

This patch adds the base persistence layer for filtered FansGurus/TGX catalog
items. It imports already-filtered catalog policy output into Dujiao-Next local
tables, without making live upstream API calls.

## Scope

Model and repository changes:

- Add `ProductMapping.UpstreamProductCode`.
- Add `ProductMapping.Provider`.
- Add `ProductMapping.Platform`.
- Add `SKUMapping.UpstreamSKUCode`.
- Add repository lookup by upstream product code.
- Add repository lookup by upstream SKU code.

Import service:

- `ProductMappingService.ImportProviderCatalog`
- Creates platform categories such as `platform-instagram`.
- Creates local mapped products as inactive by default.
- Creates one SKU per provider catalog item for the base import.
- Stores provider/platform/code metadata in product and SKU mappings.
- Skips duplicate mappings by `connection_id + upstream_product_code`.

## Verification

Passed:

```text
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/service -run 'TestImportProviderCatalog'
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/upstream
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/repository -run 'TestSQLDialect|TestProduct'
```

## Limitations

This is the base import path only.

Still pending:

- raw upstream payload persistence;
- TGX `config` race parsing into multiple SKUs;
- TGX widget schema conversion;
- live FansGurus/TGX catalog pull job;
- deactivation of previously imported items that disappear, become Telegram
  matches, or leave the platform intersection.
