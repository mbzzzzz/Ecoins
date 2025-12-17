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

            // Calculate real carbon saved from user activities related to this brand
            // Method 1: Sum from redemptions (if carbon_value_snapshot exists)
            const { data: offers } = await supabase
                .from('offers')
                .select('id')
                .eq('brand_id', brand.id);

            let totalCarbon = 0;
            
            if (offers && offers.length > 0) {
                const offerIds = offers.map(o => o.id);
                
                // Get redemptions and sum carbon_value_snapshot
                const { data: redemptions } = await supabase
                    .from('redemptions')
                    .select('carbon_value_snapshot')
                    .in('offer_id', offerIds);
                
                if (redemptions && redemptions.length > 0) {
                    totalCarbon = redemptions.reduce((sum, r) => {
                        const carbon = r.carbon_value_snapshot || 0;
                        return sum + carbon;
                    }, 0);
                }
            }
            
            // Method 2: If no redemptions with carbon, calculate from user activities
            // that earned points used for this brand's offers
            if (totalCarbon === 0) {
                // Get all users who redeemed this brand's offers
                if (offers && offers.length > 0) {
                    const offerIds = offers.map(o => o.id);
                    const { data: userRedemptions } = await supabase
                        .from('redemptions')
                        .select('user_id')
                        .in('offer_id', offerIds);
                    
                    if (userRedemptions && userRedemptions.length > 0) {
                        const userIds = [...new Set(userRedemptions.map(r => r.user_id))];
                        
                        // Sum carbon from activities of users who redeemed
                        const { data: activities } = await supabase
                            .from('activities')
                            .select('carbon_saved')
                            .in('user_id', userIds)
                            .gte('logged_at', new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString()); // Last 90 days
                        
                        if (activities) {
                            totalCarbon = activities.reduce((sum, a) => {
                                return sum + (a.carbon_saved || 0);
                            }, 0);
                        }
                    }
                }
            }
            
            // Fallback to brand's total_carbon_saved column if available
            if (totalCarbon === 0 && brand.total_carbon_saved) {
                totalCarbon = brand.total_carbon_saved;
            }

            return new Response(JSON.stringify({
                name: brand.name,
                logo_url: brand.logo_url,
                total_carbon_saved: totalCarbon,
                updated_at: new Date().toISOString()
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
