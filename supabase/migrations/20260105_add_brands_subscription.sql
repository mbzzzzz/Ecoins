-- Add subscription tracking to brands
alter table public.brands
  add column if not exists subscription_tier text default 'free', -- 'free', 'pro', 'enterprise'
  add column if not exists subscription_status text default 'inactive', -- 'active', 'inactive'
  add column if not exists subscription_end_date timestamptz;

-- Policy: Brands can read their own subscription status
create policy "Brands can view own subscription" on public.brands
  for select using (true); -- Public read is already enabled, but good to be explicit mentally
