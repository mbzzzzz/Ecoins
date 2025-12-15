-- Create brands table if it doesn't exist (for project: gwmcmlpuqummaumjloci.supabase.co)
create table if not exists public.brands (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  description text,
  logo_url text,
  website_url text,
  api_key text unique,
  api_key_hash text,
  webhook_url text,
  owner_user_id uuid references auth.users(id) on delete cascade,
  total_carbon_saved float default 0,
  created_at timestamptz default now()
);

-- Add missing columns if table already exists
alter table public.brands
  add column if not exists owner_user_id uuid references auth.users(id) on delete cascade,
  add column if not exists api_key text unique,
  add column if not exists total_carbon_saved float default 0;

-- Enable RLS
alter table public.brands enable row level security;

-- Drop existing policies if they exist
drop policy if exists "Brands are viewable by everyone" on public.brands;
drop policy if exists "Brand owners can manage their brands" on public.brands;

-- Add RLS policies
create policy "Brands are viewable by everyone" on public.brands
  for select using (true);

create policy "Brand owners can manage their brands" on public.brands
  for all using (auth.uid() = owner_user_id);

-- Add indexes for faster lookups
create index if not exists idx_brands_owner_user_id on public.brands(owner_user_id);
create index if not exists idx_brands_api_key on public.brands(api_key);

