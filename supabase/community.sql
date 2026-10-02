-- 헬스장 커뮤니티 (lib/data/community.dart).
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Safe to run again after changes.
--
-- A board per gym: gyms come from the 체력단련장업 open data
-- (tool/load_gyms.py) and users can add missing ones. Signed-in users with a
-- nickname write posts (text + up to 4 photos) and comments, like posts,
-- report and block. Everyone also shares the 운동 라운지 boards by sport,
-- and each user keeps up to 3 gyms as "my gyms". Three reports from
-- different people hide a post or comment until it is reviewed (hidden =
-- false again by hand).

create extension if not exists pg_trgm;

-- Gyms ----------------------------------------------------------------------

create table if not exists public.gyms (
  id           text primary key,              -- 'l-<관리번호>' open data, 'u-<uuid>' user-added
  name         text not null check (char_length(name) between 1 and 60),
  address      text not null default '' check (char_length(address) <= 200),
  sido         text not null default '',      -- 서울특별시
  sigungu      text not null default '',      -- 강남구
  source       text not null default 'user' check (source in ('open', 'user')),
  created_by   uuid references auth.users (id) on delete set null,
  member_count int not null default 0,
  post_count   int not null default 0,
  last_post_at timestamptz,
  created_at   timestamptz not null default now(),
  -- lower-cased name + address without spaces, for search
  search       text generated always as (lower(replace(name || address, ' ', ''))) stored
);

create index if not exists gyms_search on public.gyms using gin (search gin_trgm_ops);
create index if not exists gyms_region on public.gyms (sido, sigungu);

-- Community profiles (nickname) -----------------------------------------------

create table if not exists public.community_profiles (
  user_id    uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  nickname   text not null check (char_length(nickname) between 2 and 12),
  agreed_at  timestamptz not null default now(),   -- community rules accepted
  created_at timestamptz not null default now()
);

create unique index if not exists community_profiles_nickname
  on public.community_profiles (lower(nickname));

-- Profile photo: a path in the community bucket, in the user's own folder.
alter table public.community_profiles add column if not exists avatar text
  check (char_length(avatar) <= 200);

-- My gyms (joined boards, shown first) -----------------------------------------

create table if not exists public.gym_members (
  gym_id     text not null references public.gyms (id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (gym_id, user_id)
);

create index if not exists gym_members_user on public.gym_members (user_id);

-- Posts, comments, likes -------------------------------------------------------

create table if not exists public.posts (
  id            uuid primary key default gen_random_uuid(),
  gym_id        text not null references public.gyms (id) on delete cascade,
  author        uuid not null default auth.uid() references public.community_profiles (user_id) on delete cascade,
  body          text not null check (char_length(body) between 1 and 2000),
  images        text[] not null default '{}' check (cardinality(images) <= 4),
  like_count    int not null default 0,
  comment_count int not null default 0,
  hidden        boolean not null default false,
  created_at    timestamptz not null default now(),
  edited_at     timestamptz
);

-- What the post is about (앱의 PostTag): 잡담, 운동메이트, 질문, 정보, 후기.
alter table public.posts add column if not exists tag text not null default 'free'
  check (tag in ('free', 'mate', 'question', 'info', 'review'));

create index if not exists posts_gym_time on public.posts (gym_id, created_at desc);
create index if not exists posts_gym_tag_time on public.posts (gym_id, tag, created_at desc);
create index if not exists posts_author on public.posts (author);

create table if not exists public.comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts (id) on delete cascade,
  author     uuid not null default auth.uid() references public.community_profiles (user_id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 500),
  hidden     boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists comments_post_time on public.comments (post_id, created_at);

-- Replies: one level. A reply to a reply goes under its top-level comment.
alter table public.comments add column if not exists parent_id uuid
  references public.comments (id) on delete cascade;
create index if not exists comments_parent on public.comments (parent_id);

-- Who a reply answers (the author of the comment tapped, before replies
-- to a reply move under the top-level one), for the notification.
alter table public.comments add column if not exists reply_to uuid
  references auth.users (id) on delete set null;

create or replace function public.comments_parent()
returns trigger language plpgsql security definer set search_path = '' as $$
declare p record;
begin
  new.reply_to := null;
  if new.parent_id is not null then
    select post_id, parent_id, author into p from public.comments where id = new.parent_id;
    if p.post_id is distinct from new.post_id then
      raise exception 'parent comment is on another post';
    end if;
    new.reply_to := p.author;
    if p.parent_id is not null then new.parent_id := p.parent_id; end if;
  end if;
  return new;
end $$;

drop trigger if exists comments_parent on public.comments;
create trigger comments_parent before insert on public.comments
  for each row execute function public.comments_parent();

create table if not exists public.post_likes (
  post_id    uuid not null references public.posts (id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

-- Reports and blocks -------------------------------------------------------------

create table if not exists public.reports (
  id          uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('post', 'comment')),
  target_id   uuid not null,
  reporter    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  reason      text not null check (char_length(reason) between 1 and 300),
  created_at  timestamptz not null default now(),
  unique (target_type, target_id, reporter)
);

create table if not exists public.user_blocks (
  blocker    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  blocked    uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker, blocked),
  check (blocker <> blocked)
);

-- Counters (security definer: readers can't update these rows) ----------------

create or replace function public.community_count()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_table_name = 'posts' then
    if tg_op = 'INSERT' then
      update public.gyms set post_count = post_count + 1, last_post_at = new.created_at
        where id = new.gym_id;
    else
      update public.gyms set post_count = greatest(post_count - 1, 0) where id = old.gym_id;
    end if;
  elsif tg_table_name = 'comments' then
    if tg_op = 'INSERT' then
      update public.posts set comment_count = comment_count + 1 where id = new.post_id;
    else
      update public.posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
    end if;
  elsif tg_table_name = 'post_likes' then
    if tg_op = 'INSERT' then
      update public.posts set like_count = like_count + 1 where id = new.post_id;
    else
      update public.posts set like_count = greatest(like_count - 1, 0) where id = old.post_id;
    end if;
  elsif tg_table_name = 'gym_members' then
    if tg_op = 'INSERT' then
      update public.gyms set member_count = member_count + 1 where id = new.gym_id;
    else
      update public.gyms set member_count = greatest(member_count - 1, 0) where id = old.gym_id;
    end if;
  end if;
  return null;
end $$;

drop trigger if exists posts_count on public.posts;
create trigger posts_count after insert or delete on public.posts
  for each row execute function public.community_count();
drop trigger if exists comments_count on public.comments;
create trigger comments_count after insert or delete on public.comments
  for each row execute function public.community_count();
drop trigger if exists post_likes_count on public.post_likes;
create trigger post_likes_count after insert or delete on public.post_likes
  for each row execute function public.community_count();
drop trigger if exists gym_members_count on public.gym_members;
create trigger gym_members_count after insert or delete on public.gym_members
  for each row execute function public.community_count();

-- Rate limits: spam protection per user ------------------------------------------

create or replace function public.community_rate_limit()
returns trigger language plpgsql security definer set search_path = '' as $$
declare n int;
begin
  if tg_table_name = 'posts' then
    select count(*) into n from public.posts
      where author = new.author and created_at > now() - interval '10 minutes';
    if n >= 5 then raise exception 'rate_limit' using errcode = 'P0001'; end if;
  elsif tg_table_name = 'comments' then
    select count(*) into n from public.comments
      where author = new.author and created_at > now() - interval '10 minutes';
    if n >= 30 then raise exception 'rate_limit' using errcode = 'P0001'; end if;
  elsif tg_table_name = 'gyms' then
    select count(*) into n from public.gyms
      where created_by = new.created_by and created_at > now() - interval '1 day';
    if n >= 5 then raise exception 'rate_limit' using errcode = 'P0001'; end if;
  end if;
  return new;
end $$;

drop trigger if exists posts_rate on public.posts;
create trigger posts_rate before insert on public.posts
  for each row execute function public.community_rate_limit();
drop trigger if exists comments_rate on public.comments;
create trigger comments_rate before insert on public.comments
  for each row execute function public.community_rate_limit();
drop trigger if exists gyms_rate on public.gyms;
create trigger gyms_rate before insert on public.gyms
  for each row when (new.source = 'user')
  execute function public.community_rate_limit();

-- Posts: edits touch edited_at; authors can't change counters or hidden.
create or replace function public.posts_guard()
returns trigger language plpgsql as $$
begin
  -- current_user is the function owner inside the security definer
  -- counter triggers, so only direct edits by the author are guarded.
  if current_user = 'authenticated' then
    new.like_count := old.like_count;
    new.comment_count := old.comment_count;
    new.hidden := old.hidden;
    new.gym_id := old.gym_id;
    new.author := old.author;
    new.created_at := old.created_at;
    new.edited_at := now();
  end if;
  return new;
end $$;

drop trigger if exists posts_guard on public.posts;
create trigger posts_guard before update on public.posts
  for each row execute function public.posts_guard();

-- Three reports from different people hide the post or comment.
create or replace function public.reports_autohide()
returns trigger language plpgsql security definer set search_path = '' as $$
declare n int;
begin
  select count(*) into n from public.reports
    where target_type = new.target_type and target_id = new.target_id;
  if n >= 3 then
    if new.target_type = 'post' then
      update public.posts set hidden = true where id = new.target_id;
    else
      update public.comments set hidden = true where id = new.target_id;
    end if;
  end if;
  return null;
end $$;

drop trigger if exists reports_autohide on public.reports;
create trigger reports_autohide after insert on public.reports
  for each row execute function public.reports_autohide();

-- Row level security ---------------------------------------------------------------

alter table public.gyms enable row level security;
alter table public.community_profiles enable row level security;
alter table public.gym_members enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.post_likes enable row level security;
alter table public.reports enable row level security;
alter table public.user_blocks enable row level security;

-- Gyms: everyone reads; signed-in users add ('user' source, as themselves).
drop policy if exists "gyms: read" on public.gyms;
create policy "gyms: read" on public.gyms for select to anon, authenticated using (true);
drop policy if exists "gyms: add" on public.gyms;
create policy "gyms: add" on public.gyms for insert to authenticated
  with check (source = 'user' and created_by = auth.uid() and member_count = 0 and post_count = 0);

drop policy if exists "profiles: read" on public.community_profiles;
create policy "profiles: read" on public.community_profiles for select to anon, authenticated using (true);
drop policy if exists "profiles: own" on public.community_profiles;
create policy "profiles: own" on public.community_profiles for insert to authenticated
  with check (user_id = auth.uid()
    and (avatar is null or avatar like auth.uid()::text || '/%'));
drop policy if exists "profiles: own update" on public.community_profiles;
create policy "profiles: own update" on public.community_profiles for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid()
    and (avatar is null or avatar like auth.uid()::text || '/%'));

drop policy if exists "members: own" on public.gym_members;
create policy "members: own" on public.gym_members for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Posts and comments: hidden ones and ones by people I blocked aren't shown
-- (my own stay visible to me).
drop policy if exists "posts: read" on public.posts;
create policy "posts: read" on public.posts for select to anon, authenticated using (
  author = auth.uid() or (
    not hidden and not exists (
      select 1 from public.user_blocks b where b.blocker = auth.uid() and b.blocked = posts.author)));
drop policy if exists "posts: write" on public.posts;
create policy "posts: write" on public.posts for insert to authenticated
  with check (author = auth.uid() and like_count = 0 and comment_count = 0 and not hidden);
drop policy if exists "posts: edit" on public.posts;
create policy "posts: edit" on public.posts for update to authenticated
  using (author = auth.uid()) with check (author = auth.uid());
drop policy if exists "posts: delete" on public.posts;
create policy "posts: delete" on public.posts for delete to authenticated using (author = auth.uid());

drop policy if exists "comments: read" on public.comments;
create policy "comments: read" on public.comments for select to anon, authenticated using (
  author = auth.uid() or (
    not hidden and not exists (
      select 1 from public.user_blocks b where b.blocker = auth.uid() and b.blocked = comments.author)));
drop policy if exists "comments: write" on public.comments;
create policy "comments: write" on public.comments for insert to authenticated
  with check (author = auth.uid() and not hidden);
drop policy if exists "comments: delete" on public.comments;
create policy "comments: delete" on public.comments for delete to authenticated using (author = auth.uid());

drop policy if exists "likes: own" on public.post_likes;
create policy "likes: own" on public.post_likes for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Reports: write only (reviewed in the dashboard).
drop policy if exists "reports: write" on public.reports;
create policy "reports: write" on public.reports for insert to authenticated
  with check (reporter = auth.uid());

drop policy if exists "blocks: own" on public.user_blocks;
create policy "blocks: own" on public.user_blocks for all to authenticated
  using (blocker = auth.uid()) with check (blocker = auth.uid());

-- 운동 라운지 ---------------------------------------------------------------------

-- Boards for everyone by sport: gyms rows with source 'topic' (id 't-...').
-- They aren't in the gym search and can't be joined as "my gym".
alter table public.gyms drop constraint if exists gyms_source_check;
alter table public.gyms add constraint gyms_source_check
  check (source in ('open', 'user', 'topic'));

insert into public.gyms (id, name, source) values
  ('t-health', '헬스', 'topic'),
  ('t-crossfit', '크로스핏', 'topic'),
  ('t-running', '러닝', 'topic'),
  ('t-yoga', '요가', 'topic'),
  ('t-pilates', '필라테스', 'topic'),
  ('t-diet', '다이어트·식단', 'topic'),
  ('t-home', '홈트', 'topic'),
  ('t-swimming', '수영', 'topic'),
  ('t-climbing', '클라이밍', 'topic'),
  ('t-cycling', '자전거', 'topic'),
  ('t-combat', '복싱·격투기', 'topic'),
  ('t-free', '자유수다', 'topic')
on conflict (id) do update set name = excluded.name, source = 'topic';

-- My gyms: at most 3, and not the 라운지 boards.
create or replace function public.gym_members_guard()
returns trigger language plpgsql security definer set search_path = '' as $$
declare n int;
begin
  if exists (select 1 from public.gyms where id = new.gym_id and source = 'topic') then
    raise exception 'topic_board' using errcode = 'P0001';
  end if;
  perform pg_advisory_xact_lock(hashtext('gym_members:' || new.user_id::text));
  select count(*) into n from public.gym_members
    where user_id = new.user_id and gym_id <> new.gym_id;
  if n >= 3 then raise exception 'gym_limit' using errcode = 'P0001'; end if;
  return new;
end $$;

drop trigger if exists gym_members_guard on public.gym_members;
create trigger gym_members_guard before insert on public.gym_members
  for each row execute function public.gym_members_guard();

-- Search -------------------------------------------------------------------------

-- Gyms whose name or address contains every word of the query (spaces
-- ignored within a word): ones whose name has them all first, then the
-- busiest.
create or replace function public.search_gyms(q text, lim int default 30)
returns setof public.gyms language sql stable set search_path = '' as $$
  with w as (
    select array_agg(x) as words
    from unnest(string_to_array(lower(trim(q)), ' ')) as x where x <> ''
  )
  select g.* from public.gyms g, w
  where g.source <> 'topic'
    and (select bool_and(g.search like '%' || x || '%') from unnest(w.words) as x)
  order by
    (select bool_and(lower(replace(g.name, ' ', '')) like '%' || x || '%')
       from unnest(w.words) as x) desc,
    g.member_count desc, g.post_count desc, char_length(g.name), g.name
  limit least(greatest(lim, 1), 50);
$$;

grant execute on function public.search_gyms(text, int) to anon, authenticated;

-- Comment likes ------------------------------------------------------------------

alter table public.comments add column if not exists like_count int not null default 0;

create table if not exists public.comment_likes (
  comment_id uuid not null references public.comments (id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

alter table public.comment_likes enable row level security;
drop policy if exists "comment likes: own" on public.comment_likes;
create policy "comment likes: own" on public.comment_likes for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function public.comment_likes_count()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    update public.comments set like_count = like_count + 1 where id = new.comment_id;
  else
    update public.comments set like_count = greatest(like_count - 1, 0) where id = old.comment_id;
  end if;
  return null;
end $$;

drop trigger if exists comment_likes_count on public.comment_likes;
create trigger comment_likes_count after insert or delete on public.comment_likes
  for each row execute function public.comment_likes_count();

-- Notifications ------------------------------------------------------------------

-- Written only by the triggers below; each user reads and marks their own.
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,  -- who gets it
  actor      uuid references public.community_profiles (user_id) on delete cascade,
  kind       text not null
    check (kind in ('post_like', 'comment', 'reply', 'comment_like', 'hot')),
  post_id    uuid references public.posts (id) on delete cascade,
  comment_id uuid references public.comments (id) on delete cascade,
  count      int not null default 1,   -- likes on one thing grouped: "외 N명"
  read_at    timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_time
  on public.notifications (user_id, created_at desc);
create index if not exists notifications_unread
  on public.notifications (user_id) where read_at is null;

alter table public.notifications enable row level security;
drop policy if exists "notifications: read own" on public.notifications;
create policy "notifications: read own" on public.notifications for select to authenticated
  using (user_id = auth.uid());
drop policy if exists "notifications: mark own" on public.notifications;
create policy "notifications: mark own" on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "notifications: delete own" on public.notifications;
create policy "notifications: delete own" on public.notifications for delete to authenticated
  using (user_id = auth.uid());

-- Likes this many make a post 인기글 (CommunityLimits.hotLikes in the app).
create or replace function public.community_hot_likes()
returns int language sql immutable as $$ select 5 $$;

create or replace function public.community_notify(
  target uuid, who uuid, what text, post uuid, cmt uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if target is null or target = who then return; end if;
  if who is not null and exists (
    select 1 from public.user_blocks where blocker = target and blocked = who) then
    return;
  end if;
  -- Someone without a nickname yet shows as "누군가".
  if who is not null and not exists (
    select 1 from public.community_profiles where user_id = who) then
    who := null;
  end if;
  if what in ('post_like', 'comment_like') then
    -- Likes on the same thing stay one unread notification.
    update public.notifications
      set count = count + 1, actor = coalesce(who, actor), created_at = now()
      where user_id = target and kind = what and read_at is null
        and post_id is not distinct from post and comment_id is not distinct from cmt;
    if found then return; end if;
  end if;
  insert into public.notifications (user_id, actor, kind, post_id, comment_id)
    values (target, who, what, post, cmt);
end $$;

revoke execute on function public.community_notify(uuid, uuid, text, uuid, uuid)
  from public, anon, authenticated;

create or replace function public.notify_post_like()
returns trigger language plpgsql security definer set search_path = '' as $$
declare p record;
begin
  -- Runs after post_likes_count (triggers go by name), so like_count is new.
  select author, like_count into p from public.posts where id = new.post_id;
  perform public.community_notify(p.author, new.user_id, 'post_like', new.post_id, null);
  if p.like_count = public.community_hot_likes() and not exists (
    select 1 from public.notifications where post_id = new.post_id and kind = 'hot') then
    perform public.community_notify(p.author, null, 'hot', new.post_id, null);
  end if;
  return null;
end $$;

drop trigger if exists post_likes_notify on public.post_likes;
create trigger post_likes_notify after insert on public.post_likes
  for each row execute function public.notify_post_like();

create or replace function public.notify_comment()
returns trigger language plpgsql security definer set search_path = '' as $$
declare post_author uuid;
begin
  select author into post_author from public.posts where id = new.post_id;
  if new.reply_to is not null then
    perform public.community_notify(new.reply_to, new.author, 'reply', new.post_id, new.id);
  end if;
  if post_author is distinct from new.reply_to then
    perform public.community_notify(post_author, new.author, 'comment', new.post_id, new.id);
  end if;
  return null;
end $$;

drop trigger if exists comments_notify on public.comments;
create trigger comments_notify after insert on public.comments
  for each row execute function public.notify_comment();

create or replace function public.notify_comment_like()
returns trigger language plpgsql security definer set search_path = '' as $$
declare c record;
begin
  select author, post_id into c from public.comments where id = new.comment_id;
  perform public.community_notify(c.author, new.user_id, 'comment_like', c.post_id, new.comment_id);
  return null;
end $$;

drop trigger if exists comment_likes_notify on public.comment_likes;
create trigger comment_likes_notify after insert on public.comment_likes
  for each row execute function public.notify_comment_like();

-- Photos -------------------------------------------------------------------------

-- Public bucket; each user writes only under their own folder "<uid>/...".
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('community', 'community', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

drop policy if exists "community photos: upload own" on storage.objects;
create policy "community photos: upload own" on storage.objects for insert to authenticated
  with check (bucket_id = 'community' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "community photos: delete own" on storage.objects;
create policy "community photos: delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'community' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "community photos: list own" on storage.objects;
create policy "community photos: list own" on storage.objects for select to authenticated
  using (bucket_id = 'community' and (storage.foldername(name))[1] = auth.uid()::text);

notify pgrst, 'reload schema';

-- 운영: 신고 처리와 이용 정지 (operator) -------------------------------------------
-- Reports are reviewed within 24 hours (web/terms.html). The operator works
-- in the SQL Editor: docs/community-ops.md has the steps.

alter table public.reports add column if not exists reviewed_at timestamptz;

-- Banned from the community: can't post or comment any more. Only the
-- operator (SQL Editor / service role) reads or writes it.
create table if not exists public.community_bans (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  reason     text not null default '',
  created_at timestamptz not null default now()
);
alter table public.community_bans enable row level security;
revoke all on public.community_bans from anon, authenticated;

create or replace function public.community_ban_check()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if exists (select 1 from public.community_bans where user_id = new.author) then
    raise exception 'banned' using errcode = 'P0001';
  end if;
  return new;
end $$;

drop trigger if exists posts_ban on public.posts;
create trigger posts_ban before insert or update of body, images, tag on public.posts
  for each row execute function public.community_ban_check();
drop trigger if exists comments_ban on public.comments;
create trigger comments_ban before insert or update of body on public.comments
  for each row execute function public.community_ban_check();

-- What still waits for a look: one row per reported post or comment.
create or replace view public.report_queue
with (security_invoker = true) as
select
  r.target_type,
  r.target_id,
  count(*)::int                          as reports,
  min(r.created_at)                      as first_reported,
  string_agg(distinct r.reason, ' / ')   as reasons,
  coalesce(p.body, c.body)               as body,
  coalesce(p.author, c.author)           as author,
  pr.nickname                            as author_nickname,
  coalesce(p.hidden, c.hidden)           as hidden
from public.reports r
left join public.posts p on r.target_type = 'post' and p.id = r.target_id
left join public.comments c on r.target_type = 'comment' and c.id = r.target_id
left join public.community_profiles pr on pr.user_id = coalesce(p.author, c.author)
where r.reviewed_at is null
group by r.target_type, r.target_id, p.body, c.body, p.author, c.author,
  pr.nickname, p.hidden, c.hidden
order by min(r.created_at);
revoke all on public.report_queue from anon, authenticated;

-- One step for a report: remove (delete) or keep it, and optionally ban the
-- author. Marks every report on it reviewed. Operator only.
create or replace function public.community_resolve(
  kind text, target uuid, remove boolean default true, ban boolean default false
) returns text language plpgsql security definer set search_path = '' as $$
declare who uuid;
begin
  if kind = 'post' then
    select author into who from public.posts where id = target;
    if remove then delete from public.posts where id = target;
    else update public.posts set hidden = false where id = target; end if;
  elsif kind = 'comment' then
    select author into who from public.comments where id = target;
    if remove then delete from public.comments where id = target;
    else update public.comments set hidden = false where id = target; end if;
  else
    raise exception 'kind is post or comment';
  end if;
  update public.reports set reviewed_at = now()
    where target_type = kind and target_id = target and reviewed_at is null;
  if ban and who is not null then
    insert into public.community_bans (user_id, reason)
      values (who, 'report ' || kind || ' ' || target)
      on conflict (user_id) do nothing;
  end if;
  return case when remove then 'removed' else 'kept' end
    || case when ban and who is not null then ', author banned' else '' end;
end $$;
revoke all on function public.community_resolve(text, uuid, boolean, boolean)
  from public, anon, authenticated;

-- How many reports wait (for the notifier, with the service role key).
create or replace function public.community_open_reports()
returns int language sql security definer set search_path = '' as $$
  select count(distinct (target_type, target_id))::int
  from public.reports where reviewed_at is null
$$;
revoke all on function public.community_open_reports() from public, anon, authenticated;
grant execute on function public.community_open_reports() to service_role;
