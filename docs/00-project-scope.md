# Project Scope

## Goal

Build a reseller platform on top of Dujiao-Next that aggregates:

- FansGurus fan/growth services.
- TGX Account account-purchase products.

The target site should behave as one storefront and admin system. Customers should be able to browse a supported platform, choose either fan/growth service SKUs or account-purchase SKUs, pay on the target site, and receive fulfillment or status updates through the Dujiao-Next order lifecycle.

## In Scope

- Use Dujiao-Next as the base system instead of rebuilding commerce from scratch.
- Integrate FansGurus API for fan/growth SKUs.
- Integrate TGX Account shared API for account SKUs.
- Synchronize upstream SKU lists, prices, inventory/status where available, and local availability.
- Exclude every SKU that contains Telegram or Telegram-related wording.
- Use independent provider allowlists after Telegram exclusion:
  - FansGurus: X, Instagram, Facebook, TikTok, YouTube, VK, Spotify, Discord,
    Twitch, Reddit, LinkedIn, GitHub, Quora, WhatsApp, Line Voom, Threads.
  - TGX: X, Facebook, Instagram, YouTube, TikTok, Google/Gmail, Threads,
    LinkedIn, GitHub, Reddit, Discord, Outlook/Hotmail and overseas email.
- Calculate local prices from each connection's exchange rate, markup, and
  rounding configuration. Administrators can keep per-SKU prices manual.
- Use decimal arithmetic for all money calculations.
- Preserve upstream raw payloads for audit and troubleshooting.
- Support Simplified Chinese, Traditional Chinese, and English.
- Choose first-visit default language from IP geolocation, with `Accept-Language` fallback and manual override.
- Use Dujiao-Next payment, order, user, admin, and delivery primitives where practical.
- Add provider adapters, sync jobs, queue jobs, and admin views only where Dujiao-Next does not already cover the need.
- Maintain SEO-friendly multilingual URLs and crawlable landing pages.
- Support Alipay, WeChat Pay, and PayPal if available through Dujiao-Next payment integrations.
- Reserve a domain-driven brand asset layer for favicon, logo, site images, site name, and domain-specific public text.

## Out Of Scope For Initial Planning

- Storing real upstream API credentials in git.
- Placing real test orders upstream without explicit approval.
- Selling Telegram-related products or services.
- Selling a platform or SKU outside that provider's explicit allowlist.

## Current Clarity

The product direction, upstream roles, pricing rules, SKU filtering rules, and Dujiao-Next reuse strategy are clear.

Confirmed implementation inputs:

- Dujiao-Next source exists in the current project directory:
  - `dujiao-next/`
  - `user/`
  - `admin/`
  - `document/`
- FansGurus API credentials have been provided out of band and must be configured through secrets.
- TGX credentials have been provided out of band and must be configured through secrets.
- TGX markup base field is `price`.
- Payment target is Alipay, WeChat Pay, and PayPal.
- Display and settlement currency is USD.
- Integration settings use a single root `.env`.
- Cloned upstream source directories are not tracked by this root repository.

Remaining uncertainties are operational:

- Launch domain names for storefront, admin, and callbacks.
- Whether the TGX proxy/agent docs contain additional bulk-pricing or reseller-specific endpoints beyond the public shared API.

See `docs/10-open-questions.md`.
