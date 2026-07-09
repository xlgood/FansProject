# Patch 0009: Provider Catalog Sync

Date: 2026-07-09

Source tree:

```text
dujiao-next/
```

## Purpose

This patch adds the live catalog sync orchestration layer around the already
implemented provider clients, catalog policy, and import path.

It does not create scheduler/admin endpoints yet and does not call real upstream
APIs in tests.

## Scope

Added:

- `FansGurusCatalogClient` interface.
- `TGXCatalogClient` interface.
- `ProviderCatalogSyncInput`.
- `ProviderCatalogSyncResult`.
- `ProductMappingService.SyncProviderCatalogWithClients`.

Behavior:

- Pull FansGurus services through `ListServices`.
- Pull TGX items through `ListItems`.
- Convert upstream records to `ProviderCatalogItem`.
- Build the filtered catalog using Telegram exclusion and platform
  intersection rules.
- Import filtered catalog rows using separate FansGurus and TGX connection IDs.
- Return sync summary counts:
  - pulled records;
  - supported platforms;
  - Telegram filtered records;
  - inactive filtered records;
  - non-intersection filtered records;
  - imported/skipped records.

## Verification

Passed:

```text
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/service -run 'Test(SyncProviderCatalog|ImportProviderCatalog)'
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/upstream
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/repository -run 'TestSQLDialect|TestProduct'
```

## Next Patch

Continue Phase 4 with persistence and lifecycle hardening:

- Persist raw upstream payloads and sync summaries.
- Mark stale imported mappings inactive when upstream records disappear or leave
  the filtered intersection.
- Wire sync orchestration to an admin or worker entry point.
