-- In-app feedback ("알아서핏 어떠세요?", lib/ui/screens/review_sheet.dart).
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Insert only from the app; read it in the SQL Editor.
--
-- Reminders used to be web pushes sent from the server (push_subscriptions,
-- push_log, push_due() and the daily-push Edge Function); they are now
-- notifications the Android/iOS app schedules on the device
-- (lib/data/reminders.dart). To remove the old server parts:
--   select cron.unschedule('daily-push');
--   drop function if exists public.push_due();
--   drop table if exists public.push_log, public.push_subscriptions;

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
