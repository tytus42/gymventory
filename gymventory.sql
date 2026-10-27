-- Gymventory — baza danych. Wklej CAŁOŚĆ w Supabase: SQL Editor → New query → Run.
-- Skrypt można uruchamiać wielokrotnie (np. po aktualizacji) — niczego nie usuwa.
-- Każda osoba widzi wyłącznie swoje dane; znajomi widzą tylko to, co udostępnione (Row Level Security).

-- 1. Dziennik każdego użytkownika (ćwiczenia, treningi, pomiary) ----------------------------
create table if not exists public.gv_docs (
  user_id    uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  id         text        not null,
  data       jsonb       not null default '{}'::jsonb,
  deleted    boolean     not null default false,
  updated_at timestamptz not null default now(),
  server_at  timestamptz not null default now(),
  primary key (user_id, id)
);
create index if not exists gv_docs_server_at on public.gv_docs (user_id, server_at);

create or replace function public.gv_touch() returns trigger language plpgsql as $$
begin new.server_at := clock_timestamp(); return new; end $$;
drop trigger if exists gv_touch on public.gv_docs;
create trigger gv_touch before insert or update on public.gv_docs for each row execute function public.gv_touch();

-- 2. Profile (nazwa + kod do zapraszania znajomych) ----------------------------------------
create table if not exists public.gv_profiles (
  user_id    uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  name       text not null check (char_length(name) between 1 and 40),
  code       text not null unique check (code ~ '^[A-Z0-9]{6}$'),
  created_at timestamptz not null default now()
);

-- 3. Znajomi -----------------------------------------------------------------------------
create table if not exists public.gv_friends (
  from_id    uuid not null references auth.users(id) on delete cascade,
  to_id      uuid not null references auth.users(id) on delete cascade,
  status     text not null default 'pending' check (status in ('pending','accepted')),
  created_at timestamptz not null default now(),
  primary key (from_id, to_id),
  check (from_id <> to_id)
);

-- 4. Treningi udostępnione znajomym --------------------------------------------------------
create table if not exists public.gv_shared (
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date       date not null,
  title      text,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, date)
);

-- 5. Wyzwania ----------------------------------------------------------------------------
create table if not exists public.gv_challenges (
  id         uuid primary key default gen_random_uuid(),
  owner      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title      text not null check (char_length(title) between 1 and 60),
  kind       text not null check (kind in ('workouts','sets','volume','ex_reps','ex_max','cardio_km')),
  exercise   text,
  start_date date not null,
  end_date   date not null,
  target     numeric,
  created_at timestamptz not null default now(),
  check (end_date >= start_date)
);
create table if not exists public.gv_challenge_members (
  challenge_id uuid not null references public.gv_challenges(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  value        numeric not null default 0,
  updated_at   timestamptz not null default now(),
  primary key (challenge_id, user_id)
);

-- Funkcje pomocnicze do reguł (security definer = nie zapętlają się na regułach) ------------
create or replace function public.gv_is_friend(other uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from gv_friends where status = 'accepted'
    and ((from_id = auth.uid() and to_id = other) or (to_id = auth.uid() and from_id = other)))
$$;
create or replace function public.gv_is_member(cid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from gv_challenge_members where challenge_id = cid and user_id = auth.uid())
$$;
create or replace function public.gv_is_owner(cid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from gv_challenges where id = cid and owner = auth.uid())
$$;

-- Reguły dostępu --------------------------------------------------------------------------
alter table public.gv_docs              enable row level security;
alter table public.gv_profiles          enable row level security;
alter table public.gv_friends           enable row level security;
alter table public.gv_shared            enable row level security;
alter table public.gv_challenges        enable row level security;
alter table public.gv_challenge_members enable row level security;

do $$ declare r record; begin
  for r in select policyname, tablename from pg_policies where schemaname = 'public' and tablename like 'gv\_%' loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

create policy gv_docs_all on public.gv_docs for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy gv_profiles_read   on public.gv_profiles for select to authenticated using (true);
create policy gv_profiles_insert on public.gv_profiles for insert to authenticated with check (user_id = auth.uid());
create policy gv_profiles_update on public.gv_profiles for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy gv_friends_read   on public.gv_friends for select to authenticated using (auth.uid() in (from_id, to_id));
create policy gv_friends_invite on public.gv_friends for insert to authenticated with check (from_id = auth.uid() and status = 'pending');
create policy gv_friends_accept on public.gv_friends for update to authenticated using (to_id = auth.uid()) with check (to_id = auth.uid());
create policy gv_friends_remove on public.gv_friends for delete to authenticated using (auth.uid() in (from_id, to_id));

create policy gv_shared_read  on public.gv_shared for select to authenticated using (user_id = auth.uid() or public.gv_is_friend(user_id));
create policy gv_shared_write on public.gv_shared for insert to authenticated with check (user_id = auth.uid());
create policy gv_shared_upd   on public.gv_shared for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy gv_shared_del   on public.gv_shared for delete to authenticated using (user_id = auth.uid());

create policy gv_ch_read   on public.gv_challenges for select to authenticated using (owner = auth.uid() or public.gv_is_member(id));
create policy gv_ch_create on public.gv_challenges for insert to authenticated with check (owner = auth.uid());
create policy gv_ch_update on public.gv_challenges for update to authenticated using (owner = auth.uid()) with check (owner = auth.uid());
create policy gv_ch_delete on public.gv_challenges for delete to authenticated using (owner = auth.uid());

create policy gv_chm_read   on public.gv_challenge_members for select to authenticated
  using (public.gv_is_member(challenge_id) or public.gv_is_owner(challenge_id));
create policy gv_chm_join   on public.gv_challenge_members for insert to authenticated
  with check (public.gv_is_owner(challenge_id) and (user_id = auth.uid() or public.gv_is_friend(user_id)));
create policy gv_chm_update on public.gv_challenge_members for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy gv_chm_leave  on public.gv_challenge_members for delete to authenticated
  using (user_id = auth.uid() or public.gv_is_owner(challenge_id));

grant select, insert, update, delete on public.gv_docs, public.gv_profiles, public.gv_friends,
  public.gv_shared, public.gv_challenges, public.gv_challenge_members to authenticated;

-- 6. Zdjęcia sprzętu: prywatny schowek, każdy ma tylko swój folder ---------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('gv-photos', 'gv-photos', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

drop policy if exists gv_photos_read   on storage.objects;
drop policy if exists gv_photos_insert on storage.objects;
drop policy if exists gv_photos_update on storage.objects;
drop policy if exists gv_photos_delete on storage.objects;
create policy gv_photos_read   on storage.objects for select to authenticated
  using (bucket_id = 'gv-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy gv_photos_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'gv-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy gv_photos_update on storage.objects for update to authenticated
  using (bucket_id = 'gv-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy gv_photos_delete on storage.objects for delete to authenticated
  using (bucket_id = 'gv-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- 7. Codzienny „ping” (GitHub Actions), żeby darmowy projekt nie był usypiany -----------------
create or replace function public.gv_ping() returns integer language sql stable as $$ select 1 $$;
grant execute on function public.gv_ping() to anon, authenticated;
