# Church App

A mobile app for church administration (directory, attendance, giving) and
congregation life (Scripture, sermons, reading plans, prayer). See the
project proposal and development roadmap for full context.

**Current status: Phases 0–4 built** (directory, attendance, admin
dashboard, Bible reader, sermons, reading plans, small groups, prayer
requests, events). **Not yet connected to a real Supabase project** — see
"Before this actually runs" below. Giving/payments (Paystack) is
intentionally built last, in Phase 5 — see the roadmap for why.

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
flutter run \
  --dart-define=ENV=dev \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Without the two `SUPABASE_*` values the app boots to a "Supabase isn't
configured" screen instead of the login flow — expected until a Supabase
project exists (see below).

Run analysis + tests:
```bash
flutter analyze
flutter test
```

## CI

Two GitHub Actions workflows run automatically on PRs/pushes touching
`backend/` or `mobile/` respectively — lint + test for each. See
`.github/workflows/`.

## Before this actually runs end-to-end

The backend and mobile app both boot and pass their test suites today
without any external accounts — but nothing that touches real data works
yet, because no Supabase project exists. Before that:

1. Create `church-app-dev` (and later `church-app-prod`) per
   `infra/infra.md`, and apply `infra/migrations/*.sql` in order.
2. Fill in `backend/.env` and the mobile `SUPABASE_*` dart-defines with
   that project's values.
3. Create at least one real login and a matching `profiles` row (with a
   role) so `AuthGate` has something to resolve after sign-in.

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
