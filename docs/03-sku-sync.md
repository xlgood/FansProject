# SKU Sync And Catalog Policy

## Goals

- Import FansGurus fan/growth SKUs.
- Import TGX Account account SKUs.
- Exclude Telegram-related SKUs.
- Compute the platform intersection between the two providers.
- Publish only supported intersection platforms.
- Apply correct markup per provider.

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
5. Reject Telegram-related records before intersection.
6. Compute `supported_platforms = fansgurus_platforms ∩ tgx_platforms`.
7. Hide any SKU whose platform is not in `supported_platforms`.
8. Calculate target price.
9. Mark local SKU active only if upstream is active, platform is supported, and purchase form is supported.

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

FansGurus:

```text
target_price = fansgurus.rate * 5
```

TGX:

```text
target_price = tgx.price * 1.2
```

TGX base field is confirmed as `price`.

## Inventory Rules

FansGurus:

- No explicit inventory endpoint in the public API.
- Use service presence, min/max, status/order errors, and admin overrides.
- Missing upstream service should become inactive after a grace period, not deleted immediately.

TGX:

- Use `/shared/commodity/inventory` for count and pricing details.
- Use `/shared/commodity/inventoryState` before purchase when practical.
- Respect `minimum`.
- If inventory is hidden, treat product as purchasable only if provider says it is active and inventory checks pass.

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
- filtered non-intersection records;
- errors and sample error payloads.

## Admin Overrides

Admins need to:

- force-disable platform/category/SKU;
- override detected platform;
- override display title/description per locale;
- configure provider price multiplier;
- inspect raw upstream payload;
- retry failed sync;
- manually recalculate intersection.
