# Patch 0013: Provider Procurement Polling

Date: 2026-07-09

Source tree:

```text
dujiao-next/
```

## Purpose

This patch lets procurement workers poll accepted FansGurus and TGX provider
orders after submission.

## Scope

Provider polling:

- Keep the existing Dujiao-Next adapter polling path unchanged.
- Branch accepted procurement polling by connection protocol:
  - `fansgurus`
  - `tgx-account`
- FansGurus polling:
  - calls provider `status`
  - maps completed/delivered to local delivered flow
  - maps canceled/refunded/partial aliases into local procurement states
- TGX polling:
  - calls provider `query`
  - stores returned `secret` as local fulfillment payload when completed
  - leaves pending trades accepted without creating fulfillment
- Scheduled accepted-order sync also supports provider connections.

Testing:

- Verify FansGurus completed status marks local order delivered.
- Verify TGX completed query with `secret` creates fulfillment.
- Verify TGX pending query keeps procurement accepted.
- Re-run provider submit tests to guard the preceding patch.

## Verification

Passed:

```text
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/service -run 'TestPollUpstreamStatus_(FansGurusCompleted|TGXQueryDeliveredSecret|TGXQueryPendingKeepsAccepted|Delivered|FulfilledMappedToDelivered)'
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/service -run 'TestSubmitToUpstream_(FansGurusProvider|TGXProviderImmediateSecret|Success|NonRetryableError_Rejects|RetryableError_Retries)'
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/upstream
```

## Next Patch

Harden provider retry/idempotency behavior around timeout and ambiguous
submission states.
