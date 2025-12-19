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
            
                case 'compact':
                    html = '<div style="display: flex; flex-direction: column; align-items: center; text-align: center; font-family: sans-serif;">' +
                        '<div style="color: ' + accent + '; margin-bottom: 4px;">' +
                        '<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 22C6.477 22 2 17.523 2 12C2 6.477 6.477 2 12 2C17.523 2 22 6.477 22 12C22 17.523 17.523 22 12 22ZM12 4C7.582 4 4 7.582 4 12C4 16.418 7.582 20 12 20C16.418 20 20 16.418 20 12C20 7.582 16.418 4 12 4ZM12 6C13.657 6 15 7.343 15 9C15 10.657 13.657 12 12 12C10.343 12 9 10.657 9 9C9 7.343 10.343 6 12 6Z"/></svg>' +
                        '</div>' +
                        '<div style="font-size: 18px; font-weight: 800; color: #111827;">' + carbonSavedFormatted + ' kg</div>' +
                        '<div style="font-size: 10px; color: #6b7280; margin-top: 2px;">Carbon Saved</div>' +
                        '</div>';
                    break;
                case 'banner':
                    html = '<div style="background: #ffffff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 12px 16px; display: flex; align-items: center; justify-content: space-between; max-width: 400px; font-family: sans-serif;">' +
                        '<div style="display: flex; align-items: center;">' +
                        '<div style="width: 36px; height: 36px; background: ' + accent + '1A; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-right: 12px;">' +
                        '<svg width="20" height="20" viewBox="0 0 24 24" fill="' + accent + '"><path d="M12 2L2 22H22L12 2ZM12 6L18 18H6L12 6Z"/></svg>' +
                        '</div>' +
                        '<div>' +
                        '<div style="font-size: 14px; font-weight: 700; color: #1f2937;">Eco Impact</div>' +
                        '<div style="font-size: 12px; color: #6b7280;">' + carbonSavedFormatted + ' kg CO₂ saved</div>' +
                        '</div>' +
                        '</div>' +
                        // Assuming 65% progress mock or calc. Since we don't have a goal, we skip percentage or make up one based on a static goal (e.g. 1000kg)
                        // For now simply showing the value prominently if needed, or skipping percentage as per logic
                        '<div style="font-size: 18px; font-weight: 800; color: ' + accent + ';">' + carbonSavedFormatted + '</div>' + 
                        '</div>';
                    break;
                case 'minimal':
                    html = '<div style="display: inline-flex; align-items: center; font-family: monospace; font-size: 14px; color: #1f2937;">' +
                        '<svg width="16" height="16" viewBox="0 0 24 24" fill="' + accent + '" style="margin-right: 6px;"><path d="M12 22C6.477 22 2 17.523 2 12C2 6.477 6.477 2 12 2C17.523 2 22 6.477 22 12C22 17.523 17.523 22 12 22Z"/></svg>' +
                        '<span style="font-weight: 700;">' + carbonSavedFormatted + ' kg CO₂</span>' +
                        '</div>';
                    break;
                case 'badge':
                    html = '<div style="display: inline-flex; align-items: center; background: ' + accent + '; border-radius: 30px; padding: 8px 16px; font-family: sans-serif;">' +
                        '<svg width="16" height="16" style="margin-right: 8px;" viewBox="0 0 24 24" fill="white"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>' +
                        '<span style="color: white; font-weight: 700; font-size: 12px;">Sustainable Brand</span>' +
                        '</div>';
                    break;
                case 'progress':
                    html = '<div style="font-family: sans-serif; width: 100%; max-width: 300px;">' +
                       '<div style="display: flex; justify-content: space-between; margin-bottom: 8px;">' +
                       '<span style="font-weight: 700; font-size: 14px; color: #1f2937;">Eco Impact</span>' +
                       '<span style="font-weight: 700; font-size: 12px; color: ' + accent + ';">' + carbonSavedFormatted + ' kg</span>' +
                       '</div>' +
                       '<div style="width: 100%; height: 10px; background: #f3f4f6; border-radius: 5px; overflow: hidden;">' +
                       '<div style="width: 65%; height: 100%; background: ' + accent + '; border-radius: 5px;"></div>' +
                       '</div>' +
                       '</div>';
                    break;
                case 'ring':
                    html = '<div style="position: relative; width: 140px; height: 140px; display: flex; align-items: center; justify-content: center; font-family: sans-serif;">' +
                        '<svg width="140" height="140" viewBox="0 0 140 140" style="transform: rotate(-90deg);">' +
                        '<circle cx="70" cy="70" r="58" stroke="' + accent + '26" stroke-width="12" fill="none" />' +
                        '<circle cx="70" cy="70" r="58" stroke="' + accent + '" stroke-width="12" fill="none" stroke-dasharray="364" stroke-dashoffset="120" stroke-linecap="round" />' +
                        '</svg>' +
                        '<div style="position: absolute; text-align: center;">' +
                        '<div style="font-size: 24px; font-weight: 800; color: #111827;">' + Math.round(carbonSaved) + '</div>' +
                        '<div style="font-size: 10px; font-weight: 600; color: #6b7280; letter-spacing: 1px; margin-top: 2px;">KG SAVED</div>' +
                        '</div>' +
                        '</div>';
                    break;
                case 'card':
                default:
                    html = '<div style="background: #ffffff; border: 1px solid #e5e7eb; border-radius: 16px; padding: 20px; max-width: 320px; text-align: center; font-family: sans-serif;">' +
                        '<h3 style="font-size: 16px; font-weight: 600; color: #1f2937; margin: 0 0 4px 0;">' + data.name + '</h3>' +
                        '<p style="font-size: 12px; color: #6b7280; margin-bottom: 16px;">Sustainability Partner</p>' +
                        '<h2 style="font-size: 24px; font-weight: 800; color: ' + accent + '; margin: 0;">' + carbonSavedFormatted + ' kg</h2>' +
                        '<p style="font-size: 12px; color: #6b7280; margin-top: 4px;">CO₂ Saved by Community</p>' +
                        '<div style="margin-top: 12px; padding: 10px 14px; background: #f9fafb; border-radius: 10px;">' +
                        '<div style="font-size: 11px; color: #1f2937; font-weight: 600;">Equivalent to planting</div>' +
                        '<div style="font-size: 18px; font-weight: 800; color: ' + accent + '; margin: 4px 0;">' + treesEquivalent + ' trees</div>' +
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
