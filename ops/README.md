# Operations

Reserved for deployment and runtime notes.

Initial production assumptions:

- PostgreSQL for persistent catalog, order, and sync state.
- Redis for cache, queues, locks, and rate limiting.
- CDN in front of static storefront assets.
- Scheduled workers for SKU sync and order status polling.
- Monitoring for upstream API latency, sync failures, order forwarding failures, and payment callbacks.

API keys and payment secrets must be injected through environment variables or the deployment secret manager.

## Prelaunch Audit

Run the read-only production audit before any public launch:

```bash
bash ops/prelaunch-audit.sh \
  --backend-config /path/to/production/config.yml \
  --site-config /path/to/site_config.json \
  --user-env /path/to/user.env.production \
  --admin-env /path/to/admin.env.production
```

The script reports:

- `FAIL`: launch-blocking configuration issues.
- `WARN`: missing files or wording that needs manual review.
- `PASS`: checks that matched the launch policy.

It checks release mode, default secrets, CORS wildcard origins, `X-Lang`,
HTTP server limits, `site_config.currency: USD`, final HTTPS `site_url`,
frontend `VITE_API_BASE_URL`, frontend secret-like env names, and public
frontend wording that may expose provider/API/procurement internals.
Template placeholders such as `CHANGE_ME` and `FINAL_*` are treated as
launch-blocking failures in backend config files.

Gate 1 input templates live in `ops/gate1/`:

- `site_config.json.example`
- `user.env.production.example`
- `admin.env.production.example`

They intentionally contain placeholders. Copy them outside the repository and
replace all placeholders before using them as audit inputs.

## Nginx Template

Reverse proxy examples live in `ops/nginx/`:

- `target-site.conf.example`
- `target-proxy-headers.conf.example`

Copy them outside the repository, replace all `FINAL_*` placeholders and TLS
certificate paths, then validate with `nginx -t` before reload.

## Compose Template

Separated deployment scaffolding lives in `ops/compose/`:

- `docker-compose.production.yml`
- `.env.production.example`
- `config.yml.production.example`

Copy `.env.production.example` outside the repository before adding real
secrets. Copy `config.yml.production.example` outside the repository before
adding backend secrets, then run Compose with
`--env-file /secure/path/target.env`.

## Operations Runbook

Production operations procedures are documented in
`docs/24-operations-runbook.md`, including start, stop, restart, logs, health
checks, payment/provider disablement, rollback, and incident priorities.
