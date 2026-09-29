-- Reminder pushes (supabase/functions/daily-push) and in-app feedback.
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Needs user_sync.sql (the server only knows signed-in users' logs).
--
-- Once a day (20:00 KST, the cron job at the bottom) the daily-push Edge
-- Function asks push_due() who should get a reminder and sends it:
--   * after the last meal or weigh-in: days 1 and 3, then weekly for the
--     first month (7, 14, 21, 28), then every two weeks (42, 56, ...) for
--     as long as reminders stay on
--   * on the check-in weekday when no check-in was done in the last 4 days
-- Only to users who turned reminders on (Settings -> 알림) and at most one
-- message per user per day.

-- One row per device that allowed notifications. Web Push today; the
-- platform column leaves room for FCM tokens from the Android/iOS apps.
create table if not exists public.push_subscriptions (
  endpoint   text primary key,             -- Web Push endpoint (or FCM token)
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  platform   text not null default 'web',  -- web / android / ios
  p256dh     text,                          -- Web Push keys
  auth       text,
  created_at timestamptz not null default now()
);

create index if not exists push_subscriptions_user on public.push_subscriptions (user_id);

alter table public.push_subscriptions enable row level security;

drop policy if exists "own push subscriptions: read" on public.push_subscriptions;
create policy "own push subscriptions: read" on public.push_subscriptions
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "own push subscriptions: insert" on public.push_subscriptions;
create policy "own push subscriptions: insert" on public.push_subscriptions
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "own push subscriptions: update" on public.push_subscriptions;
create policy "own push subscriptions: update" on public.push_subscriptions
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own push subscriptions: delete" on public.push_subscriptions;
create policy "own push subscriptions: delete" on public.push_subscriptions
  for delete to authenticated using (auth.uid() = user_id);

-- What was sent (so each reminder goes out once). Server only: no policies.
create table if not exists public.push_log (
  id      bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  kind    text not null,                    -- inactive_1 ... inactive_30, checkin
  sent_at timestamptz not null default now()
);

create index if not exists push_log_user on public.push_log (user_id, sent_at);
alter table public.push_log enable row level security;

-- Who gets which reminder today (Korea time), one row per user.
create or replace function public.push_due()
returns table (user_id uuid, kind text, language text)
language sql stable security definer set search_path = ''
as $$
  with today as (
    select (now() at time zone 'Asia/Seoul')::date as d
  ),
  subs as (
    select distinct s.user_id from public.push_subscriptions s
  ),
  settings as (
    select r.user_id, r.data
    from public.user_records r join subs using (user_id)
    where r.kind = 'settings' and not r.deleted
  ),
  last_log as (
    select r.user_id, max((r.data ->> 'date')::date) as d
    from public.user_records r join subs using (user_id)
    where r.kind in ('meal', 'weight') and not r.deleted and r.data ? 'date'
    group by r.user_id
  ),
  last_plan as (
    select r.user_id, max((r.data ->> 'weekStart')::date) as d
    from public.user_records r join subs using (user_id)
    where r.kind = 'plan' and not r.deleted
    group by r.user_id
  ),
  candidates as (
    -- Inactivity: days 1 and 3, weekly to day 28, then every 14 days.
    select l.user_id, 'inactive_' || (t.d - l.d) as kind, 1 as priority
    from last_log l, today t
    where (t.d - l.d) in (1, 3, 7, 14, 21, 28)
       or ((t.d - l.d) >= 42 and (t.d - l.d) % 14 = 0)
    union all
    -- Check-in day, no check-in in the last 4 days, still logging.
    select p.user_id, 'checkin', 0
    from last_plan p
    join settings st using (user_id)
    join last_log l using (user_id)
    cross join today t
    where extract(isodow from t.d) = coalesce((st.data ->> 'checkinWeekday')::int, 1)
      and p.d < t.d - 3
      and t.d - l.d < 7
  )
  select distinct on (c.user_id) c.user_id, c.kind, st.data ->> 'language'
  from candidates c
  left join settings st using (user_id)
  cross join today t
  where coalesce((st.data ->> 'notifications')::boolean, true)
    -- Not already sent: an inactivity step since the last log, anything today.
    and not exists (
      select 1 from public.push_log g
      where g.user_id = c.user_id
        and (g.sent_at at time zone 'Asia/Seoul')::date = t.d
    )
    and not exists (
      select 1 from public.push_log g join last_log l using (user_id)
      where g.user_id = c.user_id and g.kind = c.kind
        and (g.sent_at at time zone 'Asia/Seoul')::date > l.d
    )
  order by c.user_id, c.priority;
$$;

revoke all on function public.push_due() from public, anon, authenticated;

-- In-app feedback ("알아서핏 어떠세요?"). Insert only from the app; read it
-- in the SQL Editor.
create table if not exists public.app_feedback (
  id          bigint generated always as identity primary key,
  at          timestamptz not null default now(),
  user_id     uuid default auth.uid(),
  rating      text not null check (rating in ('good', 'bad')),
  message     text check (char_length(message) <= 2000),
  platform    text,
  app_version text
);

alter table public.app_feedback enable row level security;

drop policy if exists "insert feedback" on public.app_feedback;
create policy "insert feedback" on public.app_feedback
  for insert to anon, authenticated
  with check (user_id is null or user_id = auth.uid());

-- Daily at 20:00 KST (11:00 UTC): call the Edge Function. Replace
-- <project-ref> and <CRON_SECRET> (the same value as the function's
-- CRON_SECRET secret) before running. Needs the pg_cron and pg_net
-- extensions (Database -> Extensions).
create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.unschedule('daily-push') where exists (select 1 from cron.job where jobname = 'daily-push');
select cron.schedule(
  'daily-push',
  '0 11 * * *',
  $$
  select net.http_post(
    url := 'https://<project-ref>.supabase.co/functions/v1/daily-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', '<CRON_SECRET>'
    ),
    body := '{}'::jsonb
  );
  $$
);
