# 0016 Admin Procurement Status Sync

Adds an admin endpoint for manually synchronizing a single procurement order's
latest status.

Scope:

- Adds `POST /admin/procurement-orders/:id/sync-status`.
- Reuses the existing procurement polling flow.
- Grants the integration role access to the new endpoint.

Verification:

- `go test ./internal/http/handlers/admin ./internal/router`
- `go test ./internal/service -run 'TestPollUpstreamStatus_(FansGurusCompleted|TGXQueryDeliveredSecret|TGXQueryPendingKeepsAccepted|Delivered|FulfilledMappedToDelivered)'`
