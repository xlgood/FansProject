# ADR 0001: Project Baseline

Date: 2026-07-07

## Status

Accepted

## Context

Website3 is a reseller storefront backed by Fansgurus upstream services and a
Dujiao-Next based commerce/order foundation.

The current repository is an orchestration and implementation workspace. It
contains planning documents, placeholder application directories, operations
notes, and Dujiao-Next patch notes. It does not currently contain Dujiao-Next
source code or production application code.

The project has these fixed requirements:

- Fansgurus is the upstream provider at `https://fansgurus.com/api/v2`.
- Fansgurus API keys must remain server-side and must not be committed.
- Website3 sell prices are `Fansgurus upstream rate * 10`.
- Public storefront pages must support `en`, `zh-CN`, and `zh-TW`.
- First-visit language detection may use IP or edge country signals, but every
  locale must remain directly addressable through stable locale-prefixed URLs.
- Dujiao-Next should remain external unless vendoring is explicitly approved.
- Non-trivial implementation work must follow `docs/07-implementation-policy.md`
  and `docs/08-coding-standards.md`.

Baseline verification performed:

- `find-skills` is installed at `/Users/river/.codex/skills/find-skills/SKILL.md`.
- `karpathy-guidelines` is installed at
  `/Users/river/.codex/skills/karpathy-guidelines/SKILL.md`.
- `.env.example` contains an empty `FANSGURUS_API_KEY=`.
- No real Fansgurus API key was found in the repository during baseline search.
- The working directory is not currently a Git repository.

## Decision

1. Keep this repository as the Website3 orchestration and implementation
   workspace.
2. Keep Dujiao-Next source external. Use `patches/dujiao-next/` for integration
   notes, migration notes, and patch documentation unless the project owner
   explicitly approves vendoring.
3. Treat Dujiao-Next as the first reuse target for product, order, payment,
   admin, user, and delivery lifecycle behavior.
4. Build a Website3-specific Fansgurus adapter unless Phase 1 research finds a
   mature, compatible, maintained integration that satisfies project security
   and operational requirements.
5. Prefer an SSR/SSG-capable storefront implementation for SEO-critical public
   pages, catalog browsing, and locale-prefixed URLs.
6. Keep the Fansgurus adapter server-side only. The public storefront must read
   normalized Website3 catalog/order APIs and must never call Fansgurus directly.
7. Use decimal-safe money/rate handling in future implementation work.
8. Require short decision notes before custom implementations of non-trivial
   features, following `docs/07-implementation-policy.md`.

## Initial Implementation Direction

The next project phase is Phase 1: Upstream Research And Dujiao-Next Fit Check.

Phase 1 should produce an integration map that answers:

- Which Dujiao-Next modules are reused unchanged.
- Which Dujiao-Next modules need extension points or migrations.
- Where paid-order fulfillment can be hooked safely.
- Which queue or scheduler mechanism should run SKU sync, order forwarding, and
  status polling.
- How Dujiao-Next stores products, SKUs, orders, payments, admin records, and
  language files.
- Whether the Fansgurus adapter should be embedded in Dujiao-Next first or run
  as a sidecar worker.

## Consequences

- Implementation starts with evidence gathering instead of speculative code.
- Storefront and adapter scaffolding should wait until Dujiao-Next extension
  points and framework choices are confirmed.
- Any future real API key discovery must be treated as an incident: remove it,
  rotate the key, and document the event.
- Because the workspace is not currently a Git repository, commit history,
  branch-based review, and normal change tracking are unavailable until Git is
  initialized or the project is moved into a repository.

## Verification

The baseline is complete when:

- This ADR exists.
- Required skills are available.
- No real Fansgurus API key is present in repository files.
- Dujiao-Next remains referenced externally rather than vendored.
- The next actionable task is Phase 1 integration research.
