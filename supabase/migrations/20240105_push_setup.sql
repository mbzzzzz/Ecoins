-- Add fcm_token to profiles
alter table public.profiles add column if not exists fcm_token text;

-- Create Trigger execution
create or replace function public.trigger_push_notification()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Call Edge Function
  -- Note: In real production, we use net.http_post or pg_net if enabled.
  -- Since we cannot easily enable pg_net here, we will mock this step.
  -- The standard way is using Supabase Database Webhooks shown in the dashboard.
  -- For this script, we will just rely on the table insert and assume the webhook is configured in Dashboard.
  return new;
end;
$$;

-- We actually just need to tell the user to enable the Webhook in the Dashboard.
-- "Database Webhooks" -> Create Webhook -> Table: notifications (INSERT) -> URL: Edge Function.
-- But we CAN create the column.
