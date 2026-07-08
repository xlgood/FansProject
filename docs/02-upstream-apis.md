# Upstream API Research

Research date: 2026-07-08.

## FansGurus

Source: `https://fansgurus.com/zh/api`

### Base

- Method: `POST`
- URL: `https://fansgurus.com/api/v2`
- Response: JSON
- Authentication: `key`

### Important Actions

- `services`: list available services.
- `add`: create order.
- `status`: query one or many orders.
- `refill`: create refill where supported.
- `refill_status`: query refill status.
- `balance`: check upstream balance.

### Service Fields

- `service`
- `name`
- `type`
- `category`
- `rate`
- `min`
- `max`
- `refill`
- `cancel`

### Order Form Types Observed In Docs

- Default package: `service`, `link`, `quantity`, optional `runs`, optional `interval`.
- Custom Comments: `service`, `link`, `comments`.
- Poll: `service`, `link`, `quantity`, `answer_number`.
- Invites from Groups: `service`, `link`, `quantity`, `groups`.
- Subscriptions: `service`, `username`, `min`, `max`, optional `posts`, `old_posts`, `delay`, `expiry`.

### Target Rules

- Exclude any FansGurus SKU where normalized text contains Telegram-related terms.
- Keep only SKUs whose normalized platform is in the cross-provider platform intersection.
- Target price = `rate * 5`.
- Currency policy: treat FansGurus upstream amounts as USD. FansGurus balance/order responses expose `currency` as `USD`.
- Upstream order creation must happen after local payment success.
- Store FansGurus order ID and poll `status`.

## TGX Account

Source: `https://www.tgxaccount.com/user/docs/api`

### Base

- Base URL: `https://www.tgxaccount.com/shared`
- Method: HTTP `POST`
- Content type: `application/x-www-form-urlencoded`
- Auth fields: `app_id`, `app_key`, `sign`
- Signing: MD5 over sorted request parameters, with `&key=<app_key>` appended.

### Important Endpoints

- `/shared/authentication/connect`: test credentials, shop name, balance.
- `/shared/commodity/items`: category tree and commodity list.
- `/shared/commodity/item`: query one commodity by code.
- `/shared/commodity/inventory`: inventory and pricing.
- `/shared/commodity/inventoryState`: stock sufficiency check.
- `/shared/commodity/trade`: buy commodity and receive trade number/secret where available.
- `/shared/commodity/draftCard`: preselect supported card/account items.
- `/shared/commodity/query`: query trade status and delivered secret.

### Commodity Fields

- `id`
- `code`
- `name`
- `description`
- `price`
- `user_price`
- `factory_price`
- `cover`
- `delivery_way`
- `contact_type`
- `password_status`
- `config`
- `widget`
- `draft_status`
- `inventory_hidden`
- `minimum`

### Target Rules

- Exclude any TGX SKU where normalized text contains Telegram-related terms.
- Keep only SKUs whose normalized platform is in the cross-provider platform intersection.
- Target price = TGX `price` * 1.2.
- Currency policy: TGX commodity APIs expose price-like numeric fields but do not provide a reliable per-response currency field. The target site will treat synchronized TGX prices as USD for display and settlement unless a later account-specific TGX document proves otherwise.
- Use `request_no` as idempotency key for purchases.
- Automatic TGX delivery should store returned `secret` into Dujiao-Next delivery payload.
- Manual TGX delivery should poll `/shared/commodity/query`.

## Dujiao-Next

Source: `https://dujiao-next.com/`

### Confirmed Fit

Dujiao-Next is explicitly positioned for digital goods, account/key products, virtual services, manual delivery, and custom frontend/admin development.

It already includes:

- product and SKU concepts;
- order and payment lifecycle;
- user frontend API;
- admin backend;
- automatic and manual delivery;
- payment callbacks/webhooks;
- upstream site integration concepts;
- multilingual docs/site structure;
- queue and Redis configuration.

### Official Repositories

- API/backend: `https://github.com/dujiao-next/dujiao-next`
- User frontend: `https://github.com/dujiao-next/user`
- Admin frontend: `https://github.com/dujiao-next/admin`
- Docs: `https://github.com/dujiao-next/document`

### Local Source Paths

- API/backend: `dujiao-next/`
- User frontend: `user/`
- Admin frontend: `admin/`
- Docs: `document/`

### Integration Approach

Dujiao-Next's own "site integration" Open API is useful as a reference for signatures, upstream mapping, idempotency, and callback style. However, FansGurus and TGX have different upstream APIs, so the target platform should implement provider-specific adapters inside or alongside Dujiao-Next instead of forcing both providers through the Dujiao-Next Open API shape.

Dujiao-Next already supports a site-wide currency setting and payment channels such as Alipay, WeChat Pay, and PayPal. Target-site integration settings should use one root `.env`; provider-specific Dujiao-Next runtime config can be generated or mapped from it as needed.

## Security Rules

- Never expose FansGurus key, TGX app key, Dujiao-Next secrets, payment credentials, or webhook secrets to the frontend.
- Do not log upstream secrets.
- Store raw upstream payloads but redact credentials and customer-sensitive delivery secrets in logs.
- Use idempotency keys for every upstream write operation.
