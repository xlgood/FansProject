# Patch 0010: Provider Catalog Sync State

Date: 2026-07-09

Source tree:

```text
dujiao-next/
```

## Purpose

This patch persists provider catalog sync history and deactivates stale imported
mappings after each sync.

## Scope

Models and repositories:

- Add `ProviderCatalogSyncRun`.
- Add `ProviderCatalogSyncRunRepository`.
- Add `ProductMappingRepository.DeactivateMissingProviderCodes`.
- Add `ProductMappingRepository.ListActiveByProvider`.

Sync behavior:

- Store sync status, counts, supported platforms, raw FansGurus services, and
  raw TGX items.
- Record failed sync attempts when upstream pull or import fails.
- After successful import, mark active provider mappings inactive if their
  upstream product code is not in the latest filtered catalog.
- Keep stale handling scoped by `connection_id + provider`.

## Verification

Passed:

```text
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/service -run 'Test(SyncProviderCatalog|ImportProviderCatalog)'
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/upstream
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/repository -run 'TestSQLDialect|TestProduct'
```

## Next Patch

Wire the provider catalog sync to an execution entry point:

- admin-triggered sync endpoint, or
- worker/queue task, or
- CLI/bootstrap command.
