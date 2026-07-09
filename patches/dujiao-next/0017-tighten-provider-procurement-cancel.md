# 0017 Tighten Provider Procurement Cancel

Prevents admin cancellation from marking provider-accepted procurement orders as
locally canceled when the provider does not support a cancel call.

Scope:

- Adds `ErrProcurementCancelUnsupported`.
- Rejects manual cancel for FansGurus/TGX `submitted` or `accepted` procurement
  orders.
- Keeps local-only cancellation available for failed/rejected/pending
  procurement orders.
- Returns a 400 response for unsupported admin cancel attempts.

Verification:

- `go test ./internal/service -run 'TestCancelManual_(ProviderAcceptedUnsupported|FailedLocalOnlyCancels)'`
- `go test ./internal/http/handlers/admin ./internal/router`
