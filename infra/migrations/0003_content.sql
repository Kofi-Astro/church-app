-- 0003_content.sql
-- Phase 2: sermon library, a singleton church_settings row (livestream
-- URL for now), and per-user Bible bookmarks/highlights.
--
-- Run against church-app-dev first, verify, then apply to church-app-prod.

-- ---------------------------------------------------------------------
-- Sermons — congregation-facing content. Any signed-in member can read;
-- only admins manage the library (matches app/api/v1/sermons.py).
-- ---------------------------------------------------------------------
create table sermons (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  speaker text,
  series text,
  sermon_date date not null,
  video_url text,
  description text,
  created_by uuid references profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

alter table sermons enable row level security;

create policy "sermons: any signed-in profile can read"
  on sermons for select
  using (exists (select 1 from profiles p where p.id = auth.uid()));

create policy "sermons: admins can manage"
  on sermons for all
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

create index sermons_series_idx on sermons (series);
create index sermons_sermon_date_idx on sermons (sermon_date desc);

-- ---------------------------------------------------------------------
-- Church settings — a single row of church-wide, admin-editable config.
-- Starts with just the livestream URL (Phase 2's "live streaming embed").
-- ---------------------------------------------------------------------
-- `id boolean primary key ... check (id)` is a standard Postgres trick to
-- force exactly one row to ever exist: the only legal primary key value
-- is `true`, so a second insert would collide with the existing row's
-- primary key. That's how "one settings row for the whole church" is
-- enforced at the database level instead of just by convention.
create table church_settings (
  id boolean primary key default true,
  livestream_url text,
  updated_at timestamptz not null default now(),
  constraint church_settings_singleton check (id)
);

insert into church_settings (id) values (true);

alter table church_settings enable row level security;

create policy "church_settings: any signed-in profile can read"
  on church_settings for select
  using (exists (select 1 from profiles p where p.id = auth.uid()));

create policy "church_settings: admins can update"
  on church_settings for update
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

-- ---------------------------------------------------------------------
-- Bible bookmarks/highlights — pure per-user data. The mobile app talks
-- to these tables directly with the anon key (no FastAPI endpoint), so
-- RLS here is the only access control — see lib/features/bible/bible_sync_service.dart.
-- ---------------------------------------------------------------------
create table bible_bookmarks (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles (id) on delete cascade,
  translation_id text not null,
  book_id text not null,
  book_name text not null,
  chapter int not null,
  created_at timestamptz not null default now(),
  unique (profile_id, translation_id, book_id, chapter)
);

alter table bible_bookmarks enable row level security;

create policy "bible_bookmarks: a user can manage their own bookmarks"
  on bible_bookmarks for all
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create table bible_highlights (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles (id) on delete cascade,
  translation_id text not null,
  book_id text not null,
  chapter int not null,
  verse int not null,
  color text not null default 'yellow',
  created_at timestamptz not null default now(),
  unique (profile_id, translation_id, book_id, chapter, verse)
);

alter table bible_highlights enable row level security;

create policy "bible_highlights: a user can manage their own highlights"
  on bible_highlights for all
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- ---------------------------------------------------------------------
-- Sanity check query (run manually after applying, not part of the
-- migration): confirm RLS is actually on for every table above.
-- select relname, relrowsecurity from pg_class
--   where relname in ('sermons', 'church_settings', 'bible_bookmarks', 'bible_highlights');
-- ---------------------------------------------------------------------
