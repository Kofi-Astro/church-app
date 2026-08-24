# Infrastructure Setup

This covers Phase 0's infrastructure: Supabase project setup, environment
separation, and how migrations are applied. Deployment/CI details live in
`.github/workflows/`.

## 1. Supabase projects

Two Supabase projects keep dev and prod fully separate (a third, `staging`,
can be added later if needed — dev doubles as staging for now while
working solo):

| Project | Purpose | Status |
|---|---|---|
| `church-app-dev` | Local development and CI. Safe to reset/seed freely. | **Live** — all 5 migrations applied, RLS confirmed on for all 19 tables. |
| `church-app-prod` | Real data, once Phase 1 is approved for go-live. Nothing touches this until then. | Not created yet. |

For each project, grab from **Project Settings → API**:
- Project URL → `SUPABASE_URL`
- Secret key (`service_role` in the older key format) →
  `SUPABASE_SERVICE_ROLE_KEY` (backend only — this key bypasses RLS, so it
  must never reach the mobile app or client-side code)
- Publishable key (`anon` in the older key format) → `SUPABASE_ANON_KEY`
  (safe for the mobile app; RLS still applies to it)

Note: Supabase's newer key format (`sb_publishable_...` /
`sb_secret_...`) requires `supabase-py` ≥ 2.31.0 — older versions raise
`SupabaseException: Invalid API key` at client creation. `requirements.txt`
is already pinned to 2.31.0 for this reason.

## 2. Applying migrations

SQL migrations live in `infra/migrations/`, numbered in order. Apply them
via the Supabase SQL editor, the Supabase CLI, or `psql` directly against
the project's connection string (Project Settings → Database). All of
them are already applied to `church-app-dev`; apply the same files to
`church-app-prod` in the same order when that project is created.

Run migrations in order:
```
0001_init.sql
0002_attendance.sql
0003_content.sql
0004_reading_plans_and_groups.sql
0005_community.sql
0006_fix_profiles_rls.sql
0007_giving.sql
0008_congregations_and_auxiliaries.sql
```

`0008` seeds the church's actual congregations (English, Akan, Youth
Chapel, Teens Chapel, French Chapel, Northern Congregation, Children's
Service) and a first batch of auxiliaries (Men's/Women's Auxiliary,
Baptist Young Men/Women, Girls' Auxiliary, Royal Ambassadors) as real
rows, not just schema — more of each can be added afterward through the
app. Its RLS policies use the `current_profile_role()` helper from
`0006` from the start, so it doesn't reintroduce the recursion bug that
one fixed.

Two of the migrations emit a harmless `NOTICE` about a policy name being
truncated to Postgres's 63-character identifier limit — the policy still
gets created correctly under the truncated name, this is cosmetic only.

`0006` is not optional — without it, every read of `profiles` (and
therefore every other table whose policies check a caller's role) fails
with `infinite recursion detected in policy for relation "profiles"`
under RLS. See the comment at the top of that file and
`docs/threat-model.md` for how this was found and confirmed fixed.

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

## 5. Giving (Phase 5 — schema live, Paystack not connected)

`0007_giving.sql` creates `giving_transactions` and is applied to
`church-app-dev`. The backend's `/api/v1/giving/initialize` endpoint
calls Paystack's "Initialize Transaction" API (`app/core/paystack.py`)
using `PAYSTACK_SECRET_KEY` — until that's set, it returns a clean 503
instead of attempting a real charge. To actually connect it:

1. Get a Paystack **test** secret key (`sk_test_...`) from the church's
   Paystack dashboard.
2. Set `PAYSTACK_SECRET_KEY` in `backend/.env`.
3. Test end-to-end with Paystack's documented test card numbers before
   ever touching a live key.

Webhook signature verification (to confirm a payment actually completed,
rather than trusting the mobile app's word for it) isn't built yet —
that's the next piece once a real key exists to test against.
