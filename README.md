# Church App

A mobile app for church administration (directory, attendance, giving) and
congregation life (Scripture, sermons, reading plans, prayer). See the
project proposal and development roadmap for full context.

**Current status: Phase 0 — Foundations.** Giving/payments (Paystack) is
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
  --dart-define=API_BASE_URL=http://localhost:8000
```

Run analysis + tests:
```bash
flutter analyze
flutter test
```

## CI

Two GitHub Actions workflows run automatically on PRs/pushes touching
`backend/` or `mobile/` respectively — lint + test for each. See
`.github/workflows/`.

## Before real member data goes in

Do not point this app at real church data until the items in
`docs/data-retention-policy.md` (Appendix C-equivalent gate items) are
resolved with leadership. Everything up to that point should run on
sample/test data only.
