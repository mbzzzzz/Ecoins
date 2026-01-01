import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    const widgetJs = `
(function () {
    const scriptTag = document.currentScript;
    const apiKey = scriptTag.getAttribute('data-key') || new URL(scriptTag.src).searchParams.get('key');
    const variant = scriptTag.getAttribute('data-variant') || 'banner'; // Default to banner to match new UI
    const accent = scriptTag.getAttribute('data-accent') || '#11BB82';
    const font = scriptTag.getAttribute('data-font') || 'Inter';

    if (!apiKey) {
        console.error('Eco Rewards Widget: Missing API Key');
        return;
    }

    const container = document.getElementById('eco-rewards-widget');
    if (!container) {
        console.error('Eco Rewards Widget: Container #eco-rewards-widget not found');
        return;
    }

    // Load Font
    const fontMap = {
        'Inter': 'family=Inter:wght@400;600;700',
        'Outfit': 'family=Outfit:wght@400;600;700',
        'Roboto Mono': 'family=Roboto+Mono:wght@400;600;700',
        'Open Sans': 'family=Open+Sans:wght@400;600;700'
    };
    
    if (fontMap[font]) {
        if (!document.getElementById('eco-widget-font-' + font)) {
            const link = document.createElement('link');
            link.id = 'eco-widget-font-' + font;
            link.rel = 'stylesheet';
            link.href = 'https://fonts.googleapis.com/css2?' + fontMap[font] + '&display=swap';
            document.head.appendChild(link);
        }
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
            const carbonSavedFormatted = carbonSaved.toFixed(0); // No decimals for cleaner look
            const treesEquivalent = Math.round(carbonSaved / 20);
            
            // Dynamic goal from brand settings
            const goal = data.sustainability_goal || 2000;
            const progress = Math.min((carbonSaved / goal) * 100, 100).toFixed(0);

            let html = '';
            
            // Common styles
            const boxStyle = 'background: #ffffff; border: 1px solid #e5e7eb; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); border-radius: 12px; font-family: "' + font + '", sans-serif; overflow: hidden;';

            switch(variant) {
                case 'ring':
                    html = '<div style="position: relative; width: 140px; height: 140px; display: flex; align-items: center; justify-content: center; font-family: ' + font + ', sans-serif;">' +
                        '<svg width="140" height="140" viewBox="0 0 140 140" style="transform: rotate(-90deg);">' +
                        '<circle cx="70" cy="70" r="58" stroke="' + accent + '20" stroke-width="12" fill="none" />' +
                        '<circle cx="70" cy="70" r="58" stroke="' + accent + '" stroke-width="12" fill="none" stroke-dasharray="364" stroke-dashoffset="' + (364 - (364 * progress / 100)) + '" stroke-linecap="round" />' +
                        '</svg>' +
                        '<div style="position: absolute; text-align: center;">' +
                        '<div style="font-size: 24px; font-weight: 800; color: #111827;">' + carbonSavedFormatted + '</div>' +
                        '<div style="font-size: 10px; font-weight: 600; color: #6b7280; letter-spacing: 1px; margin-top: 2px;">kg CO₂</div>' +
                        '</div>' +
                        '</div>';
                    break;

                case 'illustrative-tree':
                     html = '<div style="' + boxStyle + ' padding: 20px; max-width: 320px;">' +
                        '<div style="display: flex; justify-content: space-between; align-items: flex-start;">' +
                        '<div>' +
                             '<div style="font-size: 10px; font-weight: 700; color: #9CA3AF; letter-spacing: 1.5px; margin-bottom: 4px;">TOTAL IMPACT</div>' +
                             '<div style="display: flex; align-items: baseline;">' +
                                 '<span style="font-size: 24px; font-weight: 800; color: #111827;">' + carbonSavedFormatted + '</span>' +
                                 '<span style="font-size: 12px; font-weight: 600; color: #6B7280; margin-left: 4px;">kg CO₂e</span>' +
                             '</div>' +
                        '</div>' +
                        '<div style="width: 48px; height: 48px; background: ' + accent + '15; border-radius: 50%; display: flex; align-items: center; justify-content: center;">' +
                           '<svg width="24" height="24" viewBox="0 0 24 24" fill="' + accent + '"><path d="M12 2L2 22H22L12 2ZM12 6L18 18H6L12 6Z"/></svg>' + // Mock tree icon
                        '</div>' +
                        '</div>' +
                        '<div style="margin-top: 16px; background: #F3F4F6; padding: 12px; border-radius: 8px; display: flex; align-items: center;">' +
                             '<div style="width: 20px; height: 20px; background: ' + accent + '20; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-right: 8px;">' +
                                 '<svg width="12" height="12" viewBox="0 0 24 24" fill="' + accent + '"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>' +
                             '</div>' +
                             '<div style="font-size: 11px; color: #1F2937;">Equivalent to <span style="font-weight: 700; color: ' + accent + ';">' + treesEquivalent + ' trees planted</span></div>' +
                        '</div>' +
                        '<div style="margin-top: 12px; height: 4px; background: #E5E7EB; border-radius: 2px; overflow: hidden;">' +
                             '<div style="width: ' + progress + '%; height: 100%; background: ' + accent + ';"></div>' +
                        '</div>' +
                        '</div>';
                    break;
                    
                case 'banner':
                default:
                    // Matches "Live Preview" in new UI: "Eco Impact", Icon+Value, Gradient bar
                     html = '<div style="' + boxStyle + ' padding: 16px; max-width: 320px;">' +
                        '<div style="display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 12px;">' +
                            '<span style="font-weight: 700; font-size: 14px; color: #1f2937;">Eco Impact</span>' +
                            '<div style="display: flex; align-items: center;">' + // Icon + Value
                                '<svg width="14" height="14" viewBox="0 0 24 24" fill="' + accent + '" style="margin-right: 4px;"><path d="M12 22C6.477 22 2 17.523 2 12C2 6.477 6.477 2 12 2C17.523 2 22 6.477 22 12C22 17.523 17.523 22 12 22Z"/></svg>' +
                                '<span style="font-weight: 700; font-size: 12px; color: ' + accent + '; font-family: monospace;">' + carbonSavedFormatted + ' kg</span>' +
                            '</div>' +
                        '</div>' +
                        '<div style="height: 12px; width: 100%; background: #F3F4F6; border-radius: 6px; overflow: hidden;position: relative;">' +
                            '<div style="width: ' + progress + '%; height: 100%; background: ' + accent + '; border-radius: 6px; position:relative;">'+
                                '<div style="position: absolute; top:0; left:0; right:0; bottom:0; background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2));"></div>' +
                            '</div>' +
                        '</div>' +
                        '<div style="display: flex; justify-content: space-between; margin-top: 8px;">' +
                            '<span style="font-size: 10px; color: #9CA3AF;">Progress to goal</span>' +
                            '<span style="font-size: 10px; color: #9CA3AF;">' + progress + '%</span>' +
                        '</div>' +
                        '</div>';
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
