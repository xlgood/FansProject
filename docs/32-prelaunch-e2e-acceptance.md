# Prelaunch E2E Acceptance

Date: 2026-07-10

## Purpose

Use this workbook to run the final end-to-end acceptance before public launch.
It verifies that the storefront, auth, checkout, payment, order lifecycle,
admin operations, language/SEO, and guest restrictions work together on the
staging or production-equivalent environment.

Do not use live provider fulfillment or live payment credentials unless the
owner explicitly approves low-value production tests.

## Preconditions

Complete these before E2E:

- Gate 1 config audit has `0` failures.
- Gate 2 runtime dry-run has `0` failures.
- `docs/31-production-data-initialization.md` is complete.
- At least one safe test product exists after provider catalog sync.
- Payment channels are configured according to
  `docs/30-payment-launch-workbook.md`.
- `worker` is stopped unless the test is explicitly a provider fulfillment
  acceptance run.
- Test customer account exists and has a known email/password.
- Test admin account has access to products, orders, payments, provider
  connections, catalog sync, and logs.

## Evidence Record

| Area | Owner | Result | Evidence | Timestamp |
| --- | --- | --- | --- | --- |
| Public browse |  |  |  |  |
| Guest restrictions |  |  |  |  |
| Registration/login |  |  |  |  |
| Checkout |  |  |  |  |
| Payment |  |  |  |  |
| Order status |  |  |  |  |
| Admin review |  |  |  |  |
| Language/SEO |  |  |  |  |
| Public wording |  |  |  |  |
| Logs/security |  |  |  |  |

## Public Browse Flow

Run in a clean browser profile with no logged-in session.

1. Open `https://FINAL_DOMAIN/`.
2. Open `https://FINAL_DOMAIN/products`.
3. Open one category page.
4. Open one FansGurus-backed product detail page.
5. Open one TGX-backed product detail page.
6. Change language to `zh-CN`, `zh-TW`, and `en`.

Pass criteria:

- public pages return `200`;
- products and SKUs load without login;
- no Telegram product, category, SKU, or search result appears;
- no non-intersection platform appears;
- displayed currency is `USD`;
- FansGurus price reflects upstream `rate * 5`;
- FansGurus quantity basis, minimums, maximums, and increments match upstream
  scale;
- TGX price reflects `price * 1.2`;
- product copy does not mention provider, upstream, API routing, procurement,
  or manual operator workflow.

## Guest Restriction Flow

Run while logged out.

Browser checks:

- open `https://FINAL_DOMAIN/checkout`;
- open `https://FINAL_DOMAIN/pay`;
- open `https://FINAL_DOMAIN/me/orders`;
- open `https://FINAL_DOMAIN/orders/TEST-NOT-REAL`;
- open `https://FINAL_DOMAIN/guest/orders`;
- open `https://FINAL_DOMAIN/guest/orders/TEST-NOT-REAL`.

API checks:

```bash
curl -i https://FINAL_API_DOMAIN/api/v1/guest/orders
curl -i -X POST https://FINAL_API_DOMAIN/api/v1/guest/orders
curl -i -X POST https://FINAL_API_DOMAIN/api/v1/guest/orders/create-and-pay
curl -i https://FINAL_API_DOMAIN/api/v1/guest/orders/TEST-NOT-REAL
curl -i -X POST https://FINAL_API_DOMAIN/api/v1/guest/payments
```

Pass criteria:

- browser routes redirect to login;
- guest order lookup is not available without login;
- guest order creation is not available without login;
- guest payment creation is not available without login;
- public product browsing still works while logged out.

## Registration And Login Flow

1. Register a new test user from `https://FINAL_DOMAIN/auth/register`.
2. Confirm email/username validation works.
3. Log out.
4. Log in from `https://FINAL_DOMAIN/auth/login`.
5. Open `https://FINAL_DOMAIN/me`.
6. Open `https://FINAL_DOMAIN/me/security`.
7. Open `https://FINAL_DOMAIN/me/orders`.

Pass criteria:

- registration succeeds or shows the intended production policy if registration
  is disabled;
- login succeeds for the test user;
- personal center is accessible only after login;
- auth errors do not expose stack traces or internal wording;
- session persists across normal page refresh.

## Checkout Flow

Run as the logged-in test user.

1. Open a FansGurus-backed product detail page.
2. Select a valid SKU and quantity.
3. Try quantity below minimum.
4. Try quantity that violates increment rules.
5. Select a valid quantity.
6. Add to cart or go directly to checkout.
7. Open checkout.
8. Confirm final amount, currency, and payment channels.
9. Create an order without completing payment.

Repeat with one TGX-backed product.

Pass criteria:

- invalid quantity is blocked client-side or server-side;
- valid quantity succeeds;
- checkout requires login;
- order amount is correct;
- only intended payment channels appear;
- order status starts as pending payment;
- no duplicate order is created on refresh/back navigation.

## Payment Flow

Use sandbox or low-value production mode according to
`docs/30-payment-launch-workbook.md`.

For each enabled channel:

1. Select the channel on `/pay`.
2. Create payment.
3. Verify QR or redirect behavior.
4. Complete or simulate the approved sandbox payment.
5. Return to storefront.
6. Refresh payment page.
7. Open `/me/orders`.
8. Open `/orders/<order_no>`.

Pass criteria:

- payment record is created once;
- return URL uses final storefront domain;
- callback/webhook URL uses final API domain;
- local payment reaches `success`;
- order reaches paid/fulfilling or the expected post-payment state;
- duplicate callback does not double-credit or double-fulfill;
- payment amount/currency matches the gateway charge;
- Alipay/WeChat CNY conversion, if enabled, is visible in payment records;
- PayPal capture/webhook verification succeeds when PayPal is enabled.

## Provider Fulfillment Flow

Only run this section with explicit approval and low-value orders.

1. Confirm `worker` start is approved.
2. Start `worker`.
3. Pay one FansGurus-backed test order.
4. Pay one TGX-backed test order.
5. Monitor admin order detail and provider/procurement status.
6. Wait for status sync.
7. Stop `worker` after the test if launch approval is not final.

Pass criteria:

- one paid local order creates at most one provider submission;
- provider status sync updates local order without manual database edits;
- TGX delivered account secret is visible only to the buyer and authorized
  admins;
- public order pages do not expose provider/internal wording;
- logs redact provider credentials and delivery secrets.

## Admin Review Flow

Run as an authorized admin.

1. Open admin dashboard.
2. Open products and verify synced product/SKU counts.
3. Open connection management and review last catalog sync.
4. Trigger manual catalog sync only if approved for this acceptance run.
5. Open payment channels and verify only intended launch channels are active.
6. Open payments and inspect the test payment.
7. Open orders and inspect the test order.
8. Open users and inspect the test user.
9. Export payments or orders only if needed for evidence.

Pass criteria:

- admin requires login and expected permissions;
- last provider sync status is visible;
- payment/order rows match storefront actions;
- payment and provider controls are limited to authorized admin roles;
- no admin action is required for normal customer checkout except severe risk
  cases.

## Language, SEO, And Brand Flow

Run these checks:

```bash
curl -I https://FINAL_DOMAIN/
curl -I https://FINAL_DOMAIN/zh-CN
curl -I https://FINAL_DOMAIN/zh-TW/products
curl -I https://FINAL_DOMAIN/en/products
curl -i https://FINAL_DOMAIN/sitemap.xml
curl -i https://FINAL_DOMAIN/robots.txt
curl -i https://FINAL_API_DOMAIN/api/v1/public/config
```

Pass criteria:

- locale routes return `200`;
- first visit language follows trusted country header or `Accept-Language`;
- manual language override persists;
- `html lang`, canonical URL, and `hreflang` are correct;
- sitemap uses final HTTPS domain;
- sitemap excludes Telegram and non-intersection platform pages;
- favicon, logo, and OG image load from final or approved temporary assets;
- public config returns final brand and `currency: "USD"`.

## Security And Logs

Run after each E2E pass:

```bash
docker compose \
  --env-file /etc/target-site/compose.env \
  -f ops/compose/docker-compose.production.yml \
  logs --since 60m api worker
```

Review for:

- payment secrets;
- provider credentials;
- JWT or SMTP secrets;
- TGX delivered account secrets;
- stack traces exposed to public responses;
- duplicate provider submission errors;
- auth failures or rate-limit anomalies.

Pass criteria:

- no secret appears in logs or frontend bundle;
- public error messages stay user-friendly;
- admin-only wording does not leak into public storefront;
- no unexpected 5xx appears during the test window.

## Launch Blockers

Do not launch if any item is true:

- guests can create orders, create payments, or query orders without login;
- checkout works while logged out;
- Telegram or non-intersection SKUs appear publicly;
- any enabled payment channel fails callback/webhook verification;
- one paid order can create duplicate provider submissions;
- TGX account secret is visible to the wrong user;
- public pages expose provider/upstream/API/procurement wording;
- sitemap or SEO metadata uses temporary domains;
- admin cannot disable payment channel or provider fulfillment quickly;
- logs expose secrets or account delivery data.

## Final E2E Sign-Off

| Role | Name | Result | Evidence |
| --- | --- | --- | --- |
| Product owner |  |  |  |
| Engineering owner |  |  |  |
| Operations owner |  |  |  |
| Payment owner |  |  |  |
