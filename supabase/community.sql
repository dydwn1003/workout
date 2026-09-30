-- 헬스장 커뮤니티 (lib/data/community.dart).
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Safe to run again after changes.
--
-- A board per gym: gyms come from the 체력단련장업 open data
-- (tool/load_gyms.py) and users can add missing ones. Signed-in users with a
-- nickname write posts (text + up to 4 photos) and comments, like posts,
-- report and block. Three reports from different people hide a post or
-- comment until it is reviewed (hidden = false again by hand).

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

create index if not exists posts_gym_time on public.posts (gym_id, created_at desc);
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
  with check (user_id = auth.uid());
drop policy if exists "profiles: own update" on public.community_profiles;
create policy "profiles: own update" on public.community_profiles for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

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

-- Search -------------------------------------------------------------------------

-- Gyms whose name or address contains every word of the query (spaces
-- ignored within a word), busiest first.
create or replace function public.search_gyms(q text, lim int default 30)
returns setof public.gyms language sql stable set search_path = '' as $$
  select g.* from public.gyms g
  where (select bool_and(g.search like '%' || w || '%')
         from unnest(string_to_array(lower(trim(q)), ' ')) as w where w <> '')
  order by g.member_count desc, g.post_count desc, char_length(g.name), g.name
  limit least(greatest(lim, 1), 50);
$$;

grant execute on function public.search_gyms(text, int) to anon, authenticated;

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
