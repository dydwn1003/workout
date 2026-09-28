-- One-off migration for databases created before the keys/cho_keys arrays
-- were dropped from public.foods (they duplicated search/cho and took ~95 MB).
-- Run in the Supabase SQL Editor as three separate queries, in order.
-- Dropping the indexes first keeps the peak disk use low while the table is
-- rewritten.

-- 1) Drop the indexes and the arrays, switch search_foods() to search/cho.
drop index if exists public.foods_search_trgm, public.foods_cho_trgm, public.foods_category;

alter table public.foods drop column if exists keys, drop column if exists cho_keys;

create or replace function public.search_foods(q text, lim int default 40)
returns setof public.foods
language sql stable
as $$
  with p as (
    select replace(lower(replace(q, ' ', '')), '|', '') as q,
           lower(replace(q, ' ', '')) ~ '^[ㄱ-ㅎ]+$' as cho
  ), e as (
    select q, cho, replace(replace(replace(q, '\', '\\'), '%', '\%'), '_', '\_') as lq from p
  ), m as (
    select f.*, '|' || case when e.cho then f.cho else f.search end || '|' as k, e.lq
    from public.foods f, e
    where e.q <> ''
      and case when e.cho then f.cho like '%' || e.lq || '%'
               else f.search like '%' || e.lq || '%' end
  )
  select id, name, aliases, category, kcal, protein, carbs, fat, units, unknown, source, search, cho
  from m
  order by
    case
      when k like '%|' || lq || '|%' then 3
      when k like '%|' || lq || '%' then 2
      else 1
    end desc,
    length(name),
    id
  limit least(greatest(lim, 1), 100);
$$;

-- 2) Give the space back to the disk (run on its own; takes a minute).
vacuum full public.foods;

-- 3) Rebuild the indexes in one pass (smaller than ones grown row by row).
create index if not exists foods_search_trgm on public.foods using gin (search gin_trgm_ops);
create index if not exists foods_cho_trgm on public.foods using gin (cho gin_trgm_ops);
create index if not exists foods_category on public.foods (category);
analyze public.foods;
