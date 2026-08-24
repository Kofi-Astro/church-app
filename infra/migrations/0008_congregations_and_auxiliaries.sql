-- 0008_congregations_and_auxiliaries.sql
-- The church runs several distinct congregations/service tracks (English,
-- Akan, Youth Chapel, Teens Chapel, French Chapel, Northern Congregation,
-- Children's Service) rather than one single Sunday service, and has
-- several standing auxiliaries (Men's/Women's Auxiliary, Baptist Young
-- Men/Women, Girls' Auxiliary, Royal Ambassadors, ...) alongside its
-- ad-hoc small/Bible-study groups.
--
-- Run against church-app-dev first, verify, then apply to church-app-prod.

-- ---------------------------------------------------------------------
-- Congregations — a standing service track, not a single dated
-- gathering (that's still `services`, which now links to one of these).
-- Admin-managed, readable by any signed-in profile (same shape as
-- sermons/reading_plans).
-- ---------------------------------------------------------------------
create table congregations (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now()
);

alter table congregations enable row level security;

create policy "congregations: any signed-in profile can read"
  on congregations for select
  using (exists (select 1 from profiles p where p.id = auth.uid()));

-- Uses the SECURITY DEFINER helper from 0006 rather than a subquery on
-- profiles directly, so this doesn't reintroduce the recursion bug fixed
-- there.
create policy "congregations: admins can manage"
  on congregations for all
  using (public.current_profile_role() = 'admin')
  with check (public.current_profile_role() = 'admin');

-- Seeded with the church's actual congregations so the admin doesn't have
-- to type these in by hand; more can be added later through the app.
insert into congregations (name) values
  ('English Service'),
  ('Akan Service'),
  ('Youth Chapel'),
  ('Teens Chapel'),
  ('French Chapel'),
  ('Northern Congregation'),
  ('Children''s Service');

-- ---------------------------------------------------------------------
-- Members: which congregation someone primarily belongs to. Nullable —
-- a newly-added member (e.g. a visitor) may not have one assigned yet.
-- ---------------------------------------------------------------------
alter table members
  add column congregation_id uuid references congregations (id) on delete set null;

create index members_congregation_id_idx on members (congregation_id);

-- ---------------------------------------------------------------------
-- Services: which congregation this specific dated gathering belongs to
-- — e.g. "Sunday Service" on 2026-08-30 for the English congregation and
-- the same date for the Akan congregation are two different `services`
-- rows, each with its own attendance roster. Nullable at the database
-- level (so this migration doesn't break on any pre-existing rows), but
-- the API layer requires it on every new service going forward — see
-- app/schemas/attendance.py's ServiceCreate.
-- ---------------------------------------------------------------------
alter table services
  add column congregation_id uuid references congregations (id) on delete set null;

create index services_congregation_id_idx on services (congregation_id);

-- ---------------------------------------------------------------------
-- Small groups: reusing the existing table/RLS/materials machinery for
-- auxiliaries instead of building a parallel structure — an auxiliary is
-- structurally identical to a small group (a named group with a leader,
-- a membership roster, and shared materials). `category` just lets the
-- app section "Auxiliaries" apart from ordinary small/Bible-study groups
-- when listing them; every existing RLS policy on small_groups/
-- group_members/group_materials already applies unchanged.
-- ---------------------------------------------------------------------
create type group_category as enum ('small_group', 'auxiliary');

alter table small_groups
  add column category group_category not null default 'small_group';

-- Seeded with the auxiliaries named when this feature was requested;
-- "many more" can be added later the same way any small group is
-- created, just with category = 'auxiliary'.
insert into small_groups (name, category) values
  ('Men''s Auxiliary', 'auxiliary'),
  ('Women''s Auxiliary', 'auxiliary'),
  ('Baptist Young Men', 'auxiliary'),
  ('Baptist Young Women', 'auxiliary'),
  ('Girls'' Auxiliary', 'auxiliary'),
  ('Royal Ambassadors', 'auxiliary');
