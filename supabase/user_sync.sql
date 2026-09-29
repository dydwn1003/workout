-- Per-user sync of the app's records (lib/data/sync.dart).
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
--
-- Every record the app stores (profile, settings, each meal, weight,
-- workout, plan, saved meal, custom food, remembered server food) is one
-- row keyed by (user, kind, id). Deletions are kept as rows with
-- deleted = true so other devices learn about them.

create table if not exists public.user_records (
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  kind       text not null,
  id         text not null,
  data       jsonb,                         -- null when deleted
  deleted    boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, kind, id)
);

create index if not exists user_records_updated on public.user_records (user_id, updated_at);

-- updated_at is set by the server on every write, so "changed since" pulls
-- don't depend on device clocks.
create or replace function public.user_records_touch()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists user_records_touch on public.user_records;
create trigger user_records_touch before insert or update on public.user_records
  for each row execute function public.user_records_touch();

-- Only the signed-in owner can see or change their rows.
alter table public.user_records enable row level security;

drop policy if exists "own records: read" on public.user_records;
create policy "own records: read" on public.user_records
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "own records: insert" on public.user_records;
create policy "own records: insert" on public.user_records
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "own records: update" on public.user_records;
create policy "own records: update" on public.user_records
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own records: delete" on public.user_records;
create policy "own records: delete" on public.user_records
  for delete to authenticated using (auth.uid() = user_id);

-- Lets a signed-in user delete their own account (and, by cascade, their
-- records) from the app, as the App Store requires for apps with sign-in.
create or replace function public.delete_my_account()
returns void language sql security definer set search_path = '' as $$
  delete from auth.users where id = auth.uid();
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
