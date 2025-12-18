-- Unify Rewards system to use 'offers' table
-- This aligns the Brand Portal (which creates offers) with the User App (which redeems them)

-- 1. Enhance 'offers' table to match needs of rewards
alter table public.offers add column if not exists code_prefix text default 'ECO';
alter table public.offers add column if not exists type text default 'discount';

-- 2. Update 'redemptions' to reference 'offers' instead of 'rewards'
-- First, drop the old constraint
alter table public.redemptions drop constraint if exists redemptions_reward_id_fkey;

-- Add new constraint pointing to offers
-- We keep the column name 'reward_id' in redemptions table to avoid breaking too much code, 
-- but conceptually it now holds an offer_id.
alter table public.redemptions 
  add constraint redemptions_offer_id_fkey 
  foreign key (reward_id) 
  references public.offers(id)
  on delete cascade;

-- 3. Policy update for Redemptions (ensure users can still insert)
drop policy if exists "Users can create redemptions" on public.redemptions;
create policy "Users can create redemptions" on public.redemptions
  for insert with check (auth.uid() = user_id);
