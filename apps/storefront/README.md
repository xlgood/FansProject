# Storefront

Reserved workspace for target site storefront notes or future frontend code.

The preferred implementation is to reuse and extend the Dujiao-Next `user` frontend rather than build a separate storefront from scratch.

Expected responsibilities:

- Locale-prefixed public routes for `zh-CN`, `zh-TW`, and `en`.
- IP-based first-visit default language.
- Platform landing pages based on the FansGurus/TGX platform intersection.
- Fan/growth service browsing from FansGurus.
- Account product browsing from TGX.
- Checkout forms driven by normalized provider SKU schemas.
- SEO/GEO landing pages and sitemap generation.

The frontend must not call FansGurus or TGX directly. It should read normalized catalog and order APIs from the Dujiao-Next backend.
