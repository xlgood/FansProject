# Reverse Proxy And CDN Template

Date: 2026-07-10

## Purpose

This document describes the minimum reverse proxy/CDN setup for the separated
deployment. It pairs with:

- `ops/nginx/target-site.conf.example`
- `ops/nginx/target-proxy-headers.conf.example`
- `docs/21-production-deployment-plan.md`

## Recommended Domain Split

Use three domains for first production launch:

- `https://FINAL_DOMAIN`
  - customer storefront
- `https://FINAL_ADMIN_DOMAIN`
  - admin frontend
- `https://FINAL_API_DOMAIN`
  - backend API, payment callbacks, webhooks, and health check

This keeps admin routing independent and avoids path conflicts between the API
and storefront SPA.

## Nginx Template

Copy templates outside git-tracked paths:

```bash
cp ops/nginx/target-site.conf.example /secure/path/nginx/target-site.conf
cp ops/nginx/target-proxy-headers.conf.example /secure/path/nginx/target-proxy-headers.conf
```

Replace:

- `FINAL_DOMAIN`
- `FINAL_ADMIN_DOMAIN`
- `FINAL_API_DOMAIN`
- certificate paths
- upstream ports if Compose host bindings differ

Do not deploy the `.example` files directly. They intentionally contain
placeholders and must be copied to production-managed paths first.

Default local upstream ports from `ops/compose/.env.production.example`:

- API: `127.0.0.1:8080`
- user frontend: `127.0.0.1:8081`
- admin frontend: `127.0.0.1:8082`

Validate before reload:

```bash
nginx -t -c /secure/path/nginx/nginx.conf
```

## Required Routes

Storefront domain:

- `/`
  - user frontend
- `/zh-CN`, `/zh-TW/*`, `/en/*`
  - user frontend
- `/api/v1/*`
  - backend, only if API and storefront share this domain
- `/health`
  - user frontend health

Admin domain:

- `/*`
  - admin frontend
- `/health`
  - admin frontend health

API domain:

- `/health`
  - backend health
- `/api/v1/*`
  - backend
- `/api/v1/payments/callback`
  - backend
- `/api/v1/payments/webhook/paypal`
  - backend

All other API-domain paths should return `404`.

## Security Headers

The Nginx template sets:

- `Content-Security-Policy`
- `X-Frame-Options`
- `X-Content-Type-Options`
- `Referrer-Policy`
- `Permissions-Policy`

Do not enable HSTS until final TLS, redirects, and subdomain policy are tested.

If third-party payment SDKs, analytics, or support widgets are added later,
update CSP intentionally. Do not loosen CSP to wildcard sources.

## Upload Limit

The template uses:

```nginx
client_max_body_size 10m;
```

Keep this aligned with backend `upload.max_size`. If production increases one,
increase the other in the same deployment.

## Country Header For First-Visit Locale

The backend locale logic can consume country headers. Use only trusted CDN or
proxy-provided values.

The Nginx example maps:

- `CF-IPCountry`
- `CloudFront-Viewer-Country`

to:

- `X-Country-Code`

Rules:

- Do not trust user-supplied country headers from the public internet.
- If a CDN is in front of Nginx, strip incoming country/forwarded headers at
  the CDN edge and set the trusted header there.
- If Nginx is directly internet-facing, remove the map unless a trusted module
  or upstream proxy provides those headers.

## CORS Alignment

Backend `config.yml` must allow only final origins:

- `https://FINAL_DOMAIN`
- `https://FINAL_ADMIN_DOMAIN`

Keep `X-Lang` in `cors.allowed_headers`.

Run before launch:

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

- Final storefront/admin origins are allowed.
- Unknown origins are not allowed.
- Wildcard origin is absent.
- `X-Lang` is allowed.

## CDN Notes

Recommended CDN behavior:

- Redirect HTTP to HTTPS or let Nginx do it consistently, not both with
  conflicting rules.
- Cache static assets under `/assets/`.
- Do not cache:
  - `/api/v1/*`
  - payment callbacks
  - webhooks
  - `/index.html`
- Pass through payment callback and webhook request bodies unchanged.
- Preserve `Host`.
- Do not inject scripts into storefront or admin pages.

## Verification

After proxy reload:

```bash
curl -I https://FINAL_DOMAIN/
curl -I https://FINAL_ADMIN_DOMAIN/
curl -i https://FINAL_API_DOMAIN/health
curl -i https://FINAL_API_DOMAIN/api/v1/public/config
curl -i https://FINAL_DOMAIN/sitemap.xml
curl -i https://FINAL_DOMAIN/robots.txt
```

Also run Gate 3 in `docs/20-go-live-runbook.md`.
