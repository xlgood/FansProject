# Dujiao-Next Patch 0019: Provider Fulfillment E2E Mock

## Purpose

Add a repeatable local mock test for the FansGurus fulfillment flow from local
paid order to delivered order, without calling any real provider API.

## Changes

- Adds `TestProviderFulfillmentEndToEnd_FansGurusMock`.
- Uses `httptest` to mock FansGurus `add` and `status` actions.
- Verifies the full backend flow:
  - `CreateForOrder()` creates a pending procurement order.
  - `SubmitToUpstream()` submits the mocked FansGurus order and moves the local
    order to `fulfilling`.
  - `SyncAcceptedOrders()` polls the mocked status endpoint.
  - The procurement order reaches `fulfilled`.
  - The local order reaches `delivered`.
- Asserts the mock upstream receives exactly one submit call and one status
  call.

## Verification

- `go test ./internal/service -run 'TestProviderFulfillmentEndToEnd_FansGurusMock|TestSyncAcceptedOrders_FansGurusCompleted|TestSubmitToUpstream_FansGurusProvider|TestPollUpstreamStatus_FansGurusCompleted'`
- `go test ./internal/service -run 'Test(ProviderFulfillmentEndToEnd|CreateForOrder|SubmitToUpstream|PollUpstreamStatus|SyncAcceptedOrders|CancelManual)'`

