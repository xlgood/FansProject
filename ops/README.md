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
