-- Add missing columns to profiles table for bio and timestamps
alter table public.profiles
  add column if not exists bio text,
  add column if not exists updated_at timestamptz default now(),
  add column if not exists brand_id uuid references public.brands(id);

-- Helpful index for lookups by brand
create index if not exists idx_profiles_brand_id on public.profiles(brand_id);

-- Ensure RLS on profiles allows users to manage their own row
alter table public.profiles enable row level security;

drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;

create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);

create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

-- Make sure brands table has expected columns (owner_user_id already created earlier)
alter table public.brands
  add column if not exists updated_at timestamptz default now();

-- RLS: keep public read, but restrict writes to brand owners only
alter table public.brands enable row level security;

drop policy if exists "Brands are viewable by everyone" on public.brands;
drop policy if exists "Brand owners can manage their brands" on public.brands;

create policy "Brands are viewable by everyone" on public.brands
  for select using (true);

create policy "Brand owners can insert brands" on public.brands
  for insert
  with check (auth.uid() = owner_user_id);

create policy "Brand owners can update brands" on public.brands
  for update using (auth.uid() = owner_user_id);

create policy "Brand owners can delete brands" on public.brands
  for delete using (auth.uid() = owner_user_id);

-- Indexes for brands
create index if not exists idx_brands_owner_user_id on public.brands(owner_user_id);

