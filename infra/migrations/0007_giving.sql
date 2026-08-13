-- 0007_giving.sql
-- Phase 5 schema: giving/transaction history. Deliberately narrow — this
-- is the "initiate a transaction, look at your own history" shape,
-- matching what app/core/paystack.py's single Paystack call needs. No
-- recurring giving, receipts, or payout tracking yet.
--
-- All writes happen through the backend (service_role), since it's the
-- only thing that ever talks to Paystack (see docs/threat-model.md's
-- trust-boundary diagram) — so, unlike most other tables, there are no
-- client-facing insert/update policies here at all, only select. A
-- member can read their own giving history directly via the anon key if
-- the mobile app ever wants that path; today it goes through the
-- backend's /api/v1/giving/history instead, same as everything else in
-- the two-track architecture that isn't pure own-user data.

create type giving_type as enum ('tithe', 'offering', 'special', 'other');
create type giving_status as enum ('pending', 'success', 'failed');

create table giving_transactions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles (id) on delete cascade,
  amount numeric(12, 2) not null check (amount > 0),
  currency text not null default 'GHS',
  giving_type giving_type not null default 'tithe',
  note text,
  status giving_status not null default 'pending',
  paystack_reference text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table giving_transactions enable row level security;

create policy "giving_transactions: a user can read their own giving history"
  on giving_transactions for select
  using (profile_id = auth.uid());

-- Uses the SECURITY DEFINER helper from 0006 rather than a subquery on
-- profiles directly, so this doesn't reintroduce the recursion bug fixed
-- there.
create policy "giving_transactions: admins and finance_admins can read all"
  on giving_transactions for select
  using (public.current_profile_role() in ('admin', 'finance_admin'));

create index giving_transactions_profile_id_idx on giving_transactions (profile_id);
