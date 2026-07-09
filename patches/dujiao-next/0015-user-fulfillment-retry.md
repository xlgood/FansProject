# 0015 User Fulfillment Retry

Adds customer-triggered retry for temporary fulfillment submission failures.

Scope:

- Adds `fulfillment_retryable` to public order details.
- Exposes logged-in and guest retry endpoints:
  - `POST /api/v1/orders/:order_no/fulfillment/retry`
  - `POST /api/v1/guest/orders/:order_no/fulfillment/retry`
- Restricts customer retry to failed/rejected procurement orders with the
  temporary submission error code.
- Supports parent orders by checking child order procurement records.

Verification:

- `go test ./internal/service -run 'TestSubmitToUpstream_(FansGurusProvider|FansGurusUnavailableFailsForUserWithoutRetry|TGXProviderImmediateSecret|TGXProviderRecoversByRequestNo)'`
- `go test ./internal/http/handlers/public ./internal/dto`
