-- 0004_reading_plans_and_groups.sql
-- Phase 3: reading plans (+ per-user progress), and small groups with
-- membership-scoped shared materials.
--
-- Run against church-app-dev first, verify, then apply to church-app-prod.

-- ---------------------------------------------------------------------
-- Reading plans — content is admin-managed and congregation-readable,
-- same shape as sermons in 0003_content.sql.
-- ---------------------------------------------------------------------
create type reading_plan_type as enum ('annual', 'topical');

create table reading_plans (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  plan_type reading_plan_type not null default 'topical',
  created_by uuid references profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

alter table reading_plans enable row level security;

create policy "reading_plans: any signed-in profile can read"
  on reading_plans for select
  using (exists (select 1 from profiles p where p.id = auth.uid()));

create policy "reading_plans: admins can manage"
  on reading_plans for all
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

create table reading_plan_days (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references reading_plans (id) on delete cascade,
  day_number int not null,
  reference text not null,
  title text,
  unique (plan_id, day_number)
);

alter table reading_plan_days enable row level security;

create policy "reading_plan_days: any signed-in profile can read"
  on reading_plan_days for select
  using (exists (select 1 from profiles p where p.id = auth.uid()));

create policy "reading_plan_days: admins can manage"
  on reading_plan_days for all
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

-- Per-user progress — pure own-row data, same pattern as bible_bookmarks
-- in 0003_content.sql: the mobile app writes these directly with the
-- anon key, no FastAPI endpoint needed.
create table reading_plan_progress (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles (id) on delete cascade,
  plan_id uuid not null references reading_plans (id) on delete cascade,
  day_number int not null,
  completed_at timestamptz not null default now(),
  unique (profile_id, plan_id, day_number)
);

alter table reading_plan_progress enable row level security;

create policy "reading_plan_progress: a user can manage their own progress"
  on reading_plan_progress for all
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- ---------------------------------------------------------------------
-- Small groups — the directory (name/description) is readable by any
-- signed-in profile so people can discover and ask to join a group, but
-- shared materials are scoped to members of that specific group. This is
-- the "another RLS/authorization pass" DevSecOps task for Phase 3 —
-- see backend/tests/test_group_materials.py for the negative test.
-- ---------------------------------------------------------------------
create table small_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  leader_id uuid references profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

alter table small_groups enable row level security;

create policy "small_groups: any signed-in profile can read"
  on small_groups for select
  using (exists (select 1 from profiles p where p.id = auth.uid()));

create policy "small_groups: admins can manage"
  on small_groups for all
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

create table group_members (
  group_id uuid not null references small_groups (id) on delete cascade,
  profile_id uuid not null references profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, profile_id)
);

alter table group_members enable row level security;

create policy "group_members: a member can see their own group's roster"
  on group_members for select
  using (
    exists (
      select 1 from group_members gm
      where gm.group_id = group_members.group_id and gm.profile_id = auth.uid()
    )
  );

create policy "group_members: admins and the group's leader can manage"
  on group_members for all
  using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
    or exists (
      select 1 from small_groups sg where sg.id = group_members.group_id and sg.leader_id = auth.uid()
    )
  )
  with check (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
    or exists (
      select 1 from small_groups sg where sg.id = group_members.group_id and sg.leader_id = auth.uid()
    )
  );

create table group_materials (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references small_groups (id) on delete cascade,
  title text not null,
  url text,
  description text,
  created_by uuid references profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

alter table group_materials enable row level security;

-- Read is restricted to members of THIS group (or admin) — deliberately
-- not "any signed-in profile" like reading_plans/sermons, since
-- materials are private to the group they belong to.
create policy "group_materials: group members and admins can read"
  on group_materials for select
  using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
    or exists (
      select 1 from group_members gm
      where gm.group_id = group_materials.group_id and gm.profile_id = auth.uid()
    )
  );

create policy "group_materials: admins and the group's leader can manage"
  on group_materials for all
  using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
    or exists (
      select 1 from small_groups sg
      where sg.id = group_materials.group_id and sg.leader_id = auth.uid()
    )
  )
  with check (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
    or exists (
      select 1 from small_groups sg
      where sg.id = group_materials.group_id and sg.leader_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- Sanity check query (run manually after applying, not part of the
-- migration): confirm RLS is actually on for every table above.
-- select relname, relrowsecurity from pg_class
--   where relname in ('reading_plans', 'reading_plan_days', 'reading_plan_progress',
--                      'small_groups', 'group_members', 'group_materials');
-- ---------------------------------------------------------------------
