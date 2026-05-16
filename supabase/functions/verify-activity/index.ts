// @ts-nocheck — Deno Edge Function, type-checked by the Deno runtime not tsc
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Category-specific evidence guide keeps the model grounded in what each activity looks like.
const CATEGORY_GUIDE: Record<string, string> = {
  transport: 'cycling, walking, public bus/train/tram in action, transit ticket/pass, boarding pass, bike-share app screen, interior of a bus or train',
  food: 'plant-based or vegan meal on a plate, vegan menu section, restaurant receipt with vegan/vegetarian items, product label saying "vegan" or "plant-based", farmers market fresh produce',
  recycle: 'recycling bins being used, sorted recyclable materials (glass/paper/plastic/metal), deposit-return receipt, e-waste drop-off center, recycling symbol on items being sorted',
  energy: 'solar panels, LED bulb being installed, laundry drying on a clothesline, smart meter display, energy-saving device label, multiple devices unplugged',
  shopping: 'eco-certification label (B-Corp, FSC, Organic, Fair Trade), second-hand / thrift store receipt or interior, reusable bag in use, zero-waste product, sustainable brand packaging',
};

function buildPrompt(category: string, deviceInfo: unknown, location: unknown, imageTimestamp: string | null): string {
  const guide = CATEGORY_GUIDE[category] ?? 'eco-friendly action relevant to sustainability';
  return `You are an Eco-Activity Verification AI for an eco-rewards platform. Your role is to detect genuine sustainable actions and reject fraud.

CLAIMED ACTIVITY CATEGORY: "${category}"
EVIDENCE TO LOOK FOR: ${guide}

VERIFICATION STEPS:
1. Visual Match — Does the image clearly show the claimed activity or direct proof of it?
2. OCR / Text Reading — If a ticket, receipt, menu, label, or screen is visible, READ THE TEXT carefully. Extract dates, times, keywords (e.g. "Bus", "Vegan", "Recycle", "Organic", "Pre-loved").
3. Authenticity — Reject: photos of a phone/screen showing a photo, blurry/unrecognisable images, obvious stock photos, or irrelevant scenes.
4. Time Coherence — Does ambient light (daylight/night/indoor lighting) match the timestamp?
5. Location Coherence — Does the scene setting (urban street, restaurant, store, outdoor) match the GPS coordinates?

CROSS-VERIFICATION METADATA:
Device: ${JSON.stringify(deviceInfo)}
GPS Location: ${JSON.stringify(location)}
Image Timestamp: ${imageTimestamp ?? 'N/A'}

SCORING RULES:
- verified = true ONLY when confidence > 0.85 AND you see clear, authentic evidence
- If readable text confirms the activity, increase confidence significantly
- Ambiguous but plausible images → verified = false, confidence 0.40–0.65
- Carbon estimate: be conservative and category-realistic (transport: 0.2 kg/km avg, food: 0.8 kg/meal, recycle: 0.1 kg/item, energy: 0.5 kg/action, shopping: 2.0 kg/item)

Return ONLY valid JSON — no markdown, no explanation outside the JSON object:
{
  "verified": boolean,
  "confidence": number,
  "carbon_saved_estimate": number,
  "reasoning": string,
  "fraud_score": number,
  "ocr_text_found": string
}`;
}

async function verifyWithClaude(
  imageBase64: string,
  prompt: string,
  apiKey: string,
): Promise<unknown> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 512,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image',
              source: { type: 'base64', media_type: 'image/jpeg', data: imageBase64 },
            },
            { type: 'text', text: prompt },
          ],
        },
      ],
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Anthropic ${res.status}: ${err}`);
  }

  const data = await res.json();
  const raw = data.content[0].text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
  return JSON.parse(raw);
}

async function verifyWithGroq(
  imageBase64: string,
  prompt: string,
  apiKey: string,
): Promise<unknown> {
  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'llama-3.2-11b-vision-preview',
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: prompt },
            { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${imageBase64}` } },
          ],
        },
      ],
      temperature: 0.1,
      max_tokens: 400,
      response_format: { type: 'json_object' },
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Groq ${res.status}: ${err}`);
  }

  const data = await res.json();
  return JSON.parse(data.choices[0].message.content);
}

async function verifyWithGemini(
  imageBase64: string,
  prompt: string,
  apiKey: string,
): Promise<unknown> {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [
            { text: prompt },
            { inline_data: { mime_type: 'image/jpeg', data: imageBase64 } },
          ],
        }],
        generationConfig: { response_mime_type: 'application/json' },
      }),
    },
  );

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Gemini ${res.status}: ${err}`);
  }

  const data = await res.json();
  return JSON.parse(data.candidates[0].content.parts[0].text);
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { imageBase64, category, deviceInfo, location, imageTimestamp } = await req.json();

    if (!imageBase64 || !category) {
      return new Response(JSON.stringify({ error: 'Missing imageBase64 or category' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY');
    const groqKey = Deno.env.get('GROQ_API_KEY');
    const geminiKey = Deno.env.get('GEMINI_API_KEY');

    const prompt = buildPrompt(category, deviceInfo, location, imageTimestamp);

    // Provider waterfall: Claude Haiku → Groq → Gemini
    const providers: Array<{ name: string; fn: () => Promise<unknown> }> = [];

    if (anthropicKey) {
      providers.push({ name: 'Claude Haiku', fn: () => verifyWithClaude(imageBase64, prompt, anthropicKey) });
    }
    if (groqKey) {
      providers.push({ name: 'Groq', fn: () => verifyWithGroq(imageBase64, prompt, groqKey) });
    }
    if (geminiKey) {
      providers.push({ name: 'Gemini', fn: () => verifyWithGemini(imageBase64, prompt, geminiKey) });
    }

    if (providers.length === 0) {
      return new Response(
        JSON.stringify({
          verified: false,
          error: 'No AI provider configured. Set ANTHROPIC_API_KEY, GROQ_API_KEY, or GEMINI_API_KEY.',
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    let result: Record<string, unknown> | null = null;
    let usedProvider = '';
    let lastError = '';

    for (const provider of providers) {
      try {
        result = (await provider.fn()) as Record<string, unknown>;
        usedProvider = provider.name;
        break;
      } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : String(e);
        console.error(`${provider.name} failed: ${msg}`);
        lastError = msg;
      }
    }

    if (!result) {
      return new Response(
        JSON.stringify({ verified: false, error: `All providers failed. Last error: ${lastError}` }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    result.verification_timestamp = new Date().toISOString();
    result.provider = usedProvider;

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg, verified: false }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
