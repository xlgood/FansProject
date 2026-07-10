# User Frontend Patch 0005: Public Payment Copy

Date: 2026-07-10

## Purpose

Remove public-facing wording that exposes internal provider terminology during
redirect payment.

## Files Changed

- `user/src/i18n/index.ts`

## Behavior

- English redirect payment hint now says `secure payment page` instead of
  `provider page`.
- No payment flow logic changed.

## Verification

- `cd user && ./node_modules/.bin/vue-tsc -b`
- `cd user && git diff --check -- src/i18n/index.ts`
- `bash ops/prelaunch-audit.sh --backend-config /tmp/nonexistent`
