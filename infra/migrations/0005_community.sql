-- 0005_community.sql
-- Phase 4: prayer requests (with public/leaders/private visibility —
-- see docs/threat-model.md, this is the highest-stakes table in the
-- app) and events with RSVP.
--
-- Run against church-app-dev first, verify, then apply to church-app-prod.

-- ---------------------------------------------------------------------
-- Prayer requests
-- ---------------------------------------------------------------------
create type prayer_visibility as enum ('public', 'leaders', 'private');

create table prayer_requests (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles (id) on delete cascade,
  content text not null,
  visibility prayer_visibility not null default 'public',
  created_at timestamptz not null default now()
);

alter table prayer_requests enable row level security;

-- Deliberately no admin override here. "private" means the author and
-- only the author — see the can_view_prayer_request() logic mirrored in
-- app/repositories/prayer_requests.py, and the negative tests in
-- backend/tests/test_prayer_requests.py that assert an admin account
-- gets the same 404 a stranger would on someone else's private request.
create policy "prayer_requests: the author can always read their own"
  on prayer_requests for select
  using (profile_id = auth.uid());

create policy "prayer_requests: public requests are readable by any signed-in profile"
  on prayer_requests for select
  using (
    visibility = 'public'
    and exists (select 1 from profiles p where p.id = auth.uid())
  );

create policy "prayer_requests: leaders-only requests are readable by leaders"
  on prayer_requests for select
  using (
    visibility = 'leaders'
    and exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('admin', 'group_leader', 'finance_admin')
    )
  );

create policy "prayer_requests: the author can manage their own"
  on prayer_requests for all
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create index prayer_requests_profile_id_idx on prayer_requests (profile_id);

-- "Praying for this" — a lightweight per-user interaction. Readable by
-- anyone who can read the underlying request (so a count is meaningful
-- to display), writable only by the interacting user themselves.
create table prayer_interactions (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references prayer_requests (id) on delete cascade,
  profile_id uuid not null references profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (request_id, profile_id)
);

alter table prayer_interactions enable row level security;

create policy "prayer_interactions: readable if the parent request is readable"
  on prayer_interactions for select
  using (
    exists (
      select 1 from prayer_requests pr
      where pr.id = prayer_interactions.request_id
        and (
          pr.profile_id = auth.uid()
          or (pr.visibility = 'public' and exists (select 1 from profiles p where p.id = auth.uid()))
          or (
            pr.visibility = 'leaders'
            and exists (
              select 1 from profiles p
              where p.id = auth.uid() and p.role in ('admin', 'group_leader', 'finance_admin')
            )
          )
        )
    )
  );

create policy "prayer_interactions: a user can manage their own"
  on prayer_interactions for all
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- ---------------------------------------------------------------------
-- Events + RSVP — congregation-facing content, same admin-write/
-- any-signed-in-read shape as sermons and reading_plans.
-- ---------------------------------------------------------------------
create table events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  event_date timestamptz not null,
  location text,
  created_by uuid references profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

alter table events enable row level security;

create policy "events: any signed-in profile can read"
  on events for select
  using (exists (select 1 from profiles p where p.id = auth.uid()));

create policy "events: admins can manage"
  on events for all
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

create index events_event_date_idx on events (event_date);

create type rsvp_status as enum ('going', 'maybe', 'not_going');

create table event_rsvps (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references events (id) on delete cascade,
  profile_id uuid not null references profiles (id) on delete cascade,
  status rsvp_status not null default 'going',
  created_at timestamptz not null default now(),
  unique (event_id, profile_id)
);

alter table event_rsvps enable row level security;

create policy "event_rsvps: any signed-in profile can read (for counts)"
  on event_rsvps for select
  using (exists (select 1 from profiles p where p.id = auth.uid()));

create policy "event_rsvps: a user can manage their own RSVP"
  on event_rsvps for all
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- ---------------------------------------------------------------------
-- Sanity check query (run manually after applying, not part of the
-- migration): confirm RLS is actually on for every table above.
-- select relname, relrowsecurity from pg_class
--   where relname in ('prayer_requests', 'prayer_interactions', 'events', 'event_rsvps');
-- ---------------------------------------------------------------------
