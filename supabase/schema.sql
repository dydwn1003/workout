-- Food search database (식품의약품안전처 식품영양성분 데이터베이스).
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Data is loaded afterwards by tool/load_supabase.py.

create extension if not exists pg_trgm;

create table if not exists public.foods (
  id        text primary key,           -- stable id (hash of the name), same as the app's
  name      text not null,
  aliases   text[] not null default '{}',
  category  text not null,
  kcal      real not null,              -- per 100 g
  protein   real not null,
  carbs     real not null,
  fat       real not null,
  units     jsonb not null,             -- [{"label": "1회 제공량", "g": 194}, ...]
  unknown   text not null default '',   -- macros the source does not publish: p/c/f
  source    text not null,              -- 'curated' | 'mfds_food' | 'mfds_process'
  search    text not null               -- lower-cased name + aliases without spaces, joined with '|'
);

create index if not exists foods_search_trgm on public.foods using gin (search gin_trgm_ops);
create index if not exists foods_category on public.foods (category);

-- Public, read-only: anyone with the anon key can read, nobody can write
-- (loading uses the service_role key, which bypasses RLS).
alter table public.foods enable row level security;
drop policy if exists "foods are readable by everyone" on public.foods;
create policy "foods are readable by everyone" on public.foods for select using (true);

-- Same ranking as the app's searchFoods(): exact > prefix > contains over
-- name and aliases, then shorter names first. No initial-consonant (ㄷㄱㅅㅅ)
-- search on the server: it cost ~55 MB of the free-tier disk.
create or replace function public.search_foods(q text, lim int default 40)
returns setof public.foods
language sql stable
as $$
  with p as (
    select replace(lower(replace(q, ' ', '')), '|', '') as q
  ), e as (
    select q, replace(replace(replace(q, '\', '\\'), '%', '\%'), '_', '\_') as lq from p
  )
  select f.*
  from public.foods f, e
  where e.q <> '' and f.search like '%' || e.lq || '%'
  order by
    case
      when '|' || f.search || '|' like '%|' || e.lq || '|%' then 3
      when '|' || f.search like '%|' || e.lq || '%' then 2
      else 1
    end desc,
    length(f.name),
    f.id
  limit least(greatest(lim, 1), 100);
$$;

grant execute on function public.search_foods(text, int) to anon, authenticated;
