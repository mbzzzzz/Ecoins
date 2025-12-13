-- FRIENDSHIPS TABLE
-- status: 'pending', 'accepted', 'blocked'
create type friendship_status as enum ('pending', 'accepted', 'blocked');

create table public.friendships (
  id uuid default uuid_generate_v4() primary key,
  requester_id uuid references public.profiles(id) not null,
  addressee_id uuid references public.profiles(id) not null,
  status friendship_status default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(requester_id, addressee_id)
);

-- RLS for Friendships
alter table public.friendships enable row level security;

-- Users can see their own friendships (either as requester or addressee)
create policy "Users can view own friendships" on public.friendships
  for select using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- Users can create a friendship request
create policy "Users can send friend requests" on public.friendships
  for insert with check (auth.uid() = requester_id);

-- Users can update status (e.g., accept) if they are involved
create policy "Users can update own friendships" on public.friendships
  for update using (auth.uid() = requester_id or auth.uid() = addressee_id);


-- ACTIVITY FEED VIEW
-- Shows activities from the user AND their accepted friends
create or replace view public.activity_feed with (security_invoker = true) as
select 
  a.id as activity_id,
  a.user_id,
  p.display_name as user_name,
  p.avatar_url,
  a.category,
  a.description,
  a.points_earned,
  a.carbon_saved,
  a.logged_at,
  'activity' as feed_type
from public.activities a
join public.profiles p on a.user_id = p.id
where 
  -- Activity is by the current user
  a.user_id = auth.uid()
  OR
  -- OR by a friend of the current user
  exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
    and (
      (f.requester_id = auth.uid() and f.addressee_id = a.user_id)
      or
      (f.addressee_id = auth.uid() and f.requester_id = a.user_id)
    )
  );
