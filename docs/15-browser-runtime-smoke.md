# Browser Runtime Smoke Verification

Date: 2026-07-10

## Scope

Verify the local backend, user frontend, and admin frontend together in a real
browser runtime after the provider catalog and procurement integration work.

## Local Services

```bash
cd dujiao-next
GOPROXY=https://goproxy.cn,direct \
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go run ./cmd/server -mode api

cd user
VITE_API_BASE_URL=http://127.0.0.1:8080 ./node_modules/.bin/vite --host 127.0.0.1 --port 5173

cd admin
VITE_API_BASE_URL=http://127.0.0.1:8080 ./node_modules/.bin/vite --host 127.0.0.1 --port 5174
```

## Checks

```bash
curl -i http://127.0.0.1:8080/health
curl -I http://127.0.0.1:5173/
curl -I http://127.0.0.1:5174/
curl -i -X OPTIONS \
  -H 'Origin: http://127.0.0.1:5173' \
  -H 'Access-Control-Request-Method: GET' \
  -H 'Access-Control-Request-Headers: x-lang' \
  http://127.0.0.1:8080/api/v1/public/config
```

Chrome headless screenshots were captured for:

- `http://127.0.0.1:5173/`
- `http://127.0.0.1:5174/`

## Result

Passed after one CORS fix.

- Backend `/health` returned `200 OK`.
- User frontend returned `200 OK` and rendered the home page in Chrome.
- Admin frontend returned `200 OK` and rendered the login page in Chrome.
- The local database currently has no synced catalog data, so the user home page
  rendered an empty product state. That is expected for this smoke environment.
- Initial browser validation found that frontend requests carrying `X-Lang`
  were blocked by CORS preflight because the backend allowed headers did not
  include `X-Lang`.
- The backend now always includes `X-Lang` in CORS allowed headers, including
  when deployment config provides an older explicit `cors.allowed_headers` list.
- The final preflight response included:
  `Access-Control-Allow-Headers: Content-Type, Content-Length, Accept-Encoding, Authorization, Cache-Control, X-Requested-With, X-CSRF-Token, X-Lang`.
- The final admin browser screenshot no longer showed the previous network
  error toast.

## Verification

```bash
GOCACHE=/Users/river/FansProject/dujiao-next/.gocache \
GOMODCACHE=/Users/river/FansProject/dujiao-next/.gomodcache \
go test ./internal/router
```

## Notes

- The in-app browser automation tool was not available in this session.
- The Playwright wrapper attempted to download `@playwright/cli`, but network
  access to the npm registry was unavailable in the sandbox.
- Validation therefore used installed Google Chrome in headless mode.
