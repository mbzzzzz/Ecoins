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

    const targetId = scriptTag.getAttribute('data-target');
    let container;

    if (targetId) {
        container = document.getElementById(targetId);
        if (!container) {
            console.error('Eco Rewards Widget: Container #' + targetId + ' not found');
            return;
        }
    } else {
        // Auto-Generate Container
        container = document.createElement('div');
        // Insert after the script tag
        scriptTag.parentNode.insertBefore(container, scriptTag.nextSibling);
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
    fetch('https://eenpgfvmynemualvozhd.supabase.co/functions/v1/brand-api?key=' + apiKey)
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
                    html = '<div style="' + boxStyle + ' padding: 24px; display: flex; flex-direction: column; align-items: center; justify-content: center; max-width: 200px;">' +
                        '<div style="position: relative; width: 120px; height: 120px; display: flex; align-items: center; justify-content: center;">' +
                        '<svg width="120" height="120" viewBox="0 0 120 120" style="transform: rotate(-90deg);">' +
                        '<circle cx="60" cy="60" r="52" stroke="' + accent + '20" stroke-width="10" fill="none" />' +
                        '<circle cx="60" cy="60" r="52" stroke="' + accent + '" stroke-width="10" fill="none" stroke-dasharray="327" stroke-dashoffset="' + (327 - (327 * progress / 100)) + '" stroke-linecap="round" />' +
                        '</svg>' +
                        '<div style="position: absolute; text-align: center;">' +
                        '<div style="font-size: 20px; font-weight: 800; color: #111827;">' + carbonSavedFormatted + '</div>' +
                        '<div style="font-size: 9px; font-weight: 700; color: #9CA3AF; margin-top: 0px;">kg CO₂</div>' +
                        '</div>' +
                        '</div>' +
                        '<div style="margin-top: 12px; font-size: 11px; font-weight: 600; color: #374151;">Sustainability Goal</div>' +
                        '</div>';
                    break;

                case 'minimal':
                    html = '<div style="' + boxStyle + ' padding: 8px 12px; display: inline-flex; align-items: center; border-radius: 50px; max-width: fit-content;">' +
                        '<div style="width: 24px; height: 24px; background: ' + accent + '20; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-right: 8px;">' +
                         '<svg width="14" height="14" viewBox="0 0 24 24" fill="' + accent + '"><path d="M12 2L2 22H22L12 2ZM12 6L18 18H6L12 6Z"/></svg>' +
                        '</div>' +
                        '<div style="display: flex; flex-direction: column; line-height: 1.1;">' +
                            '<span style="font-size: 9px; font-weight: 700; color: #9CA3AF; letter-spacing: 0.5px;">OFFSET</span>' +
                            '<span style="font-size: 13px; font-weight: 800; color: #111827;">' + carbonSavedFormatted + ' kg CO₂</span>' +
                        '</div>' +
                        '</div>';
                    break;

                case 'card':
                     html = '<div style="' + boxStyle + ' padding: 0; max-width: 300px; overflow: hidden;">' +
                        '<div style="background: ' + accent + '10; padding: 20px; display: flex; align-items: center; justify-content: space-between;">' +
                             '<div>' +
                                 '<div style="font-size: 11px; font-weight: 700; color: ' + accent + '; letter-spacing: 1px; margin-bottom: 4px;">CERTIFIED IMPACT</div>' +
                                 '<div style="font-size: 28px; font-weight: 800; color: #111827; line-height: 1;">' + carbonSavedFormatted + '<span style="font-size: 14px; font-weight: 600; color: #6B7280; margin-left: 2px;">kg</span></div>' +
                             '</div>' +
                             '<div style="width: 40px; height: 40px; background: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">' +
                                 '<svg width="20" height="20" viewBox="0 0 24 24" fill="' + accent + '"><path d="M16.5 3C19.538 3 22 5.5 22 9C22 16 14.5 20 12 21.5C9.5 20 2 16 2 9C2 5.5 4.5 3 7.5 3C9.24 3 10.91 3.81 12 5.08C13.09 3.81 14.76 3 16.5 3Z"/></svg>' +
                             '</div>' +
                        '</div>' +
                        '<div style="padding: 16px;">' +
                            '<div style="display: flex; justify-content: space-between; margin-bottom: 6px;">' +
                                '<span style="font-size: 11px; font-weight: 600; color: #4B5563;">Goal Progress</span>' +
                                '<span style="font-size: 11px; font-weight: 700; color: ' + accent + ';">' + progress + '%</span>' +
                            '</div>' +
                            '<div style="height: 6px; width: 100%; background: #F3F4F6; border-radius: 3px; overflow: hidden;">' +
                                '<div style="width: ' + progress + '%; height: 100%; background: ' + accent + '; border-radius: 3px;"></div>' +
                            '</div>' +
                            '<div style="margin-top: 16px; padding-top: 12px; border-top: 1px solid #F3F4F6; font-size: 10px; color: #9CA3AF; text-align: center;">' +
                                'Verified by Eco Rewards' +
                            '</div>' +
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
