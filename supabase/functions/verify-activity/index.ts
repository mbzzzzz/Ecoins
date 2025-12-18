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

    // 1. Try GROQ first (Fastest/Cheapest)
    const groqApiKey = Deno.env.get('GROQ_API_KEY');
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY');

    let aiResponse;
    let provider = '';
    let result;

    if (groqApiKey) {
      provider = 'Groq';
      aiResponse = await fetch('https://api.groq.com/openai/v1/chat/completions', {
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
                  text: `Act as a strict Eco-Verification AI. Your goal is to prevent fraud while regarding genuine effort.
                  
                  Analyze if this image is CREDIBLE PROOF for the activity: "${category}".

                  CRITERIA:
                  1. Visual Evidence: Does the image show the action (e.g. riding a bike, recycling) or proof (ticket, receipt)?
                  2. Authenticity: Reject photos of screens, blurry blobs, or obvious stock photos.
                  3. Cross-Verification (Crucial): 
                     - Does the lighting (Day/Night) match the timestamp?
                     - Does the scenery (City/Rural/Indoor) match the location coordinates?

                  METADATA:
                  - Device: ${JSON.stringify(deviceInfo)}
                  - Location: ${JSON.stringify(location)}
                  - Timestamp: ${imageTimestamp || 'N/A'}

                  Output JSON only (no markdown):
                  {
                    "verified": boolean, // true ONLY if you are >85% confident
                    "confidence": number, // 0.0 to 1.0
                    "carbon_saved_estimate": number, // conservative estimate in kg
                    "reasoning": string, // Explain any inconsistencies found (e.g. "Photo is daylight but timestamp is 11PM")
                    "fraud_score": number // 0-1
                  }`
                },
                {
                  type: 'image_url',
                  image_url: { url: `data:image/jpeg;base64,${imageBase64}` }
                }
              ]
            }
          ],
          temperature: 0.1,
          max_tokens: 400,
          response_format: { type: 'json_object' }
        }),
      });

      if (aiResponse.ok) {
        const data = await aiResponse.json();
        const content = data.choices[0].message.content;
        result = JSON.parse(content);
      }

    } else if (geminiApiKey) {
      // 2. Fallback to Gemini 1.5 Flash (Google)
      provider = 'Gemini';
      aiResponse = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{
            parts: [
              {
                text: `Act as a strict Eco-Verification AI. Your goal is to prevent fraud while regarding genuine effort.
                  
                  Analyze if this image is CREDIBLE PROOF for the activity: "${category}".

                  CRITERIA:
                  1. Visual Evidence: Does the image show the action or proof?
                  2. Authenticity: Reject photos of screens, blurry blobs, or stock photos.
                  3. Cross-Verification (Crucial): 
                     - Does the lighting (Day/Night) match the timestamp?
                     - Does the scenery match the location?

                  METADATA:
                  - Device: ${JSON.stringify(deviceInfo)}
                  - Location: ${JSON.stringify(location)}
                  - Timestamp: ${imageTimestamp || 'N/A'}

                  Output JSON only (no markdown):
                  {
                    "verified": boolean,
                    "confidence": number,
                    "carbon_saved_estimate": number,
                    "reasoning": string,
                    "fraud_score": number
                  }` },
              { inline_data: { mime_type: "image/jpeg", data: imageBase64 } }
            ]
          }],
          generationConfig: {
            response_mime_type: "application/json"
          }
        }),
      });

      if (aiResponse.ok) {
        const data = await aiResponse.json();
        // Parse Gemini specific response structure
        const content = data.candidates[0].content.parts[0].text;
        result = JSON.parse(content);
      }
    } else {
      return new Response(JSON.stringify({
        error: 'Server AI Configuration Missing. Please set GROQ_API_KEY or GEMINI_API_KEY secrets.',
        verified: false
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (result) {
      // Add metadata to result
      result.device_info = deviceInfo;
      result.location = location;
      result.image_timestamp = imageTimestamp;
      result.verification_timestamp = new Date().toISOString();
      result.provider = provider;

      return new Response(JSON.stringify(result), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } else {
      const errorText = await aiResponse.text();
      return new Response(JSON.stringify({
        verified: false,
        error: `${provider} API Error: ${aiResponse.status} - ${errorText}`,
        confidence: 0,
      }), {
        status: aiResponse.status,
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

