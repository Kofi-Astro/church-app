# Infrastructure Setup

This covers Phase 0's infrastructure: Supabase project setup, environment
separation, and how migrations are applied. Deployment/CI details live in
`.github/workflows/`.

## 1. Supabase projects

Create **two** Supabase projects to keep dev and prod fully separate from
day one (a third, `staging`, can be added later if needed — dev doubles as
staging for now while working solo):

| Project | Purpose |
|---|---|
| `church-app-dev` | Local development and CI. Safe to reset/seed freely. |
| `church-app-prod` | Real data, once Phase 1 is approved for go-live. Nothing touches this until then. |

For each project, grab from **Project Settings → API**:
- Project URL → `SUPABASE_URL`
- `service_role` key → `SUPABASE_SERVICE_ROLE_KEY` (backend only — this key
  bypasses RLS, so it must never reach the mobile app or client-side code)
- `anon` key → `SUPABASE_ANON_KEY` (safe for the mobile app; RLS still
  applies to it)

## 2. Applying migrations

SQL migrations live in `infra/migrations/`, numbered in order. Apply them
via the Supabase SQL editor (or the Supabase CLI once that's set up) against
`church-app-dev` first, verify, then apply the same file to `church-app-prod`
when that project is created.

Run migrations in order:
```
0001_init.sql
```

## 3. Row-Level Security (RLS)

Every table holding member, household, attendance, or (later) giving data
has RLS **enabled from creation**, not bolted on afterward. The default
policy is deny-all; access is granted explicitly per role. See
`0001_init.sql` for the current policies and `docs/threat-model.md` for the
reasoning behind who can see what.

## 4. Secrets

No credentials live in this repo. Locally, copy `.env.example` to
`backend/.env` (gitignored). In CI, secrets are stored as GitHub Actions
encrypted secrets. In production, they're set as environment variables on
the hosting platform (Render/Railway/Fly.io).

## 5. Giving/transactions tables (Phase 5, not yet active)

`0001_init.sql` intentionally does **not** create `giving`/`transactions`
tables yet — that schema lands with Phase 5 alongside the Paystack
integration, so it can be designed once against real Paystack response
shapes instead of guessed at now.
