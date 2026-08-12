# Threat Model (living document — revisit every phase)

Last updated: Phase 0.

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

- [ ] Phase 1: attendance/directory RLS negative-tested
- [ ] Phase 2: sermon storage bucket read/write policies reviewed
- [ ] Phase 3: group materials scoped correctly to group membership
- [ ] Phase 4: prayer-request visibility adversarially tested
- [ ] Phase 5: Paystack webhook signature verification in place; payment
      logs audited for accidental card/account data
