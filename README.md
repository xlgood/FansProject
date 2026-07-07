# FansProject

Website3 project workspace for building a reseller storefront backed by Fansgurus services and a Dujiao-Next based commerce/order foundation.

## Project Direction

- Use Fansgurus as the upstream service provider through `https://fansgurus.com/api/v2`.
- Keep Dujiao-Next as an external open-source reference/base used during implementation, not vendored into this repository.
- Build a custom SEO-friendly storefront for desktop and mobile.
- Sync Fansgurus SKU, category, limits, features, and price changes into Website3.
- Price all Website3 SKUs at `Fansgurus upstream price * 10`.
- Support Simplified Chinese, Traditional Chinese, and English, with first-visit default language selected by visitor IP.

## Current Structure

- `apps/storefront/`: custom frontend UI/UX and SEO/GEO storefront work.
- `apps/fansgurus-adapter/`: upstream API adapter, SKU sync, order forwarding, status polling.
- `docs/`: product, architecture, API, sync, and SEO planning.
- `patches/dujiao-next/`: future patch notes or migration instructions for Dujiao-Next integration.
- `ops/`: deployment, runtime, monitoring, and operations notes.

## Important Notes

- Do not commit real API keys. Use `.env.example` as the template.
- Fansgurus `services` is a large JSON payload, so the production implementation must cache and persist it server-side.
- Fansgurus does not appear to provide SKU webhooks, so "real-time" SKU updates should be implemented as near-real-time polling.
- IP-based language detection should only choose the initial language. Users and search engines must still be able to access all language URLs directly.
- New requirements must follow the implementation policy in `docs/07-implementation-policy.md`: first check Dujiao-Next, then use the installed `find-skills` skill and mature framework/library research, and write custom code only when no better existing solution fits.
- Non-trivial coding work must follow `docs/08-coding-standards.md`, using the local `karpathy-guidelines` skill to keep changes simple, surgical, and verifiable.

## Key Documents

- `docs/05-requirements.md`: product requirements and acceptance criteria.
- `docs/06-development-guide.md`: implementation guide and data model notes.
- `docs/07-implementation-policy.md`: build-vs-reuse policy for Dujiao-Next, `find-skills`, and mature frameworks.
- `docs/08-coding-standards.md`: coding standards based on `karpathy-guidelines`.
- `docs/09-master-development-playbook.md`: full execution playbook covering implementation, errors, disaster recovery, performance, mobile/desktop optimization, testing, and launch.
