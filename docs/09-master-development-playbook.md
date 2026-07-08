# Master Development Playbook

## Step 1: Confirm Inputs

- Dujiao-Next source paths:
  - `dujiao-next/`
  - `user/`
  - `admin/`
  - `document/`
- FansGurus API key configured in local `.env` or deployment secret.
- TGX `app_id` and `app_key` configured in local `.env` or deployment secret.
- Currency policy: USD for display and settlement.
- Payment providers: Alipay, WeChat Pay, PayPal.
- Public domain and admin domain.
- TGX price base: `price`.
- Root repository source policy: cloned Dujiao-Next source directories are ignored by the root repo and keep their own git histories.
- Environment strategy: one root `.env` for integration settings.

## Step 2: Run Clean Dujiao-Next

- Backend starts.
- User frontend starts.
- Admin frontend starts.
- Database migrations work.
- Queue/Redis works.
- Payment sandbox or mock flow works.

## Step 3: Add Provider Settings

- FansGurus credentials.
- TGX credentials.
- Provider health checks:
  - FansGurus `balance`.
  - TGX `/shared/authentication/connect`.

## Step 4: Add Catalog Sync

- Pull FansGurus services.
- Pull TGX items.
- Store raw payloads.
- Normalize platforms.
- Exclude Telegram.
- Compute intersection.
- Publish active SKUs.

## Step 5: Add Pricing

- FansGurus multiplier `5`.
- TGX multiplier `1.2`.
- Admin-visible upstream cost and target price.
- Locked order price snapshots.

## Step 6: Add Fulfillment

- FansGurus order creation and polling.
- TGX trade creation, secret storage, and query polling.
- Retry and idempotency.
- Admin failure review.

## Step 7: Add Language And SEO

- Locale-prefixed routes.
- IP-based first-visit default.
- Manual language cookie/profile setting.
- `hreflang` and sitemap.
- Platform and intent pages based only on active intersection platforms.

## Step 8: Test

- Unit:
  - platform alias mapping;
  - Telegram exclusion;
  - price math;
  - TGX signing;
  - FansGurus payload construction.
- Integration:
  - sync with mocked upstreams;
  - checkout to queued fulfillment;
  - fulfillment retry;
  - TGX secret delivery;
  - order status polling.
- UI:
  - desktop and mobile catalog browsing;
  - language switching;
  - checkout forms.

## Step 9: Launch Readiness

- Production secrets rotated and configured.
- PostgreSQL and Redis ready.
- HTTPS and callback URLs configured.
- CORS locked to real domains.
- Payment provider webhooks verified.
- Upstream balances funded.
- Admin emergency disable controls verified.
- Backups configured.
- Logs and alerts configured.

## Stop Conditions

Stop and ask before:

- placing real upstream orders;
- using real payment credentials;
- changing production DNS;
- deleting old project files that may still contain needed history;
- committing or pushing changes.
