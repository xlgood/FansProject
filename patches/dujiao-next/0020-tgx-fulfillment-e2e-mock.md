# Dujiao-Next Patch 0020: TGX Fulfillment E2E Mock

## Purpose

Add a repeatable local mock test for the TGX account fulfillment flow where the
trade is accepted first and the account secret is delivered later by status
query.

## Changes

- Adds `TestProviderFulfillmentEndToEnd_TGXMockDelayedSecret`.
- Uses `httptest` to mock TGX `/commodity/trade` and `/commodity/query`.
- Verifies the full backend flow:
  - `CreateForOrder()` creates a pending procurement order.
  - `SubmitToUpstream()` sends the widget/manual form data to mocked TGX trade.
  - TGX returns `pending` with a `trade_no`, so the local order moves to
    `fulfilling` and the procurement order moves to `accepted`.
  - `SyncAcceptedOrders()` queries mocked TGX status.
  - TGX returns `completed` with an account secret.
  - The procurement order reaches `fulfilled`.
  - The local order reaches `delivered`.
  - The account secret is stored in fulfillment payload.
- Asserts the mock upstream receives exactly one trade call and one query call.

## Verification

- `go test ./internal/service -run 'TestProviderFulfillmentEndToEnd_TGXMockDelayedSecret|TestSubmitToUpstream_TGXProviderImmediateSecret|TestPollUpstreamStatus_TGXQueryDeliveredSecret|TestPollUpstreamStatus_TGXQueryPendingKeepsAccepted'`
- `go test ./internal/service -run 'Test(ProviderFulfillmentEndToEnd|CreateForOrder|SubmitToUpstream|PollUpstreamStatus|SyncAcceptedOrders|CancelManual)'`

