# User Frontend Patch 0006: Docker Build Env

Date: 2026-07-10

## Purpose

Allow production Docker builds to inject the public API origin used by Vite.

## Files Changed

- `user/Dockerfile`

## Behavior

- Adds `ARG VITE_API_BASE_URL`.
- Exposes it as `ENV VITE_API_BASE_URL` during `pnpm run build`.
- No runtime Nginx behavior changed.

## Verification

- `cd user && git diff --check -- Dockerfile`
