# Local Dujiao-Next Baseline

Date: 2026-07-08

This document records the Phase 1 baseline for the cloned Dujiao-Next source in
this workspace. The upstream source directories remain ignored by the root git
repository.

## Runtime Layout

- Backend source: `dujiao-next/`
- User frontend source: `user/`
- Admin frontend source: `admin/`
- Local backend config: `dujiao-next/config.yml`
- Local database: `dujiao-next/db/dujiao.db`

## Local Development Commands

Backend API-only mode:

```bash
cd dujiao-next
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache go run cmd/server/main.go -mode api
```

User frontend:

```bash
cd user
./node_modules/.bin/vite --host 127.0.0.1 --port 5173 --strictPort
```

Admin frontend:

```bash
cd admin
./node_modules/.bin/vite --host 127.0.0.1 --port 5174 --strictPort
```

`pnpm run dev` did not start in the restricted environment because pnpm tried to
verify or switch to `pnpm@10.34.3` and could not reach the registry. Since
dependencies are already installed, using the local Vite binary is the current
working path for Phase 1.

## Verified Endpoints

- Backend health: `GET http://127.0.0.1:8080/health` returns `{"status":"ok"}`.
- User frontend: `GET http://127.0.0.1:5173/` returns the Vite HTML shell.
- Admin frontend: `GET http://127.0.0.1:5174/login` returns the Vite HTML shell.
- Admin login API: `POST http://127.0.0.1:8080/api/v1/admin/login` succeeds with
  the local bootstrap admin account.

## Local Admin Account

- Username: `admin`
- Password: `Admin12345`
- 2FA: not required in the current local baseline

These credentials are local development bootstrap values only. They must not be
used for production.

## Current Runtime Choices

- Database: SQLite
- Redis: disabled
- Queue: disabled
- Email: disabled
- Backend server host: `127.0.0.1`
- Backend server port: `8080`

Default all-in-one backend startup failed while the queue was disabled, so the
current baseline uses `-mode api`. Queue-backed fulfillment and scheduled sync
will need Redis/queue enabled or a deliberate local replacement before the order
fulfillment phases.

## Phase 1 Notes

- The API route prefix is `/api/v1`.
- Frontend dev servers proxy `/api` to the backend.
- No upstream FansGurus or TGX API calls were made during this baseline.
- No real payment or order fulfillment flow was executed.
