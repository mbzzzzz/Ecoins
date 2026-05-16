// @ts-nocheck
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function getAccessToken(clientEmail: string, privateKey: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

  const signingInput = `${encode({ alg: 'RS256', typ: 'JWT' })}.${encode(payload)}`;

  // Normalize private key — handle both literal \n and actual newlines
  const normalizedKey = privateKey.includes('\\n')
    ? privateKey.replace(/\\n/g, '\n')
    : privateKey;

  const keyData = normalizedKey
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\n/g, '');

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  const encodedSig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${signingInput}.${encodedSig}`,
    }),
  });

  const tokenData = await tokenRes.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get FCM access token: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { user_ids, title, body, data } = await req.json();

    if (!user_ids || !Array.isArray(user_ids) || user_ids.length === 0) {
      return new Response(JSON.stringify({ error: 'user_ids array required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const clientEmail = Deno.env.get('FCM_SERVICE_ACCOUNT_EMAIL');
    const privateKey = Deno.env.get('FCM_SERVICE_ACCOUNT_KEY');
    const projectId = Deno.env.get('FCM_PROJECT_ID');

    if (!clientEmail || !privateKey || !projectId) {
      // Silently succeed — FCM not configured, in-app realtime still works
      return new Response(JSON.stringify({ sent: 0, skipped: 'FCM credentials not configured' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { data: profiles, error } = await supabase
      .from('profiles')
      .select('fcm_token')
      .in('id', user_ids)
      .not('fcm_token', 'is', null);

    if (error) throw error;

    const tokens: string[] = (profiles ?? [])
      .map((p: { fcm_token: string }) => p.fcm_token)
      .filter(Boolean);

    if (tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0, reason: 'No FCM tokens found' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const accessToken = await getAccessToken(clientEmail, privateKey);
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    // FCM v1 requires all data values to be strings
    const dataStringified = Object.fromEntries(
      Object.entries(data ?? {}).map(([k, v]) => [k, String(v)])
    );

    const results = await Promise.allSettled(
      tokens.map((token) =>
        fetch(fcmUrl, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body },
              data: dataStringified,
              android: { priority: 'high' },
            },
          }),
        }).then((r) => r.json())
      )
    );

    const sent = results.filter((r) => r.status === 'fulfilled').length;

    return new Response(JSON.stringify({ sent, total: tokens.length }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
