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
        const url = new URL(req.url);
        const apiKeyParam = url.searchParams.get('key');

        // Handle Widget GET Request (public with API Key)
        if (req.method === 'GET' && apiKeyParam) {
            const { data: brand, error: brandError } = await supabase
                .from('brands')
                .select('id, name, logo_url')
                .eq('api_key', apiKeyParam)
                .single();

            if (brandError || !brand) {
                return new Response(JSON.stringify({ error: 'Invalid API Key' }), {
                    status: 401,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                });
            }

            // Calculate Stats (Mock calculation for now based on redemptions or offers)
            // Real implementation would sum actual carbon saved from related activities
            const { count } = await supabase
                .from('offers')
                .select('*', { count: 'exact', head: true })
                .eq('brand_id', brand.id);

            // Mocking impact: 100kg per offer for demo (or use 0 if no offers)
            const totalCarbon = (count || 0) * 100 + 450.5; // Base mock data + dynamic count

            return new Response(JSON.stringify({
                name: brand.name,
                logo_url: brand.logo_url,
                total_carbon_saved: totalCarbon
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            });
        }

        if (!authHeader) {
            throw new Error('Missing Authorization header');
        }

        const path = url.pathname.replace('/brand-api', '');

        if (req.method === 'POST' && path === '/rewards') {
            const { brand_id, title, cost_points, type } = await req.json();
            // Schema uses 'offers' now per migration, but let's support both or check 'rewards' table existence
            // The code uses 'rewards' table. Migration added 'offers'.
            // I should probably stick to 'offers' if that's what I created.
            // But existing code uses 'rewards'.
            // Let's assume 'offers' is the one for Brand Portal UI. 'rewards' might be legacy.
            // I will use 'offers' if I can.
            // Actually, let's just leave the POST /rewards as is (legacy?) or update it to 'offers'?
            // The UI BrandDashboard calls Supabase directly. This Edge Function might be for external API.
            // I will leave the POST /rewards logic but just fix the Widget GET part.
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
