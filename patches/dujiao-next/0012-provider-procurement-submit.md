# Patch 0012: Provider Procurement Submit

Date: 2026-07-09

Source tree:

```text
dujiao-next/
```

## Purpose

This patch lets existing procurement workers submit paid mapped orders to
FansGurus and TGX provider APIs.

## Scope

Procurement submit:

- Keep the existing Dujiao-Next adapter path unchanged.
- Branch provider procurement by site connection protocol:
  - `fansgurus`
  - `tgx-account`
- FansGurus submit:
  - uses `ProductMapping.UpstreamProductCode` as service ID
  - uses order item quantity
  - uses manual form field `link`
- TGX submit:
  - splits `SKUMapping.UpstreamSKUCode` as `shared_code|race`
  - uses order item quantity
  - uses local order number as `request_no`
  - forwards manual form fields as TGX widget parameters
  - stores immediate `secret` delivery payload when returned

Testing:

- Verify FansGurus submit form construction and accepted procurement status.
- Verify TGX trade form construction, app key secrecy, and immediate
  fulfillment creation.
- Keep existing Dujiao-Next submit behavior covered.

## Verification

Passed:

```text
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/service -run 'TestSubmitToUpstream_(FansGurusProvider|TGXProviderImmediateSecret|Success|NonRetryableError_Rejects|RetryableError_Retries)'
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/service -run 'Test(SyncProviderCatalog|ImportProviderCatalog|CreateForOrder)'
GOPROXY=https://goproxy.cn,direct GOCACHE=/Users/river/FansProject/dujiao-next/.gocache GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache go test ./internal/upstream
```

## Next Patch

Add provider status polling:

- FansGurus `status` polling.
- TGX `query` polling when trade does not immediately return a secret.
- Provider-specific status mapping into local procurement/order fulfillment
  states.
