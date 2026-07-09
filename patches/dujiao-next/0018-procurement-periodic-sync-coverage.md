# Dujiao-Next Patch 0018: Procurement Periodic Sync Coverage

## Purpose

Verify that accepted provider procurement orders are covered by the automatic
worker-side status sync path, not only by the admin manual sync action.

## Changes

- Adds a service-level test for `SyncAcceptedOrders()` using a mocked
  FansGurus status endpoint.
- Verifies an accepted FansGurus procurement order is automatically advanced to
  `fulfilled` and its local order is advanced to `delivered`.
- Adds a worker/queue test that locks the periodic procurement sync task type
  to `procurement:sync_accepted`.

## Existing Runtime Path Confirmed

- `internal/worker/service.go` registers `queue.NewProcurementSyncAcceptedTask()`
  every 30 minutes when `ProcurementOrderService` is present.
- `internal/worker/asynq_worker.go` handles the task by calling
  `ProcurementOrderService.SyncAcceptedOrders()`.
- `SyncAcceptedOrders()` queries accepted procurement orders and polls
  FansGurus/TGX provider status without requiring admin interaction.

## Verification

- `go test ./internal/service -run 'TestSyncAcceptedOrders_FansGurusCompleted|TestPollUpstreamStatus_(FansGurusCompleted|TGXQueryDeliveredSecret|TGXQueryPendingKeepsAccepted|Delivered|FulfilledMappedToDelivered)'`
- `go test ./internal/worker`

