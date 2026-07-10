# Final Project Audit

Date: 2026-07-10

## Scope

This audit checks the repository handoff state before the project moves from
implementation and launch preparation into real production configuration.

The root repository is expected to track coordination assets only:

- project documentation;
- production templates;
- launch and operations scripts;
- patch archives for changes made inside cloned upstream source directories.

The cloned source directories are intentionally not tracked by the root
repository:

- `dujiao-next/`
- `user/`
- `admin/`
- `document/`

Each cloned source directory keeps its own git history and should be committed
or archived separately when needed.

## Current Deliverables

Completed deliverables in the root repository:

- project scope, architecture, API, SKU, SEO, requirements, development, and
  coding-standard documents;
- development roadmap with completed phase records;
- production security, configuration, deployment, reverse proxy, operations,
  go-live, and launch acceptance documents;
- production Compose and Nginx templates;
- Gate 1 production audit input templates;
- read-only prelaunch audit script;
- patch archives for selected backend, user frontend, and admin frontend
  source changes.

Completed deliverables in cloned source worktrees include:

- FansGurus and TGX provider clients;
- catalog sync, Telegram exclusion, platform intersection, and price rules;
- admin manual catalog sync;
- order fulfillment submission, polling, retry-safe behavior, and user-safe
  public error wording;
- admin procurement diagnostics and manual status sync;
- automatic accepted-order status sync worker coverage;
- user/admin frontend integration and smoke verification;
- locale, SEO, sitemap, and branding readiness changes;
- production HTTP server timeout configuration;
- frontend Docker build argument fixes.

## Rules Verified

The implementation and documentation preserve the confirmed project rules:

- FansGurus prices use upstream `rate * 5`.
- FansGurus quantity basis, minimum quantity, and order increments stay aligned
  with the upstream per-1000 model.
- TGX prices use upstream `price * 1.2`.
- Telegram-related SKUs are excluded.
- Public catalog visibility is limited to the platform intersection between
  FansGurus and TGX.
- Target site currency is USD unless a payment channel performs its own
  gateway conversion.
- Public storefront copy must not expose provider, upstream, API routing, or
  procurement wording.
- Live provider order submission must not be executed during tests unless the
  project owner explicitly approves a low-value live test.

## Root Repository State

The root repository intentionally excludes cloned source worktrees through
`.gitignore`. The production Compose env example is explicitly allowed so the
template can be tracked without allowing real `.env.*` files:

- ignored: `/dujiao-next/`, `/user/`, `/admin/`, `/document/`;
- ignored by default: `.env.*`;
- tracked exception: `ops/compose/.env.production.example`.

The command below should return no tracked files from child source worktrees:

```bash
git ls-files dujiao-next user admin document
```

## Verification Run

Final root verification commands:

```bash
git diff --check
bash -n ops/prelaunch-audit.sh
jq . ops/gate1/site_config.json.example
```

Expected production-template audit behavior:

```bash
bash ops/prelaunch-audit.sh \
  --backend-config ops/compose/config.yml.production.example \
  --site-config ops/gate1/site_config.json.example \
  --user-env ops/gate1/user.env.production.example \
  --admin-env ops/gate1/admin.env.production.example \
  --skip-public-text
```

This template audit is expected to exit `1` because the example files still
contain `CHANGE_ME` and `FINAL_*` placeholders. That is the intended
fail-closed behavior. A production launch must copy these templates outside
tracked paths, replace all placeholders, and rerun the audit until it exits
`0`.

Secret fingerprint scan:

```bash
rg -n "OWNER_PROVIDED_SECRET_FINGERPRINTS" . \
  --glob '!dujiao-next/**' \
  --glob '!user/**' \
  --glob '!admin/**' \
  --glob '!document/**' \
  --glob '!**/.git/**'
```

Replace `OWNER_PROVIDED_SECRET_FINGERPRINTS` with non-public fingerprints
derived locally from the owner-provided credentials. Expected result: no hits.

## Not Verified Locally

The following items require a production-like environment or explicit owner
approval:

- Docker Compose rendering and image build on the final deployment host;
- Nginx config validation on the final deployment host;
- final domain runtime smoke;
- Alipay, WeChat Pay, and PayPal sandbox or low-value live payment tests;
- low-value live FansGurus and TGX fulfillment tests;
- final logo, favicon, OG image, legal pages, support contacts, and domain
  replacement.

## Launch Readiness Gate

The next launch step is Gate 1 from `docs/20-go-live-runbook.md`.

Launch remains blocked until:

- production config files contain no placeholders;
- `ops/prelaunch-audit.sh` exits `0`;
- automated tests and builds pass against production env values;
- final domain runtime smoke passes;
- payment acceptance passes;
- explicitly approved low-value provider acceptance passes;
- the sign-off table in `docs/25-launch-acceptance-checklist.md` is complete.
