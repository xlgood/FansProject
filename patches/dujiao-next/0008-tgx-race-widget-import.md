# Patch 0008: TGX Race And Widget Import

Date: 2026-07-08

Source tree:

```text
dujiao-next/
```

## Purpose

This patch extends the provider catalog import path so TGX products can produce
multiple local SKUs from `config` race data and expose TGX `widget` fields as
Dujiao manual form schema.

## Scope

TGX catalog parsing:

- Parse `category[普通]=100.00` style config entries.
- Parse JSON object config entries such as:
  - `{"category[普通]":"100.00"}`
- Parse JSON list config entries with race/name/label and price fields.
- Calculate each TGX race target price with `price * 1.2`.
- Convert widget arrays/objects into schema fields with:
  - `key`
  - `type`
  - `label`
  - `required`

Import changes:

- Create one local SKU per TGX race variant.
- Store upstream SKU code as `shared_code|race`.
- Use a stable hash suffix in local SKU codes so non-ASCII race names do not
  collide after slug normalization.
- Store TGX widget schema in `Product.ManualFormSchemaJSON`.

## Verification

Passed:

```text
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/upstream
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/service -run 'TestImportProviderCatalog'
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/repository -run 'TestSQLDialect|TestProduct'
```

## Next Patch

Continue Phase 4 by adding live catalog sync orchestration:

- Pull FansGurus `services`.
- Pull TGX `items`.
- Build `FilteredCatalog`.
- Run provider import.
- Persist raw payloads and sync run summaries.
- Mark stale imported records inactive.
