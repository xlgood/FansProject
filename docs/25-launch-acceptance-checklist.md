# Launch Acceptance Checklist

Date: 2026-07-10

## Purpose

This is the final human acceptance checklist before public launch. It is used
after the technical gates in `docs/20-go-live-runbook.md` pass.

Launch is blocked until every required item has:

- result: pass;
- owner;
- evidence link or note;
- timestamp.

## Sign-Off Table

Use this table for the final launch record:

| Area | Owner | Result | Evidence | Timestamp |
| --- | --- | --- | --- | --- |
| Gate 1 audit |  |  |  |  |
| Tests and builds |  |  |  |  |
| Data initialization |  |  |  |  |
| Runtime smoke |  |  |  |  |
| Payment acceptance |  |  |  |  |
| Provider acceptance |  |  |  |  |
| Language/SEO/brand |  |  |  |  |
| Public wording/compliance |  |  |  |  |
| Rollback readiness |  |  |  |  |
| Final launch approval |  |  |  |  |

## Gate Evidence

Required:

- `ops/prelaunch-audit.sh` reports `0` failures.
- Backend tests pass.
- User frontend typecheck and build pass.
- Admin frontend typecheck and build pass.
- Runtime smoke on final domains passes.
- CORS check allows final origins and rejects unknown origins.
- Nginx config validates with `nginx -t`.
- Compose config renders with `docker compose config`.
- Production data initialization from
  `docs/31-production-data-initialization.md` is complete.

Evidence to attach:

- command output or CI link;
- image tag/version;
- final domain list;
- config revision or secure config checksum if operations uses one.

## Payment Acceptance

Use `docs/30-payment-launch-workbook.md` to record per-channel evidence.

Test each enabled payment channel:

- Alipay
- WeChat Pay
- PayPal

For each channel, record:

| Channel | Mode | Result | Payment ID | Order ID | Evidence |
| --- | --- | --- | --- | --- | --- |
| Alipay | sandbox / low-value live |  |  |  |  |
| WeChat Pay | sandbox / low-value live |  |  |  |  |
| PayPal | sandbox / low-value live |  |  |  |  |

Pass criteria:

- Customer can create payment from checkout.
- Payment page opens or QR renders correctly.
- Return URL uses final storefront domain.
- Callback/webhook URL uses final API domain.
- Signature verification succeeds where supported.
- Local payment reaches success.
- Local order reaches paid/fulfilling state.
- Amount and currency match configured channel behavior.
- If Alipay or WeChat Pay converts USD to CNY, stored gateway amount/currency
  matches callback data.
- Duplicate callback does not double-deliver or double-credit.
- Logs do not expose secrets.

Fail conditions:

- Any callback points to localhost, staging, or placeholder domain.
- Any channel exposes provider/payment secrets in frontend source or logs.
- Any amount/currency mismatch is unexplained.
- Any enabled channel cannot complete a payment.

## Provider Acceptance

Only run live provider tests with explicit approval and low-value orders.

Required provider checks:

| Provider | Test SKU | Quantity | Result | Local Order | Provider Ref | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| FansGurus |  |  |  |  |  |  |
| TGX Account |  |  |  |  |  |  |

Pass criteria:

- Telegram SKUs are absent before test.
- Non-intersection platforms are absent before test.
- FansGurus SKU price is upstream `rate * 5`.
- FansGurus quantity basis preserves upstream per-1000 rate, minimums, and
  increments.
- TGX SKU price is upstream `price * 1.2`.
- Paid local order creates one procurement order.
- Live submission creates one provider order/trade.
- Status sync moves local order forward without manual database edits.
- TGX delivered account secret is visible only to the buyer and authorized
  admins.
- Public order pages do not show provider, upstream, API, or procurement
  wording.

Fail conditions:

- Duplicate provider order is created for one local order.
- Telegram SKU appears anywhere in catalog, sitemap, search, or navigation.
- Non-intersection platform appears publicly.
- Provider credentials appear in logs or frontend.
- TGX account secret is visible to an unauthorized user.

## Language, SEO, And Brand

Required checks:

- `https://FINAL_DOMAIN/`
- `https://FINAL_DOMAIN/zh-CN`
- `https://FINAL_DOMAIN/zh-TW/products`
- `https://FINAL_DOMAIN/en/products`

Pass criteria:

- First visit language follows trusted country header or `Accept-Language`.
- Manual language override persists.
- `html lang` matches active locale.
- Canonical URL uses final HTTPS domain.
- `hreflang` includes `zh-CN`, `zh-TW`, `en`, and `x-default`.
- `sitemap.xml` uses final domain.
- `robots.txt` is reachable.
- Final favicon loads.
- Final logo loads.
- Final OG image loads.
- Public config returns final brand name and `currency: "USD"`.

Fail conditions:

- Any public page still points to localhost, staging, or placeholder domain.
- Any required locale route returns `404`.
- Any brand asset returns `404`.
- Sitemap publishes Telegram or non-intersection platform pages.

## Public Wording And Compliance

Required checks:

- Product titles and descriptions.
- Checkout copy.
- Payment copy.
- Order detail copy.
- Error messages.
- Terms of service.
- Privacy policy.
- Refund/digital delivery policy.
- About/contact/footer pages.

Pass criteria:

- No public copy mentions upstream providers, API routing, procurement, or
  manual operator workflows.
- Copy does not imply affiliation with social platforms.
- Copy does not promise delivery/refill/cancel behavior unless supported by
  the SKU/provider mapping.
- Age, acceptable-use, refund, and digital delivery terms are visible before or
  during checkout.
- Support contact is final and monitored.
- Telegram support links are disabled unless explicitly approved; Telegram SKUs
  remain excluded either way.

Suggested scan:

```bash
rg -n -i "fansgurus|tgx|upstream|procurement|provider page|provider api|api routing" user/src docs ops
```

Review any hit manually. Admin-only docs may mention provider details; public
frontend copy must not.

## Admin And Access

Pass criteria:

- Default admin password is not configured.
- Owner/admin accounts use strong passwords.
- 2FA is enabled for owner/admin accounts.
- Admin roles are least privilege.
- Payment settings access is limited.
- Provider settings access is limited.
- Refund and manual finance actions are limited.
- Admin domain/path is not advertised publicly.
- Admin login rate limiting is active.

## Rollback Acceptance

Before final launch approval, confirm:

- Previous image tags are known.
- Previous backend config is restorable.
- Previous frontend env values are restorable.
- Previous Nginx config is restorable.
- Database backup or restore point exists.
- Operations can disable payment channels.
- Operations can disable provider connections or stop `worker`.
- Operations can rotate payment/provider/JWT/SMTP secrets.
- Operations has the incident priorities from `docs/24-operations-runbook.md`.

## Final Approval

Launch can proceed only when all required sections are pass.

Final approvers:

| Role | Name | Approval | Timestamp |
| --- | --- | --- | --- |
| Product owner |  |  |  |
| Engineering owner |  |  |  |
| Operations owner |  |  |  |
| Finance/payment owner |  |  |  |
| Compliance/content owner |  |  |  |

Post-launch required actions:

- Monitor payment callbacks.
- Monitor provider submission failures.
- Monitor accepted-order sync.
- Monitor auth failures and rate-limit blocks.
- Re-run Gate 1 after any config/domain/payment/provider change.
