# Coding Standards

This project follows the local `karpathy-guidelines` skill.

## Practical Rules

- State assumptions before implementation.
- Prefer simple changes that match Dujiao-Next style.
- Touch only files needed for the task.
- Do not invent abstractions for one-off code.
- Keep provider-specific logic isolated in provider adapters.
- Use typed request/response structs where the codebase supports them.
- Use decimal types for money.
- Keep secrets out of logs and frontend bundles.
- Write tests around normalization, pricing, signing, and idempotency.

## Provider Adapter Rules

- Never call upstream APIs from frontend code.
- Keep raw upstream payload for troubleshooting.
- Normalize into internal catalog fields separately.
- Make upstream write operations idempotent.
- Treat upstream errors as retryable unless explicitly permanent.
- Persist enough context to retry without user re-entry.

## Money Rules

- No binary floating point for prices, charges, or costs.
- Store upstream cost, multiplier, final price, currency, and rounding result.
- Lock order amount at checkout.

## Internationalization Rules

- Every public route should be locale-aware.
- Manual language selection must override IP detection.
- Avoid hard-coded user-facing strings in new UI.
- Keep platform names consistent across locales.

## Review Checklist

- Does the change depend on real credentials?
- Does it expose secrets?
- Can paid fulfillment be retried safely?
- Are Telegram SKUs excluded?
- Does the SKU belong to the platform intersection?
- Are prices calculated with the right multiplier?
- Are unsupported service types blocked from purchase?
- Are tests or manual verification steps included?
