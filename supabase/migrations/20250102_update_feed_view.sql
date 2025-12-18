-- Update activity_feed view to include verification status and evidence
create or replace view public.activity_feed as
select 
  p.display_name as user_name,
  p.avatar_url,
  a.id as activity_id,
  a.category,
  a.description,
  a.points_earned,
  a.carbon_saved,
  a.logged_at,
  a.user_id,
  a.is_verified, -- Added
  a.evidence_url -- Added
from public.activities a
join public.profiles p on a.user_id = p.id;

-- Grant access (just to be safe, though replace view usually preserves grants)
grant select on public.activity_feed to authenticated;
grant select on public.activity_feed to anon;
