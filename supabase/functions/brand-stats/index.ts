import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_ANON_KEY') ?? ''
        )

        const { apiKey } = await req.json()

        if (!apiKey) {
            throw new Error('Missing apiKey')
        }

        // 1. Validate API Key and get Brand
        const { data: brand, error: brandError } = await supabaseClient
            .from('brands')
            .select('id, name')
            .eq('api_key', apiKey)
            .single()

        if (brandError || !brand) {
            return new Response(JSON.stringify({ error: 'Invalid API Key' }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 401,
            })
        }

        // 2. Calculate Impact
        // For MVP: Count total rewards redeemed for this brand
        const { data: rewards, error: rewardsError } = await supabaseClient
            .from('rewards')
            .select('id, cost_points')
            .eq('brand_id', brand.id)

        let totalRedemptions = 0
        let totalPointsSpent = 0

        if (rewards && rewards.length > 0) {
            const rewardIds = rewards.map(r => r.id)

            const { count, error: userRewardsError } = await supabaseClient
                .from('user_rewards')
                .select('*', { count: 'exact', head: true }) // just count
                .in('reward_id', rewardIds)

            if (count) totalRedemptions = count

            // Rough validation: approximate points
            // To be exact we'd join, but head count is faster. 
            // Let's just estimate impact for now based on redemptions * avg cost for demo speed
            // Or fetch user_rewards with reward_id to sum properly? 
            // Supabase count is efficient. Summing implies fetching data.
            // Let's just return count for now.
        }

        // Simulated "Carbon Saved" = redemptions * 5kg (example metric)
        const carbonSaved = totalRedemptions * 5

        return new Response(
            JSON.stringify({
                brand: brand.name,
                coupons_redeemed: totalRedemptions,
                estimated_carbon_saved_kg: carbonSaved,
                widget_url: `https://ecoins-widget.vercel.app?k=${apiKey}` // Hypothetical
            }),
            {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 200,
            }
        )

    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        })
    }
})
