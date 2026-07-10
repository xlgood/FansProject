# Patch 0021: Browser Smoke CORS Language Header

Date: 2026-07-10

## Summary

- Added `X-Lang` to the default backend CORS allowed headers.
- Hardened CORS middleware so `X-Lang` is appended even when an older explicit
  `cors.allowed_headers` config overrides defaults.
- Added router middleware coverage for frontend preflight requests carrying
  `x-lang`.
- Documented browser runtime smoke verification in
  `docs/15-browser-runtime-smoke.md`.

## Verification

```bash
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go test ./internal/router
```

Manual runtime checks:

- `curl -i http://127.0.0.1:8080/health`
- `curl -I http://127.0.0.1:5173/`
- `curl -I http://127.0.0.1:5174/`
- CORS preflight for `x-lang`
- Chrome headless screenshots for user home and admin login
