-- VERIFICATION SYSTEM MIGRATION

-- 1. Create Status Enum
do $$ begin
    create type verification_status as enum ('pending', 'verified', 'rejected', 'auto_verified');
exception
    when duplicate_object then null;
end $$;

-- 2. Add Verification Columns to Activities
alter table public.activities 
add column if not exists status verification_status default 'auto_verified',
add column if not exists verification_data jsonb;

-- 3. Rate Limit Function (Tier 1 Logic)
-- Returns true if user is allowed to log, false if rate limited
create or replace function public.check_rate_limit(
  p_user_id uuid, 
  p_category activity_category
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  recent_count int;
begin
  -- Check for logs in last 4 hours for this category
  select count(*) into recent_count
  from public.activities
  where user_id = p_user_id
  and category = p_category
  and logged_at > now() - interval '4 hours';

  if recent_count > 0 then
    return false; -- Rate limit hit
  else
    return true; -- OK to log
  end if;
end;
$$;
