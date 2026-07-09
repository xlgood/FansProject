# Patch 0001: Provider Catalog Sync Button

Date: 2026-07-09

Source tree:

```text
admin/
```

## Purpose

This patch adds an admin frontend entry point for the provider catalog manual
sync endpoint.

## Scope

Connection management page:

- Add a `Sync Provider Catalog` button.
- Show the button only when the current admin has
  `POST:/admin/provider-catalog/sync`.
- Auto-select the first `fansgurus` connection and the first `tgx-account`
  connection from the current connection list.
- Confirm before syncing.
- Show a localized success message with imported, filtered, and deactivated
  counts.
- Add `fansgurus` and `tgx-account` to the connection protocol selector.

API/types/i18n:

- Add `adminAPI.syncProviderCatalog`.
- Add `ProviderCatalogSyncResult`.
- Add Simplified Chinese, Traditional Chinese, and English UI strings.

## Verification

Passed:

```text
cd admin && ./node_modules/.bin/vue-tsc -b
cd admin && ./node_modules/.bin/vite build
```

Note:

```text
cd admin && pnpm run build
```

did not reach project compilation because pnpm attempted to switch to
`pnpm@10.34.3` and could not verify/download that release in this environment.
The equivalent local binaries passed.
