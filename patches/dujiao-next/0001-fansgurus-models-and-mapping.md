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
git diff --check
```

Not completed:

```text
gofmt
go test ./internal/service
```

Reason:

```text
go not found
gofmt not found
```

The local execution environment does not currently expose the Go toolchain in
`PATH`.

## Next Patch

Patch 0002 should add a Fansgurus HTTP client with mocked tests for:

- `balance`
- `services`
- `add`
- `status`
- API key redaction
- timeout/network/invalid JSON handling
