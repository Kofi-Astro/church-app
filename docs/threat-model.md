# Threat Model (living document — revisit every phase)

Last updated: Phase 4, plus first live-Supabase RLS verification.

## What data is sensitive here

| Data | Sensitivity | Notes |
|---|---|---|
| Member directory (names, contact info, household) | Medium | PII; access should be limited to admins/leaders, not public |
| Attendance records | Low–Medium | Could reveal patterns about individuals (e.g. absence) |
| Prayer requests (private/leaders-only) | High | Deeply personal; visibility bugs here are the most damaging failure mode in this app |
| Giving/transaction history (Phase 5+) | High | Financial data; also indirectly reveals income/generosity patterns |
| Auth credentials | High | Standard account-takeover risk |

## Who can access what (role model)

- **member** — own profile, own household, public content, own prayer
  requests, requests marked public/leaders-only within their own groups
- **group_leader** — the above, plus member/attendance data for their
  specific group(s)
- **admin** — full directory, attendance, and content management; not
  automatically finance data
- **finance_admin** — giving/transaction data (Phase 5+); this role should
  be assigned to as few people as possible and requires MFA

## Trust boundaries

```
[Flutter app] --(anon key, RLS-scoped)--> [Supabase Postgres]
     |
     `--(HTTPS, JWT)--> [FastAPI backend] --(service_role key)--> [Supabase Postgres]
                              |
                              `--(Phase 5)--> [Paystack API]
```

- The **anon key** is embedded in the client and is safe to ship — RLS is
  the actual security boundary on that path, not secrecy of the key.
- The **service_role key** bypasses RLS entirely and must only ever live in
  the backend's environment variables — never in the mobile app, never in
  git, never in client-side logs.
- The FastAPI layer is the only thing that will ever talk to Paystack; the
  mobile app never sees a Paystack secret key.

## Key risks and mitigations (current)

| Risk | Mitigation |
|---|---|
| RLS policy gap exposes another user's data | Every new table gets RLS enabled at creation time, plus a negative test (log in as a low-privilege test account, attempt to read data that shouldn't be visible) before merging |
| Service role key leaks (e.g. committed to git, logged) | Key lives only in `.env` (gitignored) and platform env vars; `.env.example` never has real values; log statements never print full request/response bodies |
| Prayer-request visibility bug | Explicit negative test required before this feature ships (see roadmap Phase 4 DevSecOps task) |
| Dependency vulnerability | Dependabot enabled on both `pubspec.yaml` and `requirements.txt` from Phase 0 |
| Solo-developer key-person risk | This document plus `infra/infra.md` and inline comments are the handover trail if someone else ever needs to pick this up |

## To revisit each phase

Everything below marked done is verified at the **API layer**
(`backend/tests/`, using role/account overrides against the real FastAPI
routes). That layer only ever exercises the `service_role` key, which
bypasses RLS by design — so passing those tests never actually proved RLS
itself worked.

`church-app-dev` now exists, and RLS has been probed for the first time
against the live project, directly via PostgREST with a real low-privilege
account's JWT (the same path the mobile app's direct-Supabase features —
Bible bookmarks/highlights, reading-plan progress — actually use). That
probe immediately found two real bugs, both fixed in
`infra/migrations/0006_fix_profiles_rls.sql`:

1. **Every read of `profiles` crashed with infinite recursion**
   (`42P17`) — the "admins can read all profiles" policy decided access
   by running a SELECT on `profiles`, which had to re-evaluate that same
   policy. Since most other tables' policies check the caller's role via
   a subquery on `profiles`, this broke RLS on `households`, `members`,
   `attendance`, `sermons`, `reading_plans`, `small_groups`,
   `prayer_requests`, `events`, and more — effectively everything. Fixed
   by moving the role lookup into a `SECURITY DEFINER` function, which
   reads the row as the table owner and doesn't re-trigger RLS.
2. **Privilege escalation** — "users can update their own non-role
   fields" only checked `auth.uid() = id`; nothing stopped a signed-in
   member from PATCHing their own `role` to `admin` directly via the
   anon key, skipping the backend entirely. Fixed with a trigger that
   blocks any role change unless the caller is already an admin or is
   the backend acting via `service_role`.

Both fixes were re-verified live (not just re-read) with a disposable
low-privilege test account: a member can now only see their own profile
row and gets an empty result on `households`; a member's direct attempt
to self-promote is rejected by the trigger; an admin still sees every
profile; the backend's `service_role` path can still change a profile's
role. The test account was deleted afterward.

- [x] Phase 1: attendance/directory role checks negative-tested at the
      API layer (`test_households.py`, `test_members.py`,
      `test_attendance.py`); RLS-level checks above cover the same
      tables live
- [ ] Phase 2: sermon library only supports admin-pasted video links, not
      file upload — there's no storage bucket yet, so this item doesn't
      apply until one exists
- [x] Phase 3: group materials/roster scoped to group membership,
      negative-tested (`test_small_groups.py` — a member of group A gets
      403 on group B's materials, same for a non-member); not yet
      re-verified against live RLS the way `profiles`/`households` were
      above — same method, just not done yet
- [x] Phase 4: prayer-request visibility adversarially tested
      (`test_prayer_requests.py` — a stranger, and separately an admin,
      both get 404 on someone else's private request); not yet
      re-verified against live RLS
- [ ] Phase 5: schema (`giving_transactions`) and endpoints
      (`/api/v1/giving/*`) are built and live on `church-app-dev`, gated
      the same way Supabase itself was gated pre-connection — a clean
      503 until `PAYSTACK_SECRET_KEY` is set, never a fake success (see
      `backend/tests/test_giving.py`). Still open: an actual Paystack
      account/key, webhook signature verification (nothing currently
      confirms a payment really completed — the app can't yet trust its
      own "success" state), and a payment-logs audit for accidental
      card/account data once that exists
- [ ] Extend the live-RLS probe done for `profiles`/`households` above to
      the rest of Phase 2–4's tables (attendance, sermons, reading
      plans, small groups, prayer requests, events) before real member
      data goes in — the `profiles` recursion bug is proof this class of
      issue doesn't show up any other way
