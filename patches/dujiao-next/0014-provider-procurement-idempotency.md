# Patch 0014: Provider Procurement Idempotency

Date: 2026-07-09

Source tree:

```text
dujiao-next/
```

## Purpose

This patch hardens provider procurement submission so unavailable upstream submit
results do not trigger duplicate purchases and can be shown to customers with a
friendly message.

## Scope

Provider submit behavior:

- FansGurus submit errors are split into:
  - definitive failures such as auth, validation, or balance errors;
  - temporary unavailable results such as transport, parse, or empty-order
    responses.
- Temporary unavailable FansGurus submits move the procurement order to `failed`
  with `provider_submit_temporarily_unavailable`, no `next_retry_at`, and no
  automatic retry.
- The local order is moved back from `fulfilling` to `paid` so the customer can
  see the failure and retry later without the system double-submitting upstream.
- TGX submit errors first query `/commodity/query` by `request_no` to recover an
  already-created trade when possible.
- TGX recovered trades reuse the same accept/deliver flow as normal trade
  responses.
- Unresolved TGX submit failures use the same customer-facing temporary
  unavailable failure path.
- Public order detail responses include a user-safe `fulfillment_error` code for
  failed/rejected procurement orders.

The existing Dujiao-Next upstream adapter retry behavior is unchanged.

## Verification

Passed:

```text
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/upstream
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/service -run 'TestSubmitToUpstream_(FansGurusProvider|FansGurusUnavailableFailsForUserWithoutRetry|TGXProviderImmediateSecret|TGXProviderRecoversByRequestNo)'
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/http/handlers/public ./internal/dto
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/service -run 'TestPollUpstreamStatus_(FansGurusCompleted|TGXQueryDeliveredSecret|TGXQueryPendingKeepsAccepted|Delivered|FulfilledMappedToDelivered)'
```

Sandbox note:

- The first sandboxed `go test` attempt failed because `httptest` could not bind
  to a local port. The same commands passed with approved non-sandbox execution.

## Next Patch

Expose provider fulfillment status and retry tools in admin.
