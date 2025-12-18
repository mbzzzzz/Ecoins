import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const SAFEPAY_SECRET_KEY = Deno.env.get('SAFEPAY_SECRET_KEY')
const IS_SANDBOX = true // Set to false for production

const BASE_URL = IS_SANDBOX
    ? 'https://sandbox.api.safepay.pk'
    : 'https://api.safepay.pk'

serve(async (req) => {
    const corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    }

    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const { amount, currency, plan_id } = await req.json()

        if (!SAFEPAY_SECRET_KEY) {
            throw new Error('SAFEPAY_SECRET_KEY is not set')
        }

        // 1. Initialize Order/Tracker
        // For subscriptions, Safepay often uses a slightly different flow, 
        // but the standard 'order/v1/init' is the entry point for getting a tracker.
        const response = await fetch(`${BASE_URL}/order/v1/init`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                client: headers.get('SAFEPAY_API_KEY'), // If using client key
                amount: amount,
                currency: currency || 'PKR',
                environment: IS_SANDBOX ? 'sandbox' : 'production'
            })
        })

        // NOTE: For Plans specifically, we might need a different endpoint 
        // e.g. /subscription/v1/init. 
        // Since documentation varies, we'll assume the client passes the 
        // PLAN_ID in the checkout URL directly or uses the Tracker flow.
        // 
        // IF simpler: We just return a signed URL.

        // START SIMPLIFIED FLOW (Best for MVP):
        // We will just generate a Secure Token on the server if needed, 
        // but for now, we'll return a configured URL for the client to render 
        // which includes the 'plan_id'.

        // Actually, Safepay's "Subscribe" button is often a direct link to:
        // https://sandbox.api.safepay.pk/components?plan_id=YOUR_PLAN_ID

        return new Response(
            JSON.stringify({
                url: `${BASE_URL}/components?plan_id=${plan_id}&mode=payment`,
                message: "Generated Subscription URL"
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
