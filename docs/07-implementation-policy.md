# Implementation Policy

## Reuse Order

For any missing requirement:

1. Check whether Dujiao-Next already supports it.
2. Check whether a mature library or framework feature supports it.
3. If it is a specialized workflow and not covered locally, use the installed `find-skills` skill to search for an existing skill before custom implementation.
4. Write custom code only when the above options do not fit.

## Dujiao-Next First

Prefer Dujiao-Next for:

- product and SKU storage;
- order lifecycle;
- payment callbacks;
- delivery records;
- user account flows;
- admin permissions;
- multilingual content shape;
- queue and worker behavior;
- upstream/site integration patterns.

## Custom Code Is Expected For

- FansGurus adapter.
- TGX adapter.
- platform normalization;
- Telegram exclusion;
- independent provider allowlists;
- connection-configured pricing and currency conversion;
- provider-specific fulfillment and polling;
- admin sync dashboard if not present.

## find-skills Usage

Use `find-skills` when a requirement is not directly present in Dujiao-Next and is likely reusable, for example:

- GeoIP language detection workflow;
- Vue i18n route strategy;
- payment webhook testing workflow;
- catalog sync testing workflow;
- SEO sitemap generation workflow.

Do not use `find-skills` to avoid reading the actual Dujiao-Next code. Local source inspection comes first.

## Build Constraints

- No real credentials in git.
- No frontend exposure of provider keys.
- No real upstream purchase tests without approval.
- No speculative features outside the documented requirements.
- No broad refactors of Dujiao-Next unless required by integration.
