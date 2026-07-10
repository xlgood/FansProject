# Production Security And Compliance Checklist

Date: 2026-07-10

## Purpose

Block production launch until secrets, public wording, payment callbacks,
browser security, and admin access controls are production-ready.

This checklist is based on the current Go/Gin backend, Vue/Vite user frontend,
Vue/Vite admin frontend, and the target business rule that public pages must not
expose upstream provider or internal procurement wording.

## Launch Blockers

These must be completed before any public production launch:

- Replace all default secrets in `dujiao-next/config.yml`:
  - `app.secret_key`
  - `jwt.secret`
  - `user_jwt.secret`
  - `bootstrap.default_admin_password`
  - any enabled email, payment, Telegram, provider, or channel secrets
- Set backend mode to production:
  - `server.mode: release`
- Lock CORS to final origins:
  - remove `cors.allowed_origins: ["*"]`
  - list only final storefront/admin domains
  - keep `X-Lang` allowed
- Configure final public domains:
  - `site_config.brand.site_url`
  - payment return URLs
  - payment callback/webhook URLs
  - Telegram OIDC callback only if Telegram login remains enabled
- Do not deploy frontend dev servers:
  - do not expose `vite`
  - do not expose `vite preview`
  - build and serve `dist/` from production hosting
- Keep all provider secrets server-side:
  - FansGurus key
  - TGX app key
  - payment credentials
  - webhook secrets
  - Dujiao-Next channel/API secrets
- Verify public text does not reveal:
  - upstream providers
  - API routing
  - procurement internals
  - manual operator workflows
- Verify Telegram SKUs remain excluded from public catalog and sitemap.
- Verify non-intersection platforms are not published.
- Review configured Go `http.Server` production limits before direct internet
  exposure:
  - `ReadHeaderTimeout`
  - `ReadTimeout`
  - `WriteTimeout`
  - `IdleTimeout`
  - `MaxHeaderBytes`
  The application now exposes these under `server.*` in `config.yml`; keep
  non-zero values in production and document any stricter reverse-proxy limits.

## Secrets And Configuration

Required checks:

```bash
rg -n "your-secret-key-change-in-production-please|user-secret-key-change-in-production-please|Admin12345|your-password|your-username" dujiao-next config.yml .env* docs
rg -n "fansgurus|app_key|api_key|secret|password|token" user/src admin/src
```

Rules:

- No real secret may appear in root git history, frontend source, frontend
  `.env`, docs, screenshots, or patch files.
- Frontend `VITE_*` variables are public; never place provider keys or payment
  secrets there.
- Provider credentials must live in backend secrets/admin settings only.
- Logs must redact credentials and delivery secrets.
- Production config files containing secrets must not be world-readable.

## Admin And Authentication

Required checks:

- Change default admin username/password before exposing admin.
- Enforce strong admin passwords.
- Enable 2FA for owner/admin accounts before launch.
- Review admin roles for least privilege:
  - provider catalog sync
  - procurement retry/status sync
  - payment channel settings
  - site settings
  - user/account management
- Confirm admin route is not the default public `/admin` if using fullstack
  routing:
  - set `web.admin_path` to a non-default path
- Confirm admin login rate limiting is active.
- Confirm user registration policy is intentional:
  - open registration
  - email verification
  - allowed email domains, if required

## Public API And CORS

Required checks:

```bash
curl -i -X OPTIONS \
  -H "Origin: https://FINAL_STOREFRONT_DOMAIN" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: x-lang,authorization" \
  https://FINAL_API_DOMAIN/api/v1/public/config

curl -i -X OPTIONS \
  -H "Origin: https://UNTRUSTED_EXAMPLE_DOMAIN" \
  -H "Access-Control-Request-Method: GET" \
  https://FINAL_API_DOMAIN/api/v1/public/config
```

Pass criteria:

- Final storefront/admin origins are allowed.
- Unknown origins are not allowed.
- `Access-Control-Allow-Credentials` is not paired with wildcard origins.
- `X-Lang` remains in allowed headers.

## Payment And Webhooks

Required checks:

- Alipay, WeChat Pay, and PayPal channels are configured only with production or
  explicitly selected sandbox credentials.
- Callback URLs use final HTTPS domains.
- Webhook signature verification is enabled for every provider that supports it.
- Payment return URLs do not use localhost/staging.
- Payment channel branding shows final merchant/brand names.
- Failed or duplicate callbacks are logged without exposing secrets.
- Refund/manual refund permissions are restricted to authorized admin roles.

## Provider Integration Safety

Required checks:

- Real upstream order submission remains disabled in tests and smoke scripts.
- Any live provider sync is an explicit admin action or scheduled job with
  production credentials intentionally configured.
- FansGurus and TGX request/response logs redact:
  - API keys
  - signatures
  - account delivery secrets
  - customer contact/order form values where sensitive
- Ambiguous provider submit behavior does not create duplicate orders.
- TGX delivered account secrets are visible only to the buyer and authorized
  admins.
- Admin diagnostics may mention provider/upstream details; public frontend must
  not.

## Frontend Browser Security

Required checks:

```bash
rg -n "v-html|innerHTML|insertAdjacentHTML|eval\\(|new Function|document.write|localStorage" user/src admin/src
```

Review rules:

- Every `v-html` or `innerHTML` usage must have an explicit trusted source or
  DOMPurify sanitization path.
- Legal/product/blog/order rich text must be sanitized or limited to trusted
  admin-authored content.
- Third-party custom scripts must be disabled or tightly controlled for launch.
- No auth, provider, or payment secrets may be stored in `localStorage`.
- Existing browser tokens in `localStorage` are a known inherited design choice;
  mitigate with strict CSP, no untrusted scripts, short token expiry, and 2FA.
- All external links opened with `target="_blank"` must use `rel="noopener"` or
  `rel="noopener noreferrer"`.

Recommended security headers at CDN/reverse proxy:

- `Content-Security-Policy`
- `X-Frame-Options` or CSP `frame-ancestors`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy`
- `Permissions-Policy`

Do not add HSTS until the final domain, TLS, redirects, and subdomain policy
are confirmed.

## Uploads And Media

Required checks:

- Keep upload size limit intentional:
  - default currently `10MB`
- Keep allowed MIME types/extensions intentional.
- SVG upload remains sanitized; current tests cover script tags, event handlers,
  `javascript:` URLs, and `foreignObject`.
- Uploaded files are served with safe content types.
- Uploaded media URLs do not expose private filesystem paths.
- Brand assets return HTTP `200` before launch:
  - favicon
  - logo
  - OG image

## Domain, Proxy, And Locale

Required checks:

- Reverse proxy passes the correct host.
- If reseller/domain routing trusts `X-Forwarded-Host`, set
  `reseller.trusted_forwarded_host: true` only behind a trusted proxy that
  strips untrusted incoming forwarded-host headers.
- `reseller.main_hosts` includes final main domains when reseller mode is
  enabled.
- Country headers for first-visit locale come only from trusted CDN/proxy.
- `sitemap.xml`, `robots.txt`, canonical links, and `hreflang` links use the
  final HTTPS domain.

## Compliance And Public Wording

Required checks:

- Public terms and privacy pages are finalized in all supported locales.
- Public product copy avoids deceptive guarantees and does not imply platform
  affiliation.
- Public copy does not promise delivery/refill/cancel behavior unless supported
  by the SKU/provider mapping.
- Age, acceptable-use, refund, and digital delivery policies are visible before
  checkout.
- Admin compliance acknowledgement is reviewed before enabling live payment.

## Verification Commands

Run before launch:

```bash
cd dujiao-next
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go test ./internal/router ./internal/http/handlers/public ./internal/http/handlers/admin ./internal/service ./internal/upstream

cd ../user
./node_modules/.bin/vue-tsc -b
./node_modules/.bin/vite build

cd ../admin
./node_modules/.bin/vue-tsc -b
./node_modules/.bin/vite build
```

Runtime smoke:

```bash
curl -I https://FINAL_DOMAIN/
curl -I https://FINAL_DOMAIN/zh-CN
curl -I https://FINAL_DOMAIN/zh-TW/products
curl -I https://FINAL_DOMAIN/en/products
curl -i https://FINAL_DOMAIN/api/v1/public/config
curl -i https://FINAL_DOMAIN/sitemap.xml
curl -i https://FINAL_DOMAIN/robots.txt
```

## Go-Live Decision

Launch is blocked until all launch blockers are closed and the runtime smoke
passes on the final domain.

After launch:

- Rotate any secret that was used in staging or shared during development.
- Monitor payment callbacks, procurement failures, auth failures, and rate-limit
  blocks.
- Keep a rollback path for disabling payment channels and provider sync without
  redeploying code.
