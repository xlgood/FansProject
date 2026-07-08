# Patch 0006: Catalog Policy

Date: 2026-07-08

Source tree:

```text
dujiao-next/
```

## Purpose

This patch adds the pure catalog policy layer for Phase 4. It does not yet write
to Dujiao-Next product, SKU, category, or mapping tables.

Added files:

- `internal/upstream/catalog_policy.go`
- `internal/upstream/catalog_policy_test.go`

## Scope

Implemented rules:

- Normalize platform aliases:
  - `x`, `twitter`, `twitter / x`
  - `instagram`, `ig`, `ins`
  - `tiktok`, `tik tok`
  - `facebook`, `fb`
  - `youtube`, `yt`
- Exclude Telegram-related catalog items before intersection.
- Apply Telegram Chinese and English token detection.
- Treat `tg` as Telegram only with token boundaries.
- Ignore inactive upstream items when computing platform intersection.
- Compute supported platforms as FansGurus platforms intersect TGX platforms.
- Filter out non-intersection platform items.
- Convert provider items into normalized catalog items with target prices:
  - FansGurus `rate * 5`, preserving the original per-1000 quantity basis.
  - TGX `price * 1.2`.

## Verification

Passed:

```text
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/upstream
```

Result:

```text
ok  	github.com/dujiao-next/internal/upstream	0.770s
```

## Next Patch

Continue Phase 4 by adding the persistence/import layer:

- Store raw upstream catalog payloads or sync snapshots.
- Add string code fields or metadata for TGX product/SKU identities.
- Upsert filtered catalog items into categories, products, SKUs, and mappings.
- Keep Telegram and non-intersection items inactive or absent from storefront
  output.
