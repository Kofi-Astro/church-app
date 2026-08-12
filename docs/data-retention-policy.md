# Data Retention Policy (draft — confirm with church leadership before Phase 1 go-live)

This is a starting draft, not a finalized policy. It should be reviewed and
formally approved by church leadership before any real member data is
migrated into the app (see proposal Section 6).

## Principles

- Keep only what's needed to run church administration and ministry
  effectively — not indefinitely "just in case."
- A member (or their guardian, for a minor) can request their data be
  deleted or exported; this should be honored within a reasonable time
  (suggested: 30 days), except where financial records must be retained
  for legal/accounting reasons.
- Deletion requests are logged (who requested, when, what was removed) so
  there's an audit trail even after the data itself is gone.

## Draft retention periods (to be confirmed with leadership)

| Data type | Suggested retention | Notes |
|---|---|---|
| Member/household directory | While actively a member + 2 years after departure | Supports re-engagement/pastoral follow-up; reassess if a member requests earlier deletion |
| Attendance records | 3 years | Useful for ministry planning; low sensitivity but not indefinite |
| Prayer requests | 1 year, or until marked resolved + 90 days | Personal and often time-bound by nature |
| Giving/transaction records (Phase 5+) | 7 years | Common minimum for financial/tax record-keeping — confirm exact requirement with the church's finance/accounting practice |
| Auth/account data | Deleted on account deletion request, subject to the financial-record exception above | |

## Backups

Backups are retained on a rolling basis (exact window to be set once the
production Supabase project exists — Supabase's default point-in-time
recovery window is a reasonable starting point). A deletion request removes
data from live tables; it does not retroactively purge already-taken
backups, which age out on their own schedule. This should be disclosed if a
member asks about deletion.

## Open questions for leadership (Phase 1 gate item)

- [ ] Confirm the finance/accounting-required retention period for giving
      records in the church's jurisdiction
- [ ] Confirm who is authorized to approve a data-deletion request
- [ ] Confirm whether attendance data should ever be fully anonymized
      rather than deleted (useful for aggregate stats without keeping PII)
