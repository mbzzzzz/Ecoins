// @ts-nocheck
// verify_jwt: false — called by a cron job, no user JWT
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const FROM_ADDRESS = 'noreply@ecoins.app';
const EMAIL_SUBJECT = 'Your weekly eco impact ⚡';
const APP_DEEP_LINK = 'https://ecoins.app'; // fallback web link for email CTA

function buildHtml(name: string, carbonKg: number, points: number): string {
  const displayName = name ?? 'Eco Champion';
  const carbonDisplay = carbonKg.toFixed(2);

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${EMAIL_SUBJECT}</title>
  <style>
    body { margin: 0; padding: 0; background: #F9FAFB; font-family: Arial, sans-serif; }
    .container { max-width: 560px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #047857, #10B981); padding: 40px 32px 32px; text-align: center; }
    .header h1 { margin: 0; color: #ffffff; font-size: 26px; font-weight: 700; letter-spacing: -0.5px; }
    .header p { margin: 8px 0 0; color: #D1FAE5; font-size: 15px; }
    .body { padding: 32px; }
    .greeting { font-size: 17px; color: #1F2937; margin: 0 0 24px; }
    .stat-row { display: flex; gap: 16px; margin-bottom: 28px; }
    .stat-card { flex: 1; background: #F0FDF4; border-radius: 12px; padding: 20px 16px; text-align: center; }
    .stat-card .value { font-size: 28px; font-weight: 700; color: #047857; margin: 0; }
    .stat-card .label { font-size: 13px; color: #6B7280; margin: 4px 0 0; }
    .cta-wrap { text-align: center; margin: 8px 0 0; }
    .cta { display: inline-block; background: #10B981; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 700; padding: 14px 32px; border-radius: 50px; letter-spacing: 0.2px; }
    .footer { padding: 20px 32px 28px; text-align: center; color: #9CA3AF; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🌿 Your Weekly Eco Impact</h1>
      <p>Here's what you achieved in the last 7 days</p>
    </div>
    <div class="body">
      <p class="greeting">Hi ${displayName},</p>
      <div class="stat-row">
        <div class="stat-card">
          <p class="value">${carbonDisplay}kg</p>
          <p class="label">CO₂ saved</p>
        </div>
        <div class="stat-card">
          <p class="value">${points}</p>
          <p class="label">points earned</p>
        </div>
      </div>
      <p style="color:#1F2937;font-size:15px;margin:0 0 28px;">
        This week you saved <strong>${carbonDisplay}kg of CO₂</strong> and earned
        <strong>${points} points</strong> on Ecoins. Keep it up! 🎉
      </p>
      <div class="cta-wrap">
        <a href="${APP_DEEP_LINK}" class="cta">Open Ecoins →</a>
      </div>
    </div>
    <div class="footer">
      You're receiving this because you have an Ecoins account.<br />
      © ${new Date().getFullYear()} Ecoins · Making sustainability rewarding.
    </div>
  </div>
</body>
</html>`;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Parse optional body — accept empty body too
    let dry_run = false;
    const contentType = req.headers.get('content-type') ?? '';
    if (contentType.includes('application/json')) {
      const bodyText = await req.text();
      if (bodyText.trim().length > 0) {
        const parsed = JSON.parse(bodyText);
        dry_run = parsed?.dry_run === true;
      }
    }

    const resendApiKey = Deno.env.get('RESEND_API_KEY');
    if (!resendApiKey) {
      return new Response(
        JSON.stringify({ sent: 0, skipped: 'RESEND_API_KEY not configured' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Fetch activities from the last 7 days, joined with profile email + name
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    const { data: activities, error: activitiesError } = await supabase
      .from('activities')
      .select('user_id, carbon_saved, logged_at, profiles(id, email, display_name)')
      .gte('logged_at', sevenDaysAgo)
      .not('profiles', 'is', null);

    if (activitiesError) throw activitiesError;

    if (!activities || activities.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, dry_run }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Aggregate per user
    type UserStats = {
      email: string;
      name: string;
      carbonSaved: number;
      points: number;
    };

    const userMap = new Map<string, UserStats>();

    for (const activity of activities) {
      const profile = activity.profiles;
      if (!profile || !profile.email) continue;

      const uid: string = activity.user_id;
      if (!userMap.has(uid)) {
        userMap.set(uid, {
          email: profile.email,
          name: profile.display_name ?? profile.email.split('@')[0],
          carbonSaved: 0,
          points: 0,
        });
      }

      const stats = userMap.get(uid)!;
      stats.carbonSaved += Number(activity.carbon_saved ?? 0);
    }

    const users = Array.from(userMap.values());

    if (dry_run) {
      return new Response(
        JSON.stringify({ sent: users.length, dry_run: true, users }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Send emails via Resend
    const results = await Promise.allSettled(
      users.map((user) =>
        fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${resendApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from: FROM_ADDRESS,
            to: [user.email],
            subject: EMAIL_SUBJECT,
            html: buildHtml(user.name, user.carbonSaved, user.points),
          }),
        }).then((r) => {
          if (!r.ok) throw new Error(`Resend HTTP ${r.status} for ${user.email}`);
          return r.json();
        })
      )
    );

    const sent = results.filter((r) => r.status === 'fulfilled').length;
    const failed = results
      .filter((r) => r.status === 'rejected')
      .map((r) => (r as PromiseRejectedResult).reason?.message ?? String((r as PromiseRejectedResult).reason));

    return new Response(
      JSON.stringify({ sent, dry_run: false, ...(failed.length > 0 ? { failed } : {}) }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: msg }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
