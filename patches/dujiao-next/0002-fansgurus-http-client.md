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
git diff --check
```

Not completed:

```text
gofmt
go test ./internal/upstream
```

Reason:

```text
go not found
gofmt not found
```

The local execution environment does not currently expose the Go toolchain in
`PATH`.

## Next Patch

Patch 0003 should add the Fansgurus adapter implementation that translates
Dujiao-Next `upstream.Adapter` calls into this client:

- `Ping` -> `GetBalance`
- `ListProducts` -> `ListServices`
- `CreateOrder` -> `AddOrder`
- `GetOrder` -> `GetOrderStatus`

It should also update `upstream.NewAdapter` to route `fansgurus` connections.
