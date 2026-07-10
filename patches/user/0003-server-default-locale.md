# Patch 0003: Server Default Locale

Date: 2026-07-10

## Summary

- Exported locale support helpers from the user frontend i18n module.
- User frontend now applies backend `default_locale` on first visit only when
  the visitor has not already manually selected a language.
- Manual language override remains persisted in `localStorage.locale`.

## Verification

```bash
cd user && ./node_modules/.bin/vue-tsc -b
```
