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
                .select('id, name, logo_url, sustainability_goal')
                .eq('api_key', apiKeyParam)
                .single();

            if (brandError || !brand) {
                return new Response(JSON.stringify({ error: 'Invalid API Key' }), {
                    status: 401,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                });
            }

            const { data: offers } = await supabase
                .from('offers')
                .select('id')
                .eq('brand_id', brand.id);

            let totalCarbon = 0;
            let totalRedemptions = 0;
            let activeUsers = 0;

            if (offers && offers.length > 0) {
                const offerIds = offers.map((o: { id: string }) => o.id);

                const { data: allRedemptions } = await supabase
                    .from('redemptions')
                    .select('user_id')
                    .in('offer_id', offerIds);

                if (allRedemptions && allRedemptions.length > 0) {
                    totalRedemptions = allRedemptions.length;
                    const userIds = [...new Set(allRedemptions.map((r: { user_id: string }) => r.user_id))];
                    activeUsers = userIds.length;

                    const { data: activities } = await supabase
                        .from('activities')
                        .select('carbon_saved')
                        .in('user_id', userIds)
                        .gte('logged_at', new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString());

                    if (activities) {
                        totalCarbon = activities.reduce(
                            (sum: number, a: { carbon_saved: number | null }) => sum + (a.carbon_saved || 0),
                            0
                        );
                    }
                }
            }

            return new Response(JSON.stringify({
                name: brand.name,
                logo_url: brand.logo_url,
                total_carbon_saved: Math.round(totalCarbon * 100) / 100,
                sustainability_goal: brand.sustainability_goal || 2000,
                total_redemptions: totalRedemptions,
                active_users: activeUsers,
                trees_equivalent: Math.floor(totalCarbon / 20),
                updated_at: new Date().toISOString(),
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
            const { data, error } = await supabase
                .from('offers')
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

            const { data, error } = await supabase
                .from('redemptions')
                .select('*, offers!inner(*)')
                .eq('offers.brand_id', brand_id)
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

    } catch (error: unknown) {
        const msg = error instanceof Error ? error.message : String(error);
        return new Response(JSON.stringify({ error: msg }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
});
