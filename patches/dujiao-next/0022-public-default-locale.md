# Patch 0022: Public Default Locale

Date: 2026-07-10

## Summary

- Public config now includes `default_locale`.
- Locale inference prefers common CDN/edge country headers and falls back to the
  existing `Accept-Language` resolver.
- Added tests for country-code mapping and fallback behavior.

## Verification

```bash
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go test ./internal/http/handlers/public -run 'Test(LocaleFromCountryCode|ResolvePublicDefaultLocale)'
```
