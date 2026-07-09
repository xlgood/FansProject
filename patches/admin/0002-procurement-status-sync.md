# 0002 Procurement Status Sync

Adds an admin UI action to manually synchronize accepted procurement orders.

Scope:

- Adds `syncProcurementOrderStatus` to the admin API client.
- Shows a `同步状态` / `Sync Status` action for accepted procurement orders in
  the list and detail dialog.
- Refreshes list, stats, and detail after sync.

Verification:

- `cd admin && ./node_modules/.bin/vue-tsc -b`
- `cd admin && ./node_modules/.bin/vite build`
