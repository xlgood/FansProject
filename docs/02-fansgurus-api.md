# Fansgurus API Notes

## Verified

The provided API key successfully returned:

- Balance response with USD currency.
- A large `services` JSON array.

## Base URL

`https://fansgurus.com/api/v2`

## Observed Service Fields

- `service`: upstream service id.
- `name`: upstream SKU name.
- `type`: order form type, for example `Default`, `Poll`, `Custom Comments`, `Mentions`.
- `rate`: upstream price as a decimal string.
- `min`: minimum order quantity.
- `max`: maximum order quantity.
- `dripfeed`: whether drip-feed ordering is supported.
- `refill`: whether refill is supported.
- `cancel`: whether cancellation is supported.
- `category`: upstream category name.

## Pricing Rule

Website3 sell price must be calculated as:

```text
website3_rate = fansgurus_rate * 10
```

Use decimal arithmetic, not floating point arithmetic.

## Security

The API key must only be used server-side.

Never place it in frontend code, client-side environment variables, logs, screenshots, or committed files.
