# Patch 0011: Admin Provider Catalog Sync

Date: 2026-07-09

Source tree:

```text
dujiao-next/
```

## Purpose

This patch wires provider catalog sync to a manual admin execution endpoint.

## Scope

Admin API:

- Add `POST /admin/provider-catalog/sync`.
- Accept `fansgurus_connection_id` and `tgx_connection_id`.
- Load and validate both site connections.
- Require connection protocols:
  - `fansgurus`
  - `tgx-account`
- Build provider clients from saved connection credentials.
- Call `ProductMappingService.SyncProviderCatalogWithClients`.
- Return sync summary counts.

RBAC:

- Add the manual trigger route to the built-in `integration` role.

Testing:

- Add admin handler tests with fake catalog clients.
- Verify successful manual sync imports provider mappings.
- Verify wrong connection protocol is rejected before client creation.

## Verification

Passed:

```text
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/http/handlers/admin -run 'TestSyncProviderCatalog'
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/router
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/service -run 'Test(SyncProviderCatalog|ImportProviderCatalog)'
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/upstream
```

## Next Patch

Add an admin UI control for manual sync, or add worker/queue scheduling if
automatic catalog refresh is required.
