import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0";
// Note: In production, use a verified service account via JWT
// For this MVP, we'll assume we hit the FCM HTTP v1 API directly or use a Deno FCM library if available.
// To keep it simple and robust, we will use the legacy HTTP API or just log it if credentials are missing.

// Actually, let's use a placeholder. The user needs to add their FCM Server Key.
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY') ?? '';

serve(async (req) => {
    const { record } = await req.json();

    // 'record' is the new row from the 'notifications' table trigger
    if (!record || !record.user_id) {
        return new Response("No record", { status: 400 });
    }

    // 1. Get User's FCM Token (We need to store this in profiles)
    const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: profile } = await supabase
        .from('profiles')
        .select('fcm_token')
        .eq('id', record.user_id)
        .single();

    if (!profile?.fcm_token) {
        return new Response("User has no FCM Token", { status: 200 });
    }

    // 2. Send to FCM
    if (!FCM_SERVER_KEY) {
        console.log("Missing FCM_SERVER_KEY. Simulating send:", record.message);
        return new Response("Simulated Send (Missing Key)", { status: 200 });
    }

    const res = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `key=${FCM_SERVER_KEY}`
        },
        body: JSON.stringify({
            to: profile.fcm_token,
            notification: {
                title: record.title,
                body: record.message
            }
        })
    });

    const result = await res.json();
    return new Response(JSON.stringify(result), { headers: { "Content-Type": "application/json" } });
});
