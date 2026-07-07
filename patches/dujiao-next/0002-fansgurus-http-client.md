# Patch 0002: Fansgurus HTTP Client

Date: 2026-07-07

External source tree used:

```text
/private/tmp/dujiao-next-phase1
```

Patch file:

```text
patches/dujiao-next/0002-fansgurus-http-client.patch
```

## Purpose

This patch adds a focused Fansgurus HTTP client under Dujiao-Next's
`internal/upstream` package. It does not yet wire the client into
`upstream.NewAdapter` or the procurement flow.

It adds:

- `FansgurusClient`
- `GetBalance`
- `ListServices`
- `AddOrder`
- `GetOrderStatus`
- form POST handling for Fansgurus `key` and `action`
- typed error sentinels:
  - `ErrFansgurusAuth`
  - `ErrFansgurusValidation`
  - `ErrFansgurusBusiness`
  - `ErrFansgurusBadJSON`
  - `ErrFansgurusEmptyResult`
- API key redaction in returned Fansgurus error messages
- `httptest`-based tests for balance, services, add, status, API error
  classification/redaction, bad JSON, empty services, and network failure

## Verification

Completed:

```text
gofmt -w internal/upstream/fansgurus_client.go internal/upstream/fansgurus_client_test.go
git diff --check
GOPROXY=https://goproxy.cn,direct GOCACHE=/private/tmp/go-build-cache GOMODCACHE=/private/tmp/go-mod-cache go test ./internal/upstream
```

Notes:

```text
The first attempt with proxy.golang.org timed out while downloading modules.
The test passed after using GOPROXY=https://goproxy.cn,direct.
```

## Next Patch

Patch 0003 should add the Fansgurus adapter implementation that translates
Dujiao-Next `upstream.Adapter` calls into this client:

- `Ping` -> `GetBalance`
- `ListProducts` -> `ListServices`
- `CreateOrder` -> `AddOrder`
- `GetOrder` -> `GetOrderStatus`

It should also update `upstream.NewAdapter` to route `fansgurus` connections.
