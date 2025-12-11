-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Create Enums
create type user_role as enum ('user', 'brand_admin', 'admin');
create type activity_category as enum ('transport', 'energy', 'food', 'recycle', 'shopping');
create type reward_type as enum ('discount', 'free_item', 'donation');

-- PROFILES (Extension of auth.users)
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text unique not null,
  role user_role default 'user',
  display_name text,
  avatar_url text,
  points_balance int default 0,
  carbon_saved_kg float default 0,
  created_at timestamptz default now()
);

-- BRANDS
create table public.brands (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  description text,
  logo_url text,
  website_url text,
  api_key_hash text, -- Stored securely (e.g. hashed)
  webhook_url text,
  created_at timestamptz default now()
);

-- REWARDS
create table public.rewards (
  id uuid default uuid_generate_v4() primary key,
  brand_id uuid references public.brands(id) not null,
  title text not null,
  description text,
  type reward_type default 'discount',
  cost_points int not null,
  code_prefix text, -- e.g. "ECO-"
  is_active boolean default true,
  created_at timestamptz default now()
);

-- REDEMPTIONS
create table public.redemptions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  reward_id uuid references public.rewards(id) not null,
  promo_code text not null,
  redeemed_at timestamptz default now(),
  status text default 'active' -- active, used, expired
);

-- ACTIVITIES
create table public.activities (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  category activity_category not null,
  description text,
  carbon_saved float not null,
  points_earned int not null,
  evidence_url text, -- Photo/receipt
  logged_at timestamptz default now()
);

-- RLS POLICIES
alter table public.profiles enable row level security;
alter table public.brands enable row level security;
alter table public.rewards enable row level security;
alter table public.redemptions enable row level security;
alter table public.activities enable row level security;

-- Profiles: Users can read everyone (for leaderboards) but only update their own
create policy "Public profiles are viewable by everyone" on public.profiles
  for select using (true);

create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);

create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

-- Brands: Public read
create policy "Brands are viewable by everyone" on public.brands
  for select using (true);

-- Rewards: Public read
create policy "Rewards are viewable by everyone" on public.rewards
  for select using (true);

-- Redemptions: Users can see their own redemptions
create policy "Users can view own redemptions" on public.redemptions
  for select using (auth.uid() = user_id);

create policy "Users can create redemptions" on public.redemptions
  for insert with check (auth.uid() = user_id);

-- Activities: Users can see/create their own
create policy "Users can view own activities" on public.activities
  for select using (auth.uid() = user_id);

create policy "Users can insert own activities" on public.activities
  for insert with check (auth.uid() = user_id);

-- Setup Storage Buckets (if needed later, but good to have placeholders)
-- insert into storage.buckets (id, name) values ('avatars', 'avatars');
-- insert into storage.buckets (id, name) values ('evidence', 'evidence');
