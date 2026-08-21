-- 0002_attendance.sql
-- Phase 1: services (a church gathering members can be marked present at)
-- and attendance records tied to a service + member.
--
-- Run against church-app-dev first, verify, then apply to church-app-prod.

-- ---------------------------------------------------------------------
-- Services
-- ---------------------------------------------------------------------
create table services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  service_date date not null,
  created_by uuid references profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

alter table services enable row level security;

create policy "services: admins, finance_admins and group leaders can read"
  on services for select
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('admin', 'finance_admin', 'group_leader')
    )
  );

create policy "services: admins and group leaders can manage"
  on services for all
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('admin', 'group_leader')
    )
  )
  with check (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('admin', 'group_leader')
    )
  );

-- ---------------------------------------------------------------------
-- Attendance
-- ---------------------------------------------------------------------
-- member_id is who was present; checked_in_by is who marked them present
-- (an admin/group_leader doing check-in at the door) — two different
-- people in the normal case. The unique constraint stops the same member
-- being checked in twice for the same service.
create table attendance (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references services (id) on delete cascade,
  member_id uuid not null references members (id) on delete cascade,
  checked_in_at timestamptz not null default now(),
  checked_in_by uuid references profiles (id) on delete set null,
  unique (service_id, member_id)
);

alter table attendance enable row level security;

-- A member can see their own attendance history (via their own member
-- record — see members.profile_id in 0001_init.sql).
create policy "attendance: a user can read their own attendance"
  on attendance for select
  using (
    exists (
      select 1 from members m
      where m.id = attendance.member_id and m.profile_id = auth.uid()
    )
  );

create policy "attendance: admins, finance_admins and group leaders can read all"
  on attendance for select
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('admin', 'finance_admin', 'group_leader')
    )
  );

-- Only admin/group_leader mark attendance — finance_admin can read reports
-- but has no reason to touch check-in.
create policy "attendance: admins and group leaders can mark attendance"
  on attendance for insert
  with check (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('admin', 'group_leader')
    )
  );

create policy "attendance: admins and group leaders can manage"
  on attendance for update
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('admin', 'group_leader')
    )
  )
  with check (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('admin', 'group_leader')
    )
  );

create policy "attendance: admins can delete"
  on attendance for delete
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

create index attendance_service_id_idx on attendance (service_id);
create index attendance_member_id_idx on attendance (member_id);

-- ---------------------------------------------------------------------
-- Sanity check query (run manually after applying, not part of the
-- migration): confirm RLS is actually on for both tables above.
-- select relname, relrowsecurity from pg_class
--   where relname in ('services', 'attendance');
-- ---------------------------------------------------------------------
