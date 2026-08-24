# Church App

A mobile app for church administration (directory, attendance, giving) and
congregation life (Scripture, sermons, reading plans, prayer). See the
project proposal and development roadmap for full context.

**Current status: Phases 0–4 built and connected to a real Supabase
project** (`church-app-dev`) — directory, attendance, admin dashboard,
Bible reader, sermons, reading plans, small groups, prayer requests,
events all run against live Postgres/Auth now, not just fakes. See
"Before this actually runs" below for what's still needed to click
through it as a real user.

**Phase 5 (giving) is also built** — real schema, real `/api/v1/giving`
endpoints, a real Give screen in the app — but not connected to an
actual Paystack account yet. `PAYSTACK_SECRET_KEY` is blank, so
initiating a gift returns a clean "not connected yet" response instead
of a fake success. This is deliberate: the goal was to see the exact
form/flow before wiring up real money, not to fake a payment. See
`backend/app/core/paystack.py`.

**Congregations & auxiliaries are built** — the church's distinct
service tracks (English, Akan, Youth Chapel, Teens Chapel, French
Chapel, Northern Congregation, Children's Service) are their own
`congregations` table that members and dated `services` link to, so
attendance is tracked per congregation rather than one shared calendar.
Auxiliaries (Men's/Women's Auxiliary, Baptist Young Men/Women, Girls'
Auxiliary, Royal Ambassadors) reuse the existing small-groups feature
with a `category` field rather than being a separate concept — see
`infra/migrations/0008_congregations_and_auxiliaries.sql`.

**A web admin dashboard exists** alongside the phone app, built from the
same Flutter codebase (`mobile/`) rather than a separate project — see
"Web dashboard" below.

## Structure

```
church-app/
├── mobile/          Flutter app
├── backend/         FastAPI service
├── infra/           Supabase setup guide + SQL migrations
├── docs/            Threat model, data retention policy
└── .github/         CI workflows, Dependabot config
```

## Backend — local setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp ../.env.example .env          # then fill in Supabase values once that project exists
uvicorn app.main:app --reload
```

Visit `http://localhost:8000/health` — should return
`{"status": "ok", "environment": "dev"}`.

Run lint + tests:
```bash
ruff check app tests
pytest -q
```

## Mobile — local setup

```bash
cd mobile
flutter pub get
cp dart_define.dev.json.example dart_define.dev.json   # then fill in Supabase values
flutter run --dart-define-from-file=dart_define.dev.json
```

`dart_define.dev.json` is gitignored, same pattern as `backend/.env` —
never commit real values into the `.example` file. Without
`SUPABASE_URL`/`SUPABASE_ANON_KEY` filled in, the app boots to a
"Supabase isn't configured" screen instead of the login flow.

`API_BASE_URL` is platform-dependent when the backend runs on your own
machine: the Android emulator can't resolve `localhost` as the host
machine, so it needs `http://10.0.2.2:8000` (the emulator's special
alias for host loopback) — that's the default in
`dart_define.dev.json.example`. iOS simulator and physical devices need
`http://localhost:8000` or your machine's LAN IP, respectively.

Run analysis + tests:
```bash
flutter analyze
flutter test
```

## Web dashboard — local setup

The web build is a different app shell (`AdminWebShell`, a side-rail
desktop layout), not the phone app's bottom-nav — see
`mobile/lib/features/home/auth_gate.dart` for where that choice is made
(`kIsWeb`). It's the same codebase and the same `dart_define.dev.json`
as the phone app:

```bash
cd mobile
flutter run -d chrome --dart-define-from-file=dart_define.dev.json
```

Signing in with a `member`-only account shows an explanatory
"this dashboard is for admins" screen instead of the shell — the web
build is for admin/group-leader/finance roles only. `flutter build web`
produces a deployable `build/web/` directory for actual hosting once
this is ready to go live (not committed — see `.gitignore`).

## CI

Two GitHub Actions workflows run automatically on PRs/pushes touching
`backend/` or `mobile/` respectively — lint + test for each. See
`.github/workflows/`.

## Before this actually runs end-to-end

`church-app-dev` exists and all 5 migrations are applied — `backend/.env`
and `mobile/dart_define.dev.json` are already wired to it (both
gitignored, so a fresh clone needs its own copy of each; see the
`.example` files). One real login exists
(`opokukelvin29@gmail.com`, role `admin`) so `AuthGate` has a profile to
resolve after sign-in. `church-app-prod` doesn't exist yet — create it
per `infra/infra.md` when this is ready to go live with real church data
(see "Before real member data goes in" below first).

Everything is still on sample/test data — no real directory, attendance,
or content has been entered. The `profiles`/`members`/etc. tables in
`church-app-dev` are otherwise empty.

One thing that's fully live regardless: the Bible reader, since it calls
the free public bible-api.com directly (see
`mobile/lib/features/bible/bible_api_service.dart`) rather than Supabase.

Push notifications (FCM, for sermon/live-service/prayer-update alerts)
are not wired up — that needs a Firebase project, another external
account this repo doesn't have credentials for. The daily reading-plan
reminder is a local, on-device notification instead, and works without
any of that.

## Before real member data goes in

Do not point this app at real church data until the items in
`docs/data-retention-policy.md` (Appendix C-equivalent gate items) are
resolved with leadership. Everything up to that point should run on
sample/test data only.
