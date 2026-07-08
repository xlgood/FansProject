# Provider Adapters

Reserved workspace for upstream provider integration notes or future adapter code.

Current target providers:

- FansGurus fan/growth services.
- TGX Account account products.

Responsibilities:

- Fetch upstream catalog data from each provider.
- Normalize platforms and SKU metadata into the target catalog.
- Exclude Telegram-related SKUs.
- Publish only platforms present in both provider catalogs after filtering.
- Apply provider pricing rules:
  - FansGurus: upstream price * 5.
  - TGX: upstream base price * 1.2.
- Forward paid local orders to the correct provider.
- Poll or query upstream order/trade status.
- Keep all provider credentials server-side only.

This workspace may become a Dujiao-Next backend extension, a worker package, or may be replaced by code inside the official Dujiao-Next API repository after source import.
