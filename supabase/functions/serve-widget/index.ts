import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Read the actual widget.js file content
  // For now, return a simple widget that loads from the public folder
  // In production, serve the actual widget.js file from storage or CDN
  
  const widgetJs = `
(function () {
    const scriptTag = document.currentScript;
    const apiKey = scriptTag.getAttribute('data-key') || new URL(scriptTag.src).searchParams.get('key');
    const variant = scriptTag.getAttribute('data-variant') || 'card';

    if (!apiKey) {
        console.error('Eco Rewards Widget: Missing API Key');
        return;
    }

    const container = document.getElementById('eco-rewards-widget');
    if (!container) {
        console.error('Eco Rewards Widget: Container #eco-rewards-widget not found');
        return;
    }

    // Fetch Data from brand-api
    fetch('https://gwmcmlpuqummaumjloci.supabase.co/functions/v1/brand-api?key=' + apiKey)
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (data.error) {
                container.innerHTML = '<div style="color:red; font-size:12px;">Error: ' + data.error + '</div>';
                return;
            }

            const carbonSaved = parseFloat(data.total_carbon_saved || 0);
            const carbonSavedFormatted = carbonSaved.toFixed(1);
            const treesEquivalent = Math.round(carbonSaved / 20);
            
            let html = '';
            switch(variant) {
                case 'card':
                default:
                    html = '<div style="background: #ffffff; border: 1px solid #e5e7eb; border-radius: 16px; padding: 20px; max-width: 320px; text-align: center;">' +
                        '<h3 style="font-size: 16px; font-weight: 600; color: #1f2937; margin: 0 0 4px 0;">' + data.name + '</h3>' +
                        '<p style="font-size: 12px; color: #6b7280; margin-bottom: 16px;">Sustainability Partner</p>' +
                        '<h2 style="font-size: 24px; font-weight: 800; color: #10B981; margin: 0;">' + carbonSavedFormatted + ' kg</h2>' +
                        '<p style="font-size: 12px; color: #6b7280; margin-top: 4px;">CO₂ Saved by Community</p>' +
                        '<div style="margin-top: 12px; padding: 10px 14px; background: #f0fdf4; border-radius: 10px;">' +
                        '<div style="font-size: 11px; color: #15803d; font-weight: 600;">Equivalent to planting</div>' +
                        '<div style="font-size: 18px; font-weight: 800; color: #10B981; margin: 4px 0;">' + treesEquivalent + ' trees</div>' +
                        '</div></div>';
                    break;
            }
            
            container.innerHTML = html;
        })
        .catch(function(err) {
            console.error(err);
            container.innerHTML = '<div style="color:red; font-size:12px;">Failed to load widget</div>';
        });
})();
`;

  return new Response(widgetJs, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/javascript',
      'Cache-Control': 'public, max-age=3600',
    },
  });
});
