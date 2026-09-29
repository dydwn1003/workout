-- Usage events for product analytics (lib/data/analytics.dart).
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
--
-- What the app sends: event names and small non-health properties (which
-- tab, which logging method, onboarding step, search hit counts). Never
-- weights, calories, logged meals or other health data; the only free text
-- is a food search query that found nothing (to see which foods the
-- database lacks). Users can turn it off in Settings.
--
-- The app can only insert (anon or signed in); nobody reads it through the
-- API. Query it in the SQL Editor or connect a BI tool with the database
-- password. Rows older than 180 days are deleted daily.

create table if not exists public.app_events (
  id          bigint generated always as identity primary key,
  at          timestamptz not null default now(),   -- server receive time
  client_at   timestamptz,                           -- device time of the event
  user_id     uuid default auth.uid(),               -- null when signed out
  device_id   text not null,                         -- random id per install
  session_id  text not null,                         -- random id per app launch
  name        text not null,
  props       jsonb not null default '{}',
  platform    text,                                  -- web / android / ios
  app_version text,
  -- Keep rows small and well-formed; this is what limits abuse of the
  -- public insert.
  constraint app_events_name_len check (char_length(name) between 1 and 64),
  constraint app_events_ids_len check (char_length(device_id) <= 64 and char_length(session_id) <= 64),
  constraint app_events_props_size check (pg_column_size(props) <= 2048)
);

create index if not exists app_events_at on public.app_events (at);
create index if not exists app_events_name_at on public.app_events (name, at);

alter table public.app_events enable row level security;

-- Insert only. A signed-in user can only attribute events to themselves.
drop policy if exists "insert own events" on public.app_events;
create policy "insert own events" on public.app_events
  for insert to anon, authenticated
  with check (user_id is null or user_id = auth.uid());
-- No select/update/delete policies: the API can't read or change events.

-- Keep 180 days.
create extension if not exists pg_cron;
select cron.unschedule('app_events_retention')
  where exists (select 1 from cron.job where jobname = 'app_events_retention');
select cron.schedule('app_events_retention', '17 3 * * *',
  $$delete from public.app_events where at < now() - interval '180 days'$$);

-- Handy views for the SQL Editor ------------------------------------------

-- Daily active devices / users.
create or replace view public.analytics_daily as
select date_trunc('day', at)::date as day,
       count(distinct device_id) as devices,
       count(distinct user_id) as users,
       count(*) as events
from public.app_events group by 1 order by 1 desc;

-- Event counts per day and name.
create or replace view public.analytics_events as
select date_trunc('day', at)::date as day, name, count(*) as n,
       count(distinct device_id) as devices
from public.app_events group by 1, 2 order by 1 desc, 3 desc;

-- Searches that found nothing (candidates for the food database).
create or replace view public.analytics_missed_searches as
select props->>'q' as query, count(*) as n, max(at) as last_seen
from public.app_events
where name = 'food_search' and (props->>'results')::int = 0 and props ? 'q'
group by 1 order by 2 desc;

-- Views are for the dashboard only.
revoke all on public.analytics_daily, public.analytics_events,
  public.analytics_missed_searches from anon, authenticated;
