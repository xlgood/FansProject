# Patch 0004: Fansgurus Service Sync

Date: 2026-07-07

External source tree used:

```text
/private/tmp/dujiao-next-phase1
```

Patch file:

```text
patches/dujiao-next/0004-fansgurus-service-sync.patch
```

## Purpose

This patch adds the first Fansgurus catalog sync layer for Dujiao-Next.

It intentionally syncs into Fansgurus-specific mapping tables only. It does
not yet create or update local Dujiao-Next categories, products, or SKUs.

It adds:

- `FansgurusServiceMappingRepository`
- `FansgurusSyncRunRepository`
- `FansgurusSyncService`
- connection protocol validation for `fansgurus`
- encrypted API secret reuse through `SiteConnectionService`
- service metadata upsert into `fansgurus_service_mappings`
- `fansgurus_sync_runs` counters and status updates
- unsupported service type counting
- missing-service deactivation
- repository and service unit tests

## Sync Behavior

For each Fansgurus service returned by `services`:

- unsupported service types are counted and skipped
- supported service types are upserted by `(connection_id, service)`
- `rate` is stored as `upstream_rate`
- `sell_rate` is calculated as `rate * 10`
- metadata fields, support flags, raw payload, content hash, and `last_seen_at`
  are refreshed
- new mappings default to `purchase_enabled = false`

After each sync, active mappings that were not seen in the latest response are
marked inactive.

## Verification

Completed:

```text
gofmt -w internal/repository/fansgurus_repository.go internal/repository/fansgurus_repository_test.go internal/service/fansgurus_sync.go internal/service/fansgurus_sync_test.go
git diff --check
GOPROXY=https://goproxy.cn,direct GOCACHE=/private/tmp/go-build-cache GOMODCACHE=/private/tmp/go-mod-cache go test ./internal/repository
GOPROXY=https://goproxy.cn,direct GOCACHE=/private/tmp/go-build-cache GOMODCACHE=/private/tmp/go-mod-cache go test ./internal/upstream
GOPROXY=https://goproxy.cn,direct GOCACHE=/private/tmp/go-build-cache GOMODCACHE=/private/tmp/go-mod-cache go test ./internal/service
```

Notes:

```text
The sandboxed full service test run was blocked by existing httptest port bind
usage. The same service test command passed outside the sandbox.
```

## Next Patch

Patch 0005 should connect this sync layer to application entry points:

- provider container wiring
- admin/service trigger endpoint or worker task
- optional local category/product/SKU materialization from approved mappings
