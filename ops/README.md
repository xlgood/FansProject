# Operations

Reserved for deployment and runtime notes.

Initial production assumptions:

- PostgreSQL for persistent catalog, order, and sync state.
- Redis for cache, queues, locks, and rate limiting.
- CDN in front of static storefront assets.
- Scheduled workers for SKU sync and order status polling.
- Monitoring for upstream API latency, sync failures, order forwarding failures, and payment callbacks.

API keys and payment secrets must be injected through environment variables or the deployment secret manager.
