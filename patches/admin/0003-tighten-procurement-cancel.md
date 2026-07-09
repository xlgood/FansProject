# 0003 Tighten Procurement Cancel

Hides the admin cancel action for procurement orders that may already have been
accepted by a provider.

Scope:

- Shows cancel only for `pending`, `failed`, and `rejected` procurement orders.
- Updates the confirmation copy to clarify that only unsubmitted or failed
  procurement orders can be canceled locally.

Verification:

- `cd admin && ./node_modules/.bin/vue-tsc -b`
- `cd admin && ./node_modules/.bin/vite build`
