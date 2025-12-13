-- DAILY CHALLENGES
create table public.daily_challenges (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  description text,
  icon text, -- Emoji or icon name
  category activity_category not null,
  points_reward int not null,
  goal_count int default 1,
  active_date date default current_date, -- The date this challenge is for
  created_at timestamptz default now()
);

-- USER CHALLENGE PROGRESS
create table public.user_challenges (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  challenge_id uuid references public.daily_challenges(id) not null,
  current_count int default 0,
  is_completed boolean default false,
  completed_at timestamptz,
  unique(user_id, challenge_id)
);

-- LEADERBOARD VIEW
create or replace view public.leaderboard with (security_invoker = true) as
select 
  id as user_id,
  display_name,
  avatar_url,
  points_balance,
  carbon_saved_kg,
  rank() over (order by points_balance desc) as rank
from public.profiles;

-- RLS for New Tables
alter table public.daily_challenges enable row level security;
alter table public.user_challenges enable row level security;

-- Challenges: Public read
create policy "Challenges are viewable by everyone" on public.daily_challenges
  for select using (true);

-- User Challenges: Users manage their own
create policy "Users can view own challenge progress" on public.user_challenges
  for select using (auth.uid() = user_id);

create policy "Users can update own challenge progress" on public.user_challenges
  for all using (auth.uid() = user_id);

-- STREAK CALCULATION RPC
-- Calculates consecutive days with at least one activity
create or replace function public.get_user_streak(target_user_id uuid)
returns int
language plpgsql
security definer
as $$
declare
  streak int := 0;
  last_date date := current_date;
  check_date date;
  has_activity boolean;
begin
  -- Check mostly recent days
  for i in 0..365 loop
    check_date := current_date - i;
    
    select exists(
      select 1 from public.activities 
      where user_id = target_user_id 
      and logged_at::date = check_date
    ) into has_activity;
    
    if has_activity then
      streak := streak + 1;
      last_date := check_date;
    else
      -- Allow 1 day gap if we are just checking today (user might not have logged yet)
      if check_date = current_date then
        continue; 
      else
        exit; -- Break loop on first missing day
      end if;
    end if;
  end loop;
  
  return streak;
end;
$$;

-- SEED SOME CHALLENGES (For demo)
insert into public.daily_challenges (title, description, icon, category, points_reward, goal_count, active_date)
values 
  ('Bus Boss', 'Take public transit twice today', '🚌', 'transport', 150, 2, current_date),
  ('Meatless Monday', 'Log a vegetarian meal', '🥗', 'food', 100, 1, current_date);
