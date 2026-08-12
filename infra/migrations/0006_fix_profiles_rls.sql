-- 0006_fix_profiles_rls.sql
-- Fixes two real bugs found during first-ever live RLS verification against
-- church-app-dev (all prior testing used fake repos or the service_role
-- key, which bypasses RLS, so neither of these surfaced until now):
--
-- 1. Infinite recursion (Postgres error 42P17) on every read of `profiles`,
--    and therefore on every other table whose policies check a caller's
--    role via a subquery on `profiles` (households, members, attendance,
--    sermons, reading_plans, small_groups, prayer_requests, events, ...).
--    Root cause: "profiles: admins can read all profiles" decides SELECT
--    access on `profiles` by running a SELECT on `profiles` — which must
--    itself re-evaluate that same policy. Fix: move the role lookup into a
--    SECURITY DEFINER function, which (as the table owner) reads the row
--    without triggering RLS, breaking the cycle.
--
-- 2. Privilege escalation: "profiles: users can update their own non-role
--    fields" only checked auth.uid() = id — nothing actually stopped a
--    signed-in member from PATCHing their own `role` to 'admin' directly
--    via the anon key + PostgREST, skipping the backend entirely. Fix: a
--    trigger blocks any role change unless the caller is already an admin
--    (self-service, own row only — unchanged from before) or is the
--    backend acting via the service_role key.

create or replace function public.current_profile_role()
returns app_role
language sql
security definer
stable
set search_path = public
as $$
  select role from profiles where id = auth.uid();
$$;

drop policy "profiles: admins can read all profiles" on profiles;
create policy "profiles: admins can read all profiles"
  on profiles for select
  using (public.current_profile_role() in ('admin', 'finance_admin'));

create or replace function public.prevent_profile_role_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.role() = 'service_role' then
    return new;
  end if;
  if new.role is distinct from old.role and public.current_profile_role() is distinct from 'admin' then
    raise exception 'Only an admin can change a profile''s role';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_role_escalation on profiles;
create trigger profiles_prevent_role_escalation
  before update on profiles
  for each row
  execute function public.prevent_profile_role_escalation();
