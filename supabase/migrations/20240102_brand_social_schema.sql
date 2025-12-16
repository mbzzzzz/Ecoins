-- ALIGN DATABASE WITH FLUTTER CODE

-- 1. Create 'offers' table (Brand Portal uses this, distinct from 'rewards')
create table if not exists public.offers (
  id uuid default uuid_generate_v4() primary key,
  brand_id uuid references public.brands(id) not null,
  title text not null,
  description text,
  points_cost int not null default 100,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- Enable RLS for offers
alter table public.offers enable row level security;

create policy "Brands can manage own offers" on public.offers
  for all using (brand_id in (select id from public.brands where owner_user_id = auth.uid()));

create policy "Public can view active offers" on public.offers
  for select using (is_active = true);


-- 2. Create 'friendships' table (Social Screen)
create table if not exists public.friendships (
  id uuid default uuid_generate_v4() primary key,
  requester_id uuid references public.profiles(id) not null,
  addressee_id uuid references public.profiles(id) not null,
  status text check (status in ('pending', 'accepted', 'declined')) default 'pending',
  created_at timestamptz default now(),
  unique(requester_id, addressee_id)
);

-- Enable RLS for friendships
alter table public.friendships enable row level security;

create policy "Users can see their own friendships" on public.friendships
  for select using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "Users can insert friendship requests" on public.friendships
  for insert with check (auth.uid() = requester_id);

create policy "Users can update their own friendships" on public.friendships
  for update using (auth.uid() = requester_id or auth.uid() = addressee_id);
  
create policy "Users can delete their own friendships" on public.friendships
  for delete using (auth.uid() = requester_id or auth.uid() = addressee_id);


-- 3. Create 'activity_feed' view (Social Screen)
create or replace view public.activity_feed as
select 
  p.display_name as user_name,
  p.avatar_url,
  a.category,
  a.description,
  a.points_earned,
  a.carbon_saved,
  a.logged_at,
  a.user_id
from public.activities a
join public.profiles p on a.user_id = p.id;

-- Grant access
grant select on public.activity_feed to authenticated;
grant select on public.activity_feed to anon;

-- 4. Add 'owner_user_id' to brands if missing
alter table public.brands add column if not exists owner_user_id uuid references auth.users(id);

-- Update RLS for brands to allow owner to manage
drop policy if exists "Brands are viewable by everyone" on public.brands;
create policy "Brands are viewable by everyone" on public.brands for select using (true);
create policy "Brand owners can update" on public.brands for update using (owner_user_id = auth.uid());
create policy "Brand owners can insert" on public.brands for insert with check (owner_user_id = auth.uid());

-- 5. Add 'api_key' plain text column for WidgetIntegrationScreen
alter table public.brands add column if not exists api_key text;

-- 6. Notifications Table (NotificationScreen)
create table if not exists public.notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  type text, -- 'friend_request', 'challenge', 'reward'
  title text not null,
  message text not null,
  is_read boolean default false,
  created_at timestamptz default now()
);

alter table public.notifications enable row level security;

create policy "Users can view own notifications" on public.notifications
  for select using (auth.uid() = user_id);

create policy "Users can update own notifications" on public.notifications
  for update using (auth.uid() = user_id);
