# Admin Frontend Patch 0005: Docker Build Env

Date: 2026-07-10

## Purpose

Allow production Docker builds to inject the public API origin and optional
admin route path used by Vite.

## Files Changed

- `admin/Dockerfile`

## Behavior

- Adds `ARG VITE_API_BASE_URL`.
- Adds `ARG VITE_ADMIN_PATH`.
- Exposes both as `ENV` values during `pnpm run build`.
- No runtime Nginx behavior changed.

## Verification

- `cd admin && git diff --check -- Dockerfile`
