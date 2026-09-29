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
  unknown   text not null default '',   -- estimated, not published: k(cal)/p/c/f
  source    text not null,              -- 'curated' | 'mfds_food' | 'mfds_process' | 'estimated'
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
language plpgsql stable
as $$
-- Spaces never matter ("닭가슴살샐러드" = "닭가슴살 샐러드"). When fewer than
-- 5 foods contain the whole query, foods containing both halves of it are
-- added for each split into parts of 2+ letters, so words in another order
-- or run together still match ("교촌허니콤보", "맘스터치싸이버거"). Each split
-- is its own query so the trigram index is used.
declare
  nq text := replace(lower(replace(q, ' ', '')), '|', '');
  n int := least(greatest(lim, 1), 100);
  seen text[] := '{}';
  got int;
  cut int;
  a text;
  b text;
begin
  if nq = '' then
    return;
  end if;
  a := replace(replace(replace(nq, '\', '\\'), '%', '\%'), '_', '\_');
  return query
    select f.* from public.foods f
    where f.search like '%' || a || '%'
    order by
      case
        when '|' || f.search || '|' like '%|' || a || '|%' then 3
        when '|' || f.search like '%|' || a || '%' then 2
        else 1
      end desc,
      length(f.name),
      f.id
    limit n;
  get diagnostics got = row_count;
  if got >= 5 or char_length(nq) < 4 then
    return;
  end if;
  select coalesce(array_agg(f.id), '{}') into seen
  from public.foods f where f.search like '%' || a || '%';
  for cut in 2 .. char_length(nq) - 2 loop
    exit when got >= n;
    a := replace(replace(replace(left(nq, cut), '\', '\\'), '%', '\%'), '_', '\_');
    b := replace(replace(replace(substr(nq, cut + 1), '\', '\\'), '%', '\%'), '_', '\_');
    return query
      select f.* from public.foods f
      where f.search like '%' || a || '%'
        and f.search like '%' || b || '%'
        and not (f.id = any (seen))
      order by length(f.name), f.id
      limit n - got;
    select seen || coalesce(array_agg(f.id), '{}') into seen
    from public.foods f
    where f.search like '%' || a || '%' and f.search like '%' || b || '%';
    got := cardinality(seen);
  end loop;
end $$;

grant execute on function public.search_foods(text, int) to anon, authenticated;
