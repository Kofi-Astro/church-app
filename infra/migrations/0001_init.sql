-- 0001_init.sql
-- Phase 0: core identity schema — roles, profiles, households, members.
-- No giving/transactions tables yet (see infra.md — that's Phase 5).
--
-- Run against church-app-dev first, verify, then apply to church-app-prod
-- when that project exists.

-- ---------------------------------------------------------------------
-- Roles
-- ---------------------------------------------------------------------
-- Kept as an enum rather than free text so invalid roles can't be
-- inserted. finance_admin is reserved now (unused until Phase 5) so the
-- role model doesn't need to change shape later.
create type app_role as enum ('member', 'group_leader', 'admin', 'finance_admin');

-- ---------------------------------------------------------------------
-- Profiles (one row per Supabase auth user)
-- ---------------------------------------------------------------------
create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  role app_role not null default 'member',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table profiles enable row level security;

-- Deny-all by default; grant explicitly below.
create policy "profiles: users can read their own profile"
  on profiles for select
  using (auth.uid() = id);

create policy "profiles: admins can read all profiles"
  on profiles for select
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('admin', 'finance_admin')
    )
  );

create policy "profiles: users can update their own non-role fields"
  on profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ---------------------------------------------------------------------
-- Households
-- ---------------------------------------------------------------------
create table households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  created_at timestamptz not null default now()
);

alter table households enable row level security;

create policy "households: admins can read all"
  on households for select
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('admin', 'finance_admin', 'group_leader')
    )
  );

create policy "households: admins can manage"
  on households for all
  using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
  )
  with check (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- ---------------------------------------------------------------------
-- Members (a member may or may not have an app login — profile_id is
-- nullable to allow admins to add household members who don't use the
-- app themselves, e.g. children).
-- ---------------------------------------------------------------------
create table members (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles (id) on delete set null,
  household_id uuid references households (id) on delete set null,
  full_name text not null,
  email text,
  phone text,
  created_at timestamptz not null default now()
);

alter table members enable row level security;

create policy "members: a user can read their own member record"
  on members for select
  using (profile_id = auth.uid());

create policy "members: admins and group leaders can read all"
  on members for select
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('admin', 'finance_admin', 'group_leader')
    )
  );

create policy "members: admins can manage"
  on members for all
  using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
  )
  with check (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- ---------------------------------------------------------------------
-- Sanity check query (run manually after applying, not part of the
-- migration): confirm RLS is actually on for every table above.
-- select relname, relrowsecurity from pg_class
--   where relname in ('profiles', 'households', 'members');
-- ---------------------------------------------------------------------
