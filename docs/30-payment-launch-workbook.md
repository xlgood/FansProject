# PayPal Launch Workbook

Date: 2026-07-10

## Purpose

Use this workbook to prepare and accept the only planned launch payment
channel: PayPal official.

Decision record (2026-07-17):

- PayPal is the sole launch candidate and remains disabled until the acceptance
  checks in this workbook pass.
- Alipay website payment was rejected for the current business category. The
  project will not appeal, reapply under a different category, or use another
  merchant's credentials.
- WeChat Pay, Stripe, EPay/aggregators, and crypto payment providers are
  deferred. Code support does not authorize them for launch.
- Payoneer Receiving Accounts are not a consumer checkout replacement. They
  may only be reconsidered for an approved B2B bank-transfer workflow.

Do not commit payment credentials. Configure them only in the protected backend
admin payment channel records or the production secret store used to populate
those records.

## Current Code Mapping

The backend routes official payment channels through:

| Channel | `provider_type` | `channel_type` | Interaction mode | Webhook |
| --- | --- | --- | --- | --- |
| PayPal official | `official` | `paypal` | `redirect` | `POST /api/v1/payments/webhook/paypal` |

Target site policy:

- customer-facing order payments require logged-in users;
- launch channels should set `payment_roles` to member only;
- launch channels should include order payment type;
- keep wallet recharge disabled unless operations explicitly approves it;
- target storefront currency remains `USD`;
- PayPal settlement and checkout currency must be supported by the approved
  PayPal merchant account; any conversion must be configured and reconciled.

## Final URLs

Replace the temporary domains before production:

| Purpose | URL |
| --- | --- |
| Storefront return base | `https://FINAL_DOMAIN` |
| API origin | `https://FINAL_API_DOMAIN` |
| PayPal webhook | `https://FINAL_API_DOMAIN/api/v1/payments/webhook/paypal` |

Reverse proxy and CDN rules must pass these callback/webhook request bodies
unchanged. Do not cache payment paths.

## Channel Fields

Common payment channel fields:

| Field | Required launch value |
| --- | --- |
| `is_active` | `false` while configuring; enable only during acceptance |
| `provider_type` | `official` |
| `channel_type` | `paypal` |
| `payment_roles` | `member` |
| `payment_types` | `order` |
| `min_amount` / `max_amount` | match merchant account limits |
| `hide_amount_out_range` | `true` if amount limits are set |
| `fee_rate` / `fixed_fee` | match finance decision |

PayPal `config_json` fields:

| Field | Notes |
| --- | --- |
| `client_id` | PayPal app client ID |
| `client_secret` | PayPal app secret, server-side only |
| `base_url` | sandbox or live API origin |
| `return_url` | storefront return URL |
| `cancel_url` | storefront cancel URL |
| `webhook_id` | webhook ID for signature verification |
| `brand_name` | checkout display name |
| `locale` | optional checkout locale |
| `landing_page` | optional checkout landing page |
| `user_action` | recommended `PAY_NOW` |
| `shipping_preference` | recommended `NO_SHIPPING` |
| `target_currency` / `exchange_rate` | optional; leave empty for USD if PayPal account supports it |

## Acceptance Flow

Run this sequence separately for each enabled channel.

1. Keep the provider fulfillment switch disabled or use test-only products.
2. Enable exactly one payment channel.
3. Create a low-value order using a logged-in test user.
4. Confirm checkout shows only the intended channel.
5. Complete payment in sandbox or approved low-value production mode.
6. Verify local payment status becomes `success`.
7. Verify order status advances only after valid callback/webhook processing.
8. Verify payment amount and currency match the gateway charge.
9. Verify payment logs redact private keys, app secrets, webhook secrets, and
   raw account credentials.
10. Disable the channel again if the next channel is not ready for launch.

For PayPal, also confirm:

- webhook signature verification succeeds;
- capture status is successful or an allowed pending state;
- `webhook_id` belongs to the same PayPal app as `client_id`.

## Launch Blockers

Do not enable live payment if any item is true:

- Gate 1 config audit has failures;
- Gate 2 runtime dry-run has failures;
- callback or webhook URL still uses a temporary domain;
- any enabled payment channel has `payment_roles` allowing guest payment;
- frontend env contains payment secrets;
- callback/webhook request body is modified or cached by CDN/reverse proxy;
- signature verification is skipped or failing;
- PayPal live channel points at sandbox `base_url`, or sandbox channel points at
  live `base_url`;
- a paid order can create duplicate fulfillment records;
- payment logs expose credentials or full raw secrets.

## Evidence To Record

For each channel, record before launch:

| Evidence | Owner | Status |
| --- | --- | --- |
| Channel config reviewed without exposing secrets |  |  |
| Callback/webhook URL registered in gateway dashboard |  |  |
| Low-value payment created |  |  |
| Callback/webhook accepted and verified |  |  |
| Local payment marked success |  |  |
| Amount/currency reconciled |  |  |
| Order fulfillment behavior verified with safe test product |  |  |
| Logs reviewed for secret redaction |  |  |
| Channel disabled or approved for launch |  |  |

## Rollback

If payment acceptance fails:

1. Disable the affected payment channel in admin.
2. Keep API callback/webhook endpoints reachable for already-created payments.
3. Stop provider fulfillment if payment reconciliation is uncertain.
4. Export affected payments from admin.
5. Reconcile with the gateway dashboard before refund, retry, or manual order
   adjustment.
6. Rotate channel credentials if a secret may have been exposed.
