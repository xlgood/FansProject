# Patch 0005: Provider Clients

Date: 2026-07-08

Source tree:

```text
dujiao-next/
```

## Purpose

This patch adds isolated provider API clients inside Dujiao-Next without wiring
them into runtime catalog sync or procurement yet.

Added files:

- `internal/upstream/fansgurus_client.go`
- `internal/upstream/fansgurus_client_test.go`
- `internal/upstream/tgx_client.go`
- `internal/upstream/tgx_client_test.go`
- `internal/upstream/tgx_signer.go`

## Scope

FansGurus client:

- `services`
- `balance`
- `add`
- `status`
- API error classification and secret redaction
- Decimal price helper: `rate * 5`
- Preserves FansGurus upstream quantity basis. The upstream `rate` remains a
  per-1000 rate; there is no conversion to per-unit pricing.

TGX client:

- `/authentication/connect`
- `/commodity/items`
- `/commodity/item`
- `/commodity/inventory`
- `/commodity/inventoryState`
- `/commodity/trade`
- `/commodity/query`
- Documented MD5 signer
- Widget fields as extra form parameters
- API error classification and app key redaction
- Decimal price helper: `price * 1.2`

## Verification

No real upstream order APIs were called. All tests use `httptest`.

Passed:

```text
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/upstream
```

Result:

```text
ok  	github.com/dujiao-next/internal/upstream	0.816s
```

## Next Patch

Phase 4 should build catalog sync and filtering:

- Normalize platforms from FansGurus and TGX catalogs.
- Exclude Telegram-related products/services.
- Compute the cross-provider platform intersection.
- Import allowed products/SKUs into Dujiao-Next mappings.
