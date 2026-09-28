-- One-off migration for databases created before public.foods was slimmed
-- down: drops the keys/cho_keys arrays (they duplicated search/cho, ~95 MB)
-- and the initial-consonant column cho with its index (~55 MB).
-- Run in the Supabase SQL Editor as three separate queries, in order.
-- Dropping the indexes first keeps the peak disk use low while the table is
-- rewritten.

-- 1) Drop the indexes and the columns, switch search_foods() to search.
drop index if exists public.foods_search_trgm, public.foods_cho_trgm, public.foods_category;

alter table public.foods drop column if exists keys, drop column if exists cho_keys,
  drop column if exists cho;

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

-- 2) Give the space back to the disk (run on its own; takes a minute).
vacuum full public.foods;

-- 3) Rebuild the indexes in one pass (smaller than ones grown row by row).
create index if not exists foods_search_trgm on public.foods using gin (search gin_trgm_ops);
create index if not exists foods_category on public.foods (category);
analyze public.foods;
