# Patch 0001: Fansgurus Models And Mapping Helpers

Date: 2026-07-07

External source tree used:

```text
/private/tmp/dujiao-next-phase1
```

Patch file:

```text
patches/dujiao-next/0001-fansgurus-models-and-mapping.patch
```

## Purpose

This patch is the first backend slice for Website3's Fansgurus integration into
Dujiao-Next. It does not implement live HTTP calls yet.

It adds:

- `ConnectionProtocolFansgurus = "fansgurus"`.
- `FansgurusServiceMapping` model.
- `FansgurusSyncRun` model.
- `AutoMigrate` registration for the new models.
- Fansgurus service type constants.
- `CalculateFansgurusSellRate` for the `upstream_rate * 10` rule.
- Initial manual form schema generation for:
  - `Default`
  - `Custom Comments`
  - `Poll`
  - `Mentions`
- Stable content hash helper.
- Focused unit tests for pricing, service type support, schema shape, and hash
  behavior.

## Verification

Completed:

```text
gofmt -w internal/constants/constants.go internal/models/db.go internal/models/fansgurus.go internal/service/fansgurus_mapping.go internal/service/fansgurus_mapping_test.go
git diff --check
GOPROXY=https://goproxy.cn,direct GOCACHE=/private/tmp/go-build-cache GOMODCACHE=/private/tmp/go-mod-cache go test ./internal/service
```

Notes:

```text
The first attempt with proxy.golang.org timed out while downloading modules.
The test passed after using GOPROXY=https://goproxy.cn,direct.
```

## Next Patch

Patch 0002 should add a Fansgurus HTTP client with mocked tests for:

- `balance`
- `services`
- `add`
- `status`
- API key redaction
- timeout/network/invalid JSON handling
