# SKU Sync And Catalog Policy

## Goals

- Import FansGurus fan/growth SKUs.
- Import TGX Account account SKUs.
- Exclude Telegram-related SKUs.
- Apply each provider's independent explicit platform allowlist.
- Preserve manual SKU prices unless the connection's automatic price sync is enabled.

## Normalization Pipeline

1. Pull upstream data.
2. Store raw payload unchanged.
3. Extract candidate platform from category, name, description, code, tags, and configured mapping rules.
4. Normalize aliases:
   - `x`, `twitter`, `twitter / x` -> `x`
   - `instagram`, `ig`, `ins` -> `instagram`
   - `tiktok`, `tik tok` -> `tiktok`
   - `facebook`, `fb` -> `facebook`
   - `youtube`, `yt` -> `youtube`
   - `telegram`, `tg`, `电报`, `飞机` -> `telegram`
5. Reject Telegram-related records before allowlist matching.
6. Keep FansGurus records only in its FansGurus allowlist; keep TGX records
   only in its TGX allowlist. Do not compute a cross-provider intersection.
7. Hide any SKU not allowed for its provider.
8. Store upstream cost; apply the connection's current price settings only when
   automatic price sync is enabled.
9. Mark local SKU active only if upstream is active, provider-allowed, and its purchase form is supported.

## Telegram Exclusion

Reject if any of these normalized fields contain Telegram-related tokens:

- provider category name;
- SKU/product name;
- description/content;
- code/slug;
- TGX widget/config labels;
- FansGurus service type/category text.

Initial exclusion tokens:

- `telegram`
- `tg`
- `电报`
- `飞机`
- `纸飞机`
- `t.me`
- `telegram bot`
- `telegram channel`
- `telegram group`

Avoid false positives by applying token boundaries for `tg` in English text, while allowing direct Chinese keyword matching.

## Price Rules

Use decimal arithmetic only.

FansGurus upstream amounts are USD and TGX `price` is CNY. Configure TGX's
CNY-to-USD exchange rate before synchronization. Store raw upstream prices for
reconciliation; the storefront and payment settlement remain USD. The
connection's markup and rounding rules calculate the price only when automatic
price sync is enabled; otherwise the administrator's per-SKU USD price remains.

TGX base field is confirmed as `price`.

## Inventory Rules

FansGurus:

- No explicit inventory endpoint in the public API.
- Use service presence, min/max, status/order errors, and admin overrides.
- Missing upstream service should become inactive after a grace period, not deleted immediately.

TGX:

- Use `/shared/commodity/inventory` for count and pricing details.
- Refresh all mapped TGX variants on the scheduled stock-sync job with bounded
  concurrency; use the single-SKU refresh only for diagnostics.
- Use `/shared/commodity/inventoryState` before purchase when practical.
- Respect `minimum`.
- If inventory is hidden, treat product as purchasable only if provider says it is active and inventory checks pass.

## Image Rules

- Do not download or retain per-SKU upstream product images.
- Every provider SKU uses the one local image assigned to its normalized platform
  (for example, all X products use the X image and all YouTube products use the
  YouTube image).
- Platforms without a dedicated asset use the local generic social image until
  operations supplies one platform-level replacement.

## Purchase Form Mapping

FansGurus:

- Map service `type` to required form fields.
- Disable purchase for unsupported types until implemented.
- Keep unsupported SKUs visible only if business wants "coming soon"; default is hidden from purchase.

TGX:

- Parse `widget` JSON into Dujiao-Next manual form schema.
- Parse `config` INI into selectable variants and prices.
- Pass selected `race`, contact, password, card ID, device, and widget fields into `/shared/commodity/trade`.

## Sync History

Every sync run should persist:

- provider;
- start and end time;
- status;
- upstream response size;
- total upstream records;
- imported records;
- updated records;
- deactivated records;
- filtered Telegram records;
- filtered provider-disallowed records;
- errors and sample error payloads.

## Admin Overrides

Admins need to:

- force-disable platform/category/SKU;
- override detected platform;
- override display title/description per locale;
- configure provider exchange rate, markup, rounding, and price-sync mode;
- inspect raw upstream payload;
- retry failed sync;
- review provider allowlist outcomes.
