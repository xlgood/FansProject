# Implementation Policy

## 1. Default Build Decision Order

For every new requirement, use this decision order before writing custom code:

1. Check whether the selected upstream base project, currently Dujiao-Next, already supports the requirement.
2. If Dujiao-Next does not support it, use the installed `find-skills` skill to search for existing mature skills, frameworks, libraries, or proven integrations that can implement the requirement.
3. Review GitHub, major social media discussions, and major developer/operator forums for mature existing solutions.
4. Prefer mature existing implementation paths over custom code when they meet the project requirements, license constraints, security expectations, and maintainability needs.
5. Write custom code only when no better existing framework, skill, or integration can satisfy the requirement.

This policy is mandatory for all future feature planning and implementation.

When custom code is required, implementation must follow `docs/08-coding-standards.md` and use the `karpathy-guidelines` skill for non-trivial work.

## 2. Required Evidence Before Custom Code

Before implementing a new feature from scratch, document:

- Requirement name.
- Whether Dujiao-Next supports it natively.
- `find-skills` search terms used.
- Candidate skills, plugins, frameworks, libraries, or open-source projects found.
- Why each candidate was accepted or rejected.
- Final implementation decision.

If `find-skills` is unavailable in the current execution environment, document that limitation and use available fallback research tools. Do not silently skip the research step.

## 3. Acceptance Rules For Existing Solutions

An existing solution can be adopted only if it satisfies these checks:

- It supports the required behavior without excessive rewrites.
- It has a compatible license.
- It can keep Fansgurus API keys server-side.
- It does not weaken payment, order, or admin security.
- It can integrate with Dujiao-Next or the chosen Website3 architecture.
- It is maintained enough for production use.
- It does not create unacceptable vendor lock-in unless explicitly approved.

## 4. Current Research Snapshot

Date: 2026-07-07

Scope:

- Fansgurus SKU sync.
- Fansgurus order forwarding.
- Upstream order status polling.
- 10x price multiplier.
- Dujiao-Next commerce integration.
- SEO/GEO storefront.
- IP-based default language selection.

Findings:

- Dujiao-Next remains the strongest known foundation for product, order, payment, admin, and delivery lifecycle.
- GitHub contains small SMM API clients and scripts, including PHP clients and simple service-list sync tools, but the visible candidates are low-star, narrow, or provider-specific.
- No mature, directly reusable Fansgurus-to-Dujiao-Next integration was found.
- `find-skills` is installed globally at `~/.codex/skills/find-skills/SKILL.md`.
- No mature skill found so far covers the complete Fansgurus SKU sync, pricing multiplier, fulfillment, and status polling workflow.
- Existing local or plugin skills may be useful for adjacent work, such as frontend testing, browser verification, security review, deployment guidance, and payment best practices, but they do not replace the core Fansgurus adapter.

Current decision:

- Use Dujiao-Next for commerce/order/payment/admin where practical.
- Build a Website3-specific Fansgurus adapter unless a better mature integration is found later through `find-skills` or mature framework/library research.
- Reuse mature framework/library capabilities for sub-problems such as GeoIP, i18n, caching, queueing, payment callbacks, and deployment rather than hand-rolling them.

## 5. Candidate Areas To Reuse

Prefer existing solutions for these areas:

- GeoIP: CDN country headers such as Cloudflare `CF-IPCountry`, MaxMind GeoLite2, or a reputable paid GeoIP provider.
- i18n: Dujiao-Next existing language structure, or the chosen frontend framework's mature i18n package.
- Queueing: Dujiao-Next-compatible queue/worker system or Redis-backed job processing.
- Payments: Dujiao-Next built-in payment integrations before custom gateway code.
- SEO rendering: SSR/SSG framework support instead of client-only rendering for landing pages.
- Testing: Playwright or equivalent browser automation for checkout, language, and mobile flows.
- Security: established auth, rate-limit, validation, and secret-management libraries.

## 6. Review Trigger

Re-run this research process when:

- A new major feature is requested.
- Dujiao-Next version changes significantly.
- Fansgurus API changes.
- A new marketplace skill/plugin becomes available.
- A production architecture decision is about to become expensive to reverse.
