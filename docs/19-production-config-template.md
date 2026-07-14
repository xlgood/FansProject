# Production Configuration Template

Date: 2026-07-10

## Purpose

This document is the production configuration worksheet for the target site.
Use it after the final domain, merchant accounts, Redis, database, and provider
credentials are ready.

Do not commit real secrets. Keep production values in the deployment secret
store or the production-only `dujiao-next/config.yml`.

## Domain Placeholders

Replace these placeholders before launch:

- `https://FINAL_DOMAIN`: customer storefront.
- `https://FINAL_ADMIN_DOMAIN`: admin frontend or admin route.
- `https://FINAL_API_DOMAIN`: backend API domain. This can be the storefront
  domain if API and frontend share a host.
- `FINAL_SITE_NAME`: public brand name.
- `FINAL_SUPPORT_EMAIL`: support mailbox.

Temporary copy can continue using generated placeholder domains until launch.

## Backend Config Template

Start from `dujiao-next/config.yml.example`, then apply this production shape:

```yaml
app:
  secret_key: "${APP_SECRET_KEY}"
  totp_issuer: "FINAL_SITE_NAME"

server:
  host: 0.0.0.0
  port: 8080
  mode: release
  read_header_timeout_seconds: 5
  read_timeout_seconds: 30
  write_timeout_seconds: 60
  idle_timeout_seconds: 120
  max_header_bytes: 1048576

database:
  driver: postgres
  dsn: "${DATABASE_DSN}"
  pool:
    max_open_conns: 25
    max_idle_conns: 10
    conn_max_lifetime_seconds: 3600
    conn_max_idle_time_seconds: 600

jwt:
  secret: "${ADMIN_JWT_SECRET}"
  expire_hours: 24

user_jwt:
  secret: "${USER_JWT_SECRET}"
  expire_hours: 24
  remember_me_expire_hours: 168

bootstrap:
  default_admin_username: ""
  default_admin_password: ""

telegram_auth:
  enabled: false
  bot_username: ""
  bot_token: ""
  client_secret: ""
  oidc_redirect_uri: ""
  mini_app_url: ""

redis:
  enabled: true
  host: "${REDIS_HOST}"
  port: 6379
  password: "${REDIS_PASSWORD}"
  db: 0
  prefix: "target"

queue:
  enabled: true
  host: "${REDIS_HOST}"
  port: 6379
  password: "${REDIS_PASSWORD}"
  db: 1
  concurrency: 10
  queues:
    default: 10
    critical: 5
  upstream_sync_interval: "30m"

cors:
  allowed_origins:
    - "https://FINAL_DOMAIN"
    - "https://FINAL_ADMIN_DOMAIN"
  allowed_methods:
    - GET
    - POST
    - PUT
    - PATCH
    - DELETE
    - OPTIONS
  allowed_headers:
    - Content-Type
    - Content-Length
    - Accept-Encoding
    - Authorization
    - Cache-Control
    - X-Requested-With
    - X-CSRF-Token
    - X-Lang
  allow_credentials: true
  max_age: 600

security:
  login_rate_limit:
    window_seconds: 300
    max_attempts: 5
    block_seconds: 900
  password_policy:
    min_length: 12
    require_upper: true
    require_lower: true
    require_number: true
    require_special: true

email:
  enabled: true
  host: "${SMTP_HOST}"
  port: 465
  username: "${SMTP_USERNAME}"
  password: "${SMTP_PASSWORD}"
  from: "FINAL_SUPPORT_EMAIL"
  from_name: "FINAL_SITE_NAME"
  use_tls: false
  use_ssl: true

order:
  payment_expire_minutes: 15
  max_refund_days: 30

reseller:
  enabled: false
  main_hosts:
    - "FINAL_DOMAIN"
  trusted_forwarded_host: false
  subdomain_base: ""
  self_apply_enabled: false
  settlement_confirm_days: 7

web:
  admin_path: "/console-private"
```

Notes:

- Use PostgreSQL for production unless operations explicitly accepts SQLite.
- Leave `bootstrap.default_admin_*` empty after the first admin account exists.
- Keep Telegram login disabled unless the business explicitly enables it.
  Telegram SKUs stay excluded either way.
- If the app sits behind a trusted CDN/reverse proxy, configure host and country
  headers there and keep untrusted forwarded host headers stripped.

## Site Config Template

Set Dujiao-Next setting key `site_config`:

```json
{
  "currency": "USD",
  "brand": {
    "site_name": "FINAL_SITE_NAME",
    "site_url": "https://FINAL_DOMAIN",
    "site_icon": "/uploads/brand/favicon.png",
    "site_description": {
      "zh-CN": "一站式社媒增长与账号服务平台。",
      "zh-TW": "一站式社媒成長與帳號服務平台。",
      "en-US": "One storefront for social growth and account services."
    }
  },
  "seo": {
    "title": {
      "zh-CN": "FINAL_SITE_NAME",
      "zh-TW": "FINAL_SITE_NAME",
      "en-US": "FINAL_SITE_NAME"
    },
    "keywords": {
      "zh-CN": "社媒增长,账号服务",
      "zh-TW": "社媒成長,帳號服務",
      "en-US": "social growth,account services"
    },
    "description": {
      "zh-CN": "购买社媒增长服务与账号服务。",
      "zh-TW": "購買社媒成長服務與帳號服務。",
      "en-US": "Buy social growth services and account services."
    },
    "default_og_image": "/uploads/brand/og-default.png"
  },
  "contact": {
    "email": "FINAL_SUPPORT_EMAIL",
    "telegram": "",
    "whatsapp": ""
  },
  "footer_links": [],
  "nav_config": {
    "builtin": {
      "blog": true,
      "notice": true,
      "about": true
    },
    "custom_items": []
  }
}
```

Required checks:

- `currency` must be `USD` for the target site unless finance changes the
  settlement decision.
- `brand.site_url` must be absolute HTTPS and have no trailing slash.
- Public text must not mention provider names, upstream APIs, procurement, or
  manual operator workflows.

## Payment Channels

Enable only the required launch channels:

- Alipay: `provider_type=official`, `channel_type=alipay`.
- WeChat Pay: `provider_type=official`, `channel_type=wechat`.
- PayPal: `provider_type=official`, `channel_type=paypal`.

Production callback URLs:

- Generic payment callback:
  `https://FINAL_API_DOMAIN/api/v1/payments/callback`
- PayPal webhook:
  `https://FINAL_API_DOMAIN/api/v1/payments/webhook/paypal`
- WeChat Pay webhook/notify URL:
  `https://FINAL_API_DOMAIN/api/v1/payments/callback`
- Alipay notify URL:
  `https://FINAL_API_DOMAIN/api/v1/payments/callback`
- Alipay return URL:
  `https://FINAL_DOMAIN/orders`

Currency handling:

- Storefront product prices and local order settlement should use `USD`.
- PayPal can receive `USD` when the merchant account supports it.
- Official Alipay and WeChat Pay commonly require `CNY`. If the selected
  merchant account requires CNY, configure the payment channel `config_json`
  with the channel-supported target currency and `exchange_rate`, then verify
  that payment rows store the actual gateway amount/currency for callbacks.
- Do not enable a payment channel until a sandbox or low-value production
  callback succeeds end to end.

Required payment channel checks:

- Credentials are stored only in backend/admin configuration, never frontend
  `.env` or source.
- Webhook or callback signature verification is enabled where supported.
- Channel display names and icons use final brand assets.
- Failed callbacks log payment IDs and channel IDs, not secrets.

## Provider Connections

Configure provider credentials only in backend/admin provider settings:

- FansGurus connection:
  - protocol: `fansgurus`
  - API key: production secret
  - pricing rule: exchange rate `1`, configured markup/rounding, or a manual SKU price
  - quantity basis: preserve upstream per-1000 basis, minimums, and increments
- TGX connection:
  - protocol: `tgx-account`
  - app ID: production secret
  - app key: production secret
  - pricing rule: CNY-to-USD exchange rate plus configured markup/rounding, or a manual SKU price

Catalog policy that must remain active:

- Exclude all Telegram-related SKUs.
- Publish only platforms present in both FansGurus and TGX catalogs.
- Hide stale provider mappings when they disappear from a filtered sync.
- Keep target catalog prices in USD unless finance changes the settlement
  decision.

Operational switches:

- Manual catalog sync is available from admin.
- Periodic accepted-order status sync is handled by the worker.
- Live provider order submission must be tested only with explicit approval and
  low-value orders.

## Frontend Build Environment

User frontend production build should point to the production API:

```bash
VITE_API_BASE_URL=https://FINAL_API_DOMAIN
```

Admin frontend production build should point to the same production API:

```bash
VITE_API_BASE_URL=https://FINAL_API_DOMAIN
VITE_ADMIN_PATH=/console-private
```

Rules:

- Do not deploy Vite dev servers.
- Build and serve `dist/` from the selected static hosting/CDN.
- Do not include `/api/v1` in `VITE_API_BASE_URL`; both frontends append that
  prefix internally.
- `VITE_*` values are public. Do not put provider, payment, JWT, SMTP, or admin
  secrets there.

## Reverse Proxy And Headers

Terminate TLS before traffic reaches the app or on the app host.

Required proxy behavior:

- Redirect HTTP to HTTPS.
- Preserve `Host`.
- Pass a single trusted country header for first-visit locale:
  - `CF-IPCountry`, `CloudFront-Viewer-Country`, `X-Vercel-IP-Country`, or
    `X-Country-Code`.
- Strip untrusted incoming `X-Forwarded-Host`.
- Set security headers at CDN/proxy:
  - `Content-Security-Policy`
  - `X-Frame-Options` or CSP `frame-ancestors`
  - `X-Content-Type-Options: nosniff`
  - `Referrer-Policy`
  - `Permissions-Policy`

Do not enable HSTS until final TLS, redirects, and subdomain policy are
verified.

## Go-Live Verification

Run these checks on the final domain:

```bash
curl -I https://FINAL_DOMAIN/
curl -I https://FINAL_DOMAIN/zh-CN
curl -I https://FINAL_DOMAIN/zh-TW/products
curl -I https://FINAL_DOMAIN/en/products
curl -i https://FINAL_API_DOMAIN/api/v1/public/config
curl -i https://FINAL_DOMAIN/sitemap.xml
curl -i https://FINAL_DOMAIN/robots.txt
```

Run these checks against CORS:

```bash
curl -i -X OPTIONS \
  -H "Origin: https://FINAL_DOMAIN" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: x-lang,authorization" \
  https://FINAL_API_DOMAIN/api/v1/public/config

curl -i -X OPTIONS \
  -H "Origin: https://UNTRUSTED_EXAMPLE_DOMAIN" \
  -H "Access-Control-Request-Method: GET" \
  https://FINAL_API_DOMAIN/api/v1/public/config
```

Pass criteria:

- Public config returns `currency: "USD"` and final brand fields.
- CORS allows only final storefront/admin origins.
- Locale-prefixed pages render in the expected language.
- Sitemap and canonical links use the final HTTPS domain.
- Telegram and provider-disallowed SKUs are absent.
- Checkout succeeds for each enabled payment channel.
- Paid order fulfillment succeeds through mocked or explicitly approved
  low-value live provider orders.

## Rollback Controls

Before launch, confirm operations can quickly:

- Disable every payment channel from admin.
- Disable provider connections or stop live order submission.
- Stop the queue worker.
- Rotate provider/payment/JWT/SMTP secrets.
- Roll back frontend `dist/` and backend binary/container versions.
