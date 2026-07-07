# Fansgurus Adapter

Reserved workspace for the Fansgurus integration layer.

Responsibilities:

- Fetch upstream service list with `action=services`.
- Normalize Fansgurus categories and services into Website3 catalog records.
- Apply the fixed pricing rule: `website3_rate = upstream_rate * 10`.
- Detect SKU additions, removals, price changes, and metadata changes.
- Forward paid Website3 orders to Fansgurus with `action=add`.
- Poll upstream order status with `action=status` or batch status APIs.
- Keep upstream API keys server-side only.

This adapter can be implemented as a Dujiao-Next backend extension, a sidecar service, or a scheduled worker depending on the final integration approach.
