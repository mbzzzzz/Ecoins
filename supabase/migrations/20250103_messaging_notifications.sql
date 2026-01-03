-- Create messages table for chat persistence
create table if not exists public.messages (
  id uuid default uuid_generate_v4() primary key,
  sender_id uuid references public.profiles(id) not null,
  receiver_id uuid references public.profiles(id) not null,
  content text not null,
  created_at timestamptz default now(),
  is_read boolean default false
);

-- Ensure notifications table exists and has necessary columns
create table if not exists public.notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  created_at timestamptz default now()
);

alter table public.notifications 
add column if not exists title text,
add column if not exists body text,
add column if not exists type text default 'system',
add column if not exists is_read boolean default false;

-- Policies
alter table public.messages enable row level security;
alter table public.notifications enable row level security;

do $$ 
begin
    -- Messages policies
    if not exists (select 1 from pg_policies where policyname = 'Users can read their own messages' and tablename = 'messages') then
        create policy "Users can read their own messages" on public.messages
          for select using (auth.uid() = sender_id or auth.uid() = receiver_id);
    end if;

    if not exists (select 1 from pg_policies where policyname = 'Users can insert messages' and tablename = 'messages') then
        create policy "Users can insert messages" on public.messages
          for insert with check (auth.uid() = sender_id);
    end if;

    -- Notifications policies
    if not exists (select 1 from pg_policies where policyname = 'Users can read own notifications' and tablename = 'notifications') then
        create policy "Users can read own notifications" on public.notifications
          for select using (auth.uid() = user_id);
    end if;
end $$;
