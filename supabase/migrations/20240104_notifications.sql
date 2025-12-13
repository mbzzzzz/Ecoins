-- NOTIFICATIONS
create type notification_type as enum ('friend_request', 'challenge', 'system', 'reward');

create table public.notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  title text not null,
  message text not null,
  type notification_type default 'system',
  is_read boolean default false,
  created_at timestamptz default now()
);

-- RLS
alter table public.notifications enable row level security;

create policy "Users can view own notifications" on public.notifications
  for select using (auth.uid() = user_id);

create policy "Users can update own notifications" on public.notifications
  for update using (auth.uid() = user_id);

-- TRIGGER: Notify on New Friend Request
create or replace function public.handle_new_friend_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requester_name text;
begin
  select display_name into requester_name from public.profiles where id = new.requester_id;
  
  insert into public.notifications (user_id, title, message, type)
  values (
    new.addressee_id,
    'New Friend Request',
    coalesce(requester_name, 'Someone') || ' sent you a friend request!',
    'friend_request'
  );
  return new;
end;
$$;

create trigger on_new_friend_request
  after insert on public.friendships
  for each row
  when (new.status = 'pending')
  execute function public.handle_new_friend_request();
