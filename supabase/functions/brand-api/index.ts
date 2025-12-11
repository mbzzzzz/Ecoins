import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        );

        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
            throw new Error('Missing Authorization header');
        }

        // In a real app, we would validate the API Key against the 'brands' table
        // For MVP, we assume it's a valid brand_id if passed
        // const apiKey = authHeader.replace('Bearer ', '');
        // const { data: brand } = await supabase.from('brands').select('id').eq('api_key_hash', apiKey).single();

        const url = new URL(req.url);
        const path = url.pathname.replace('/brand-api', '');

        if (req.method === 'POST' && path === '/rewards') {
            const { brand_id, title, cost_points, type } = await req.json();
            const { data, error } = await supabase
                .from('rewards')
                .insert({ brand_id, title, cost_points, type })
                .select()
                .single();

            if (error) throw error;
            return new Response(JSON.stringify(data), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            });
        }

        if (req.method === 'GET' && path === '/redemptions') {
            const brand_id = url.searchParams.get('brand_id');
            if (!brand_id) throw new Error('Missing brand_id');

            // Join with rewards to filter by brand
            const { data, error } = await supabase
                .from('redemptions')
                .select('*, rewards!inner(*)')
                .eq('rewards.brand_id', brand_id)
                .order('redeemed_at', { ascending: false });

            if (error) throw error;
            return new Response(JSON.stringify(data), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            });
        }

        return new Response(JSON.stringify({ error: 'Not Found' }), {
            status: 404,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });

    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
});
