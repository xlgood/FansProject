# Patch 0003: Fansgurus Adapter

Date: 2026-07-07

External source tree used:

```text
/private/tmp/dujiao-next-phase1
```

Patch file:

```text
patches/dujiao-next/0003-fansgurus-adapter.patch
```

## Purpose

This patch wires Fansgurus into Dujiao-Next's generic upstream adapter
contract.

It adds:

- `FansgurusAdapter`
- `upstream.NewAdapter` routing for `constants.ConnectionProtocolFansgurus`
- `Ping` backed by `FansgurusClient.GetBalance`
- `ListCategories` backed by Fansgurus service categories
- `ListProducts` backed by `FansgurusClient.ListServices`
- `GetProduct` backed by a service lookup
- `CreateOrder` backed by `FansgurusClient.AddOrder`
- `GetOrder` backed by `FansgurusClient.GetOrderStatus`
- explicit unsupported errors for `CancelOrder` and `DownloadImage`
- `httptest` coverage for protocol routing, ping, product mapping,
  product lookup, order creation, and order status mapping

## Mapping Notes

Fansgurus `service` IDs are mapped directly to Dujiao-Next upstream product
IDs and SKU IDs for the first adapter pass.

Fansgurus service `rate` is exposed as the upstream original price, while
Dujiao-Next-facing sell price follows Website3's launch rule:

```text
sell price = upstream rate * 10
```

The adapter uses decimal arithmetic for this price calculation.

Manual form fields are mapped from service type:

- `Default` -> `link`
- `Custom Comments` -> `link`, `comments`
- `Poll` -> `link`, `answer_number`
- `Mentions` -> `link`, `usernames`

Fansgurus order statuses are normalized for Dujiao-Next procurement polling:

- `Completed` -> `delivered`
- `In progress` / `Processing` -> `fulfilling`
- `Partial` -> `partially_refunded`
- `Canceled` / `Cancelled` -> `canceled`

## Verification

Completed:

```text
gofmt -w internal/upstream/adapter.go internal/upstream/fansgurus_adapter.go internal/upstream/fansgurus_adapter_test.go
git diff --check
GOPROXY=https://goproxy.cn,direct GOCACHE=/private/tmp/go-build-cache GOMODCACHE=/private/tmp/go-mod-cache go test ./internal/upstream
GOPROXY=https://goproxy.cn,direct GOCACHE=/private/tmp/go-build-cache GOMODCACHE=/private/tmp/go-mod-cache go test ./internal/service
```

Notes:

```text
The sandboxed upstream test run failed because httptest could not bind a local
port. The same command passed when run outside the sandbox.
```

## Next Patch

Patch 0004 should add the Fansgurus SKU/service sync service around
`FansgurusServiceMapping` and `FansgurusSyncRun`, including local
category/product/SKU upsert behavior and missing-service deactivation.
