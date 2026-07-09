# 0002 Fulfillment Retry Button

Adds a customer-facing retry action for temporary fulfillment submission
failures.

Scope:

- Adds logged-in and guest API wrappers for fulfillment retry.
- Adds retry loading state and success/failure toasts.
- Shows a localized `重新提交` / `Retry submission` button next to the
  friendly fulfillment error message in classic and vault order details.
- Keeps user-facing copy free of upstream/API/provider wording.

Verification:

- `cd user && ./node_modules/.bin/vue-tsc -b`
- `cd user && ./node_modules/.bin/vite build`
