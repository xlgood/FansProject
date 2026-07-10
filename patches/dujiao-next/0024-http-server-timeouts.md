# Dujiao-Next Patch 0024: HTTP Server Timeouts

Date: 2026-07-10

## Scope

Adds application-level Go `http.Server` timeout and header-size controls for
production readiness.

## Changes

- Adds `server.*` config fields for read header, read, write, and idle
  timeouts.
- Adds `server.max_header_bytes` with a default 1MB limit.
- Applies the configured limits when constructing the backend HTTP server.
- Updates `config.yml.example` with the new server settings.
- Adds unit coverage for configured timeout application and `MaxHeaderBytes`
  fallback behavior.

Note: local `config.yml` is ignored by the Dujiao-Next repository; copy the new
`server.*` keys from `config.yml.example` into production runtime config.

## Verification

```bash
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go test ./internal/app ./internal/config
```
