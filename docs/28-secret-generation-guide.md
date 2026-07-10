# Secret Generation Guide

Date: 2026-07-10

## Purpose

Use this guide to generate the remaining Gate 1 secrets for
`deploy/production-local/` or the real production secret store.

Do not paste generated values into git-tracked files, tickets, chat, or docs.
Store them only in the deployment secret store or local ignored production
draft files.

## Generate Values

Run these commands on the deployment machine or a trusted admin workstation:

```bash
openssl rand -base64 48
openssl rand -base64 48
openssl rand -base64 48
openssl rand -base64 32
openssl rand -base64 32
```

Assign the outputs in order:

| Output | Use as |
| --- | --- |
| 1 | `APP_SECRET_KEY` |
| 2 | `ADMIN_JWT_SECRET` |
| 3 | `USER_JWT_SECRET` |
| 4 | `POSTGRES_PASSWORD` |
| 5 | `REDIS_PASSWORD` |

If `openssl` is unavailable, use Python:

```bash
python3 -c 'import secrets; print(secrets.token_urlsafe(48))'
```

Run it once for each secret.

## Fill Backend Config

Edit the production backend config, for example:

```bash
deploy/production-local/config.yml
```

Replace:

| Placeholder | Replacement |
| --- | --- |
| `CHANGE_ME_APP_SECRET_32_BYTES_MIN` | `APP_SECRET_KEY` |
| `CHANGE_ME_ADMIN_JWT_SECRET` | `ADMIN_JWT_SECRET` |
| `CHANGE_ME_USER_JWT_SECRET` | `USER_JWT_SECRET` |
| `CHANGE_ME_POSTGRES_PASSWORD` | `POSTGRES_PASSWORD` inside `database.dsn` |
| `CHANGE_ME_REDIS_PASSWORD` | `REDIS_PASSWORD` in both `redis.password` and `queue.password` |

Keep `bootstrap.default_admin_password` empty after the first admin account is
created. Do not reuse the local development admin password.

## Fill Compose Env

Edit:

```bash
deploy/production-local/compose.env
```

Replace:

| Placeholder | Replacement |
| --- | --- |
| `CHANGE_ME_POSTGRES_PASSWORD` | Same `POSTGRES_PASSWORD` used in `database.dsn` |
| `CHANGE_ME_REDIS_PASSWORD` | Same `REDIS_PASSWORD` used in backend Redis and queue config |

The Compose env and backend `config.yml` must match exactly. A mismatch will
let containers start but cause database or Redis authentication failures.

## Optional SMTP Secret

If email is enabled:

```bash
openssl rand -base64 32
```

Store the actual SMTP password in:

```yaml
email:
  enabled: true
  password: SMTP_PASSWORD
```

Also verify `email.host`, `email.port`, `email.username`, `email.from`, and
`email.from_name`.

## Provider And Payment Secrets

Do not put provider or payment secrets into frontend env files.

Configure these only in the backend/admin settings:

| Secret | Where to configure |
| --- | --- |
| FansGurus API key | Admin provider connection |
| TGX app id/key | Admin provider connection |
| Alipay credentials | Admin payment channel |
| WeChat Pay credentials | Admin payment channel |
| PayPal credentials | Admin payment channel |

Keep provider connections disabled until Gate 5 low-value acceptance testing is
explicitly approved.

## Verify No Placeholders Remain

Run:

```bash
rg -n "CHANGE_ME|FINAL_[A-Z_]*" deploy/production-local
```

Expected result before Gate 1: no hits in production config files. Hits in the
local README are acceptable only if that README is not used as an audit input.

Then run:

```bash
bash ops/prelaunch-audit.sh \
  --backend-config deploy/production-local/config.yml \
  --site-config deploy/production-local/site_config.json \
  --user-env deploy/production-local/user.env.production \
  --admin-env deploy/production-local/admin.env.production
```

Expected Gate 1 result after all secrets and final domains are filled:

```text
Summary: 0 failure(s), ...
```

## Rotation Notes

Rotate these immediately if they are exposed:

- `APP_SECRET_KEY`
- `ADMIN_JWT_SECRET`
- `USER_JWT_SECRET`
- database password
- Redis password
- provider credentials
- payment credentials
- SMTP password

JWT secret rotation invalidates existing sessions. Plan an admin re-login window
when rotating `ADMIN_JWT_SECRET` or `USER_JWT_SECRET`.
