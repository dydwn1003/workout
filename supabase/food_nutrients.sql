-- Extra nutrients per food, kept beside public.foods so adding one doesn't
-- rewrite the 300k-row table (disk-friendly on the free plan).
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Data is loaded by: python3 tool/load_supabase.py --nutrients

create table if not exists public.food_nutrients (
  id      text primary key references public.foods (id) on delete cascade,
  sugar   real,                         -- 당류 g per 100 g
  sat_fat real                          -- 포화지방 g per 100 g (not loaded yet)
);

alter table public.food_nutrients enable row level security;
drop policy if exists "food nutrients are readable by everyone" on public.food_nutrients;
create policy "food nutrients are readable by everyone" on public.food_nutrients
  for select using (true);

-- search_foods() plus the extra nutrients, same ranking. Rows are JSON
-- objects shaped like public.foods with "sugar" (and "sat_fat") added.
create or replace function public.search_foods_v2(q text, lim int default 40)
returns setof jsonb
language sql stable
as $$
  select to_jsonb(f) - 'ord' || jsonb_build_object('sugar', n.sugar, 'sat_fat', n.sat_fat)
  from (
    select s.*, row_number() over () as ord
    from public.search_foods(q, lim) s
  ) f
  left join public.food_nutrients n on n.id = f.id
  order by f.ord;
$$;

grant execute on function public.search_foods_v2(text, int) to anon, authenticated;
