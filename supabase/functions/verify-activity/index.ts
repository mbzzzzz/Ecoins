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

    const { imageBase64, category, deviceInfo, location, imageTimestamp } = await req.json();

    if (!imageBase64 || !category) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Get GROQ API key from secrets
    const groqApiKey = Deno.env.get('GROQ_API_KEY');
    
    if (!groqApiKey) {
      return new Response(JSON.stringify({ 
        error: 'API key not configured',
        verified: false 
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Verify timestamp - must be within last hour
    if (imageTimestamp) {
      const imageDate = new Date(imageTimestamp);
      const now = new Date();
      const diffMinutes = (now.getTime() - imageDate.getTime()) / (1000 * 60);
      
      if (diffMinutes > 60 || diffMinutes < 0) {
        return new Response(JSON.stringify({
          verified: false,
          error: 'Image timestamp is not within the last hour',
          confidence: 0,
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    // Call Groq AI Vision API
    const groqResponse = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${groqApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'llama-3.2-11b-vision-preview',
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: `Verify if this image represents the eco-friendly activity category: "${category}". 
                Consider: device info (${JSON.stringify(deviceInfo)}), location (${JSON.stringify(location)}), timestamp validation.
                Output JSON only with keys: verified (bool), confidence (0-1), carbon_saved_estimate (kg, conservative), reasoning (string), description (short summary), category_suggestion (string).`
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:image/jpeg;base64,${imageBase64}`
                }
              }
            ]
          }
        ],
        temperature: 0.1,
        max_tokens: 400,
        response_format: { type: 'json_object' }
      }),
    });

    if (groqResponse.ok) {
      const data = await groqResponse.json();
      const content = data.choices[0].message.content;
      const result = JSON.parse(content);
      
      // Add metadata to result
      result.device_info = deviceInfo;
      result.location = location;
      result.image_timestamp = imageTimestamp;
      result.verification_timestamp = new Date().toISOString();
      
      return new Response(JSON.stringify(result), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } else {
      const errorText = await groqResponse.text();
      return new Response(JSON.stringify({
        verified: false,
        error: `Groq API Error: ${groqResponse.status} - ${errorText}`,
        confidence: 0,
      }), {
        status: groqResponse.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

  } catch (error) {
    return new Response(JSON.stringify({ 
      error: error.message,
      verified: false 
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

