# Payment Launch Workbook

Date: 2026-07-10

## Purpose

Use this workbook to prepare and accept the launch payment channels:

- Alipay official
- WeChat Pay official
- PayPal official

Do not commit payment credentials. Configure them only in the protected backend
admin payment channel records or the production secret store used to populate
those records.

## Current Code Mapping

The backend routes official payment channels through:

| Channel | `provider_type` | `channel_type` | Supported interaction modes | Callback/webhook |
| --- | --- | --- | --- | --- |
| Alipay official | `official` | `alipay` | `qr`, `wap`, `page` | `POST/GET /api/v1/payments/callback` |
| WeChat Pay official | `official` | `wechat` | `qr`, `redirect` | `POST /api/v1/payments/callback` or provider webhook handling |
| PayPal official | `official` | `paypal` | `redirect` | `POST /api/v1/payments/webhook/paypal` |

Target site policy:

- customer-facing order payments require logged-in users;
- launch channels should set `payment_roles` to member only;
- launch channels should include order payment type;
- keep wallet recharge disabled unless operations explicitly approves it;
- target storefront currency remains `USD`;
- if a gateway requires `CNY`, configure channel-level exchange settings and
  verify the stored payment amount/currency matches the gateway charge.

## Final URLs

Replace the temporary domains before production:

| Purpose | URL |
| --- | --- |
| Storefront return base | `https://FINAL_DOMAIN` |
| API origin | `https://FINAL_API_DOMAIN` |
| Generic payment callback | `https://FINAL_API_DOMAIN/api/v1/payments/callback` |
| PayPal webhook | `https://FINAL_API_DOMAIN/api/v1/payments/webhook/paypal` |

Reverse proxy and CDN rules must pass these callback/webhook request bodies
unchanged. Do not cache payment paths.

## Channel Fields

Common payment channel fields:

| Field | Required launch value |
| --- | --- |
| `is_active` | `false` while configuring; enable only during acceptance |
| `provider_type` | `official` |
| `channel_type` | one of `alipay`, `wechat`, `paypal` |
| `payment_roles` | `member` |
| `payment_types` | `order` |
| `min_amount` / `max_amount` | match merchant account limits |
| `hide_amount_out_range` | `true` if amount limits are set |
| `fee_rate` / `fixed_fee` | match finance decision |

Alipay `config_json` fields:

| Field | Notes |
| --- | --- |
| `app_id` | Alipay open platform app ID |
| `private_key` | merchant private key, server-side only |
| `alipay_public_key` | Alipay public key |
| `gateway_url` | production gateway, usually `https://openapi.alipay.com/gateway.do` |
| `notify_url` | generic callback URL |
| `return_url` | required for `wap` and `page` modes |
| `sign_type` | use `RSA2` unless the merchant account requires otherwise |
| `app_cert_sn` | required only when the account uses certificate mode |
| `alipay_root_cert_sn` | required only when the account uses certificate mode |
| `target_currency` / `exchange_rate` | set when converting site USD to CNY |

WeChat Pay `config_json` fields:

| Field | Notes |
| --- | --- |
| `appid` | WeChat app ID |
| `mchid` | merchant ID |
| `merchant_serial_no` | API certificate serial number |
| `merchant_private_key` | merchant private key, server-side only |
| `api_v3_key` | API v3 key, server-side only |
| `notify_url` | generic callback URL |
| `h5_redirect_url` | required for `redirect` mode |
| `h5_type` | optional: `WAP`, `IOS`, or `ANDROID` |
| `h5_wap_url` | optional H5 site URL |
| `h5_wap_name` | optional H5 site name |
| `base_url` | optional gateway override |
| `target_currency` / `exchange_rate` | set when converting site USD to CNY |

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

For Alipay and WeChat Pay, also confirm:

- callback signature verification succeeds;
- USD to CNY conversion, if configured, is reflected in local payment records;
- return URL works without exposing internal implementation wording.

## Launch Blockers

Do not enable live payment if any item is true:

- Gate 1 config audit has failures;
- Gate 2 runtime dry-run has failures;
- callback or webhook URL still uses a temporary domain;
- any enabled payment channel has `payment_roles` allowing guest payment;
- frontend env contains payment secrets;
- callback/webhook request body is modified or cached by CDN/reverse proxy;
- signature verification is skipped or failing;
- Alipay/WeChat conversion rate is missing when the gateway requires CNY;
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
