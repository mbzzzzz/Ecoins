-- Function to handle new user creation
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  user_role user_role;
begin
  -- Determine role from metadata, default to 'user'
  -- Cast carefully to the enum type
  user_role := COALESCE(
    (new.raw_user_meta_data->>'role')::user_role,
    'user'::user_role
  );

  insert into public.profiles (id, email, display_name, role)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    user_role
  );
  return new;
end;
$$;

-- Trigger
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Ensure roles are strictly enforced in RLS if not already
-- (Existing policies seem okay: "Users can update own profile" using auth.uid())

-- Verify enum has brand_admin
-- alter type user_role add value if not exists 'brand_admin';
