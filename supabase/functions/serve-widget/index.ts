// @ts-nocheck
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const BRAND_API = 'https://eenpgfvmynemualvozhd.supabase.co/functions/v1/brand-api';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const js = `(function () {
  // --- Locate the script element robustly ---
  // document.currentScript is null in CodePen / JSFiddle / async contexts.
  var script = document.currentScript ||
    (function () {
      var all = document.querySelectorAll('script[data-key]');
      return all[all.length - 1] || null;
    })();

  if (!script) {
    console.warn('[Ecoins Widget] Could not locate script tag. Add data-key attribute.');
    return;
  }

  var key      = script.getAttribute('data-key') || '';
  var variant  = script.getAttribute('data-variant')  || 'banner';
  var accent   = script.getAttribute('data-accent')   || '#11BB82';
  var font     = script.getAttribute('data-font')     || 'Inter';
  var showPct  = script.getAttribute('data-show-percentage') !== 'false';
  var showVals = script.getAttribute('data-show-values')     !== 'false';

  if (!key || key === 'YOUR_API_KEY') {
    console.warn('[Ecoins Widget] No valid data-key provided.');
    return;
  }

  // --- Load Google Font once ---
  var fontId = 'ecoins-font-' + font.replace(/\\s+/g, '-');
  if (!document.getElementById(fontId)) {
    var lnk = document.createElement('link');
    lnk.id   = fontId;
    lnk.rel  = 'stylesheet';
    lnk.href = 'https://fonts.googleapis.com/css2?family=' +
      encodeURIComponent(font) + ':wght@400;600;700;800;900&display=swap';
    document.head.appendChild(lnk);
  }

  // --- Create container and insert after script tag ---
  var container = document.createElement('div');
  container.setAttribute('style', 'display:inline-block;box-sizing:border-box;font-family:' + font + ',Inter,sans-serif;');

  if (script.parentNode) {
    script.parentNode.insertBefore(container, script.nextSibling);
  } else {
    document.body.appendChild(container);
  }

  container.innerHTML = '<div style="padding:12px 16px;color:' + accent + ';font-size:13px;font-family:inherit;opacity:0.7;">Loading...</div>';

  // --- Fetch brand data ---
  fetch('${BRAND_API}?key=' + encodeURIComponent(key))
    .then(function (r) { return r.json(); })
    .then(function (data) {
      if (data.error) {
        container.innerHTML = '<div style="padding:8px;color:#ef4444;font-size:12px;font-family:' + font + ',sans-serif;">Invalid API key</div>';
        return;
      }

      var carbon   = Math.round(data.total_carbon_saved || 0);
      var goal     = data.sustainability_goal || 2000;
      var progress = Math.min(carbon / goal, 1);
      var pct      = Math.round(progress * 100);
      var trees    = data.trees_equivalent || Math.floor(carbon / 20);
      var users    = data.active_users || 0;

      container.innerHTML = render(variant, carbon, goal, progress, pct, trees, users);
    })
    .catch(function (e) {
      console.error('[Ecoins Widget]', e);
      container.innerHTML = '<div style="padding:8px;color:#ef4444;font-size:12px;font-family:' + font + ',sans-serif;">Could not load data. Check API key and CORS.</div>';
    });

  // --- Helpers ---
  function bar(prog, h, r) {
    h = h || '8px'; r = r || '4px';
    return '<div style="background:#e5e7eb;border-radius:' + r + ';height:' + h + ';width:100%;overflow:hidden;">' +
      '<div style="background:' + accent + ';border-radius:' + r + ';height:' + h + ';width:' + Math.round(prog * 100) + '%;transition:width .8s ease;"></div></div>';
  }

  function statCell(val, label) {
    return '<div style="background:' + accent + '18;border-radius:8px;padding:10px 8px;text-align:center;">' +
      '<div style="font-size:18px;font-weight:800;color:#111;">' + val + '</div>' +
      '<div style="font-size:9px;color:#9ca3af;margin-top:2px;">' + label + '</div></div>';
  }

  function wrap(inner, maxW) {
    return '<div style="background:#fff;border:1px solid #e5e7eb;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,.06);padding:20px;max-width:' + (maxW || '320px') + ';box-sizing:border-box;font-family:' + font + ',Inter,sans-serif;">' + inner + '</div>';
  }

  function render(v, carbon, goal, progress, pct, trees, users) {

    if (v === 'minimal') {
      return '<div style="display:inline-flex;align-items:center;gap:8px;padding:8px 14px;background:#fff;border-radius:50px;border:1px solid #e5e7eb;box-shadow:0 1px 4px rgba(0,0,0,.06);font-family:' + font + ',sans-serif;">' +
        '<span style="font-size:16px;">🌿</span>' +
        '<span style="font-size:13px;font-weight:700;color:' + accent + ';">' + carbon + ' kg CO₂ saved</span>' +
        '</div>';
    }

    if (v === 'badge') {
      return '<div style="display:inline-flex;align-items:center;gap:10px;padding:10px 14px;background:#fff;border-radius:8px;border:1px solid #e5e7eb;box-shadow:0 2px 8px rgba(0,0,0,.06);font-family:' + font + ',sans-serif;">' +
        '<div style="background:' + accent + ';border-radius:6px;padding:6px;line-height:1;font-size:14px;color:#fff;font-weight:700;">✓</div>' +
        '<div>' +
          '<div style="font-size:11px;font-weight:700;color:#111;">Sustainability Partner</div>' +
          '<div style="font-size:10px;color:#6b7280;">' + carbon + ' kg CO₂ offset via Eco Rewards</div>' +
        '</div>' +
        '<span style="font-size:10px;color:' + accent + ';">★★★★★</span>' +
        '</div>';
    }

    if (v === 'counter') {
      return '<div style="display:inline-block;text-align:center;padding:24px;background:#fff;border-radius:16px;border:1.5px solid ' + accent + '44;box-shadow:0 4px 16px rgba(0,0,0,.06);font-family:' + font + ',sans-serif;">' +
        '<div style="font-size:40px;margin-bottom:4px;">🌱</div>' +
        '<div style="font-size:52px;font-weight:900;color:' + accent + ';line-height:1;">' + carbon + '</div>' +
        '<div style="font-size:13px;font-weight:600;color:#6b7280;letter-spacing:.08em;margin-top:4px;">kg CO₂ Saved</div>' +
        '<div style="margin-top:10px;padding:3px 12px;background:' + accent + '18;border-radius:20px;font-size:10px;color:' + accent + ';font-weight:600;display:inline-block;">🌱 Eco Rewards Verified</div>' +
        '</div>';
    }

    if (v === 'ring') {
      var r = 44, circ = +(2 * Math.PI * r).toFixed(1);
      var dash = +(circ * (1 - progress)).toFixed(1);
      return '<div style="display:inline-block;text-align:center;font-family:' + font + ',sans-serif;">' +
        '<svg width="120" height="120" viewBox="0 0 120 120">' +
          '<circle cx="60" cy="60" r="' + r + '" fill="none" stroke="#e5e7eb" stroke-width="10"/>' +
          '<circle cx="60" cy="60" r="' + r + '" fill="none" stroke="' + accent + '" stroke-width="10" stroke-linecap="round"' +
            ' stroke-dasharray="' + circ + '" stroke-dashoffset="' + dash + '" transform="rotate(-90 60 60)"/>' +
          '<text x="60" y="57" text-anchor="middle" font-size="18" font-weight="800" fill="#111" font-family="' + font + ',sans-serif">' + carbon + '</text>' +
          '<text x="60" y="71" text-anchor="middle" font-size="9" fill="#9ca3af" font-family="' + font + ',sans-serif">kg CO₂</text>' +
        '</svg>' +
        '<div style="font-size:11px;font-weight:600;color:#374151;margin-top:4px;">Sustainability Goal</div>' +
        '</div>';
    }

    if (v === 'card') {
      return wrap(
        '<div style="background:' + accent + '18;border-radius:8px;padding:20px;margin:-20px -20px 16px;display:flex;justify-content:space-between;align-items:flex-start;">' +
          '<div>' +
            '<div style="font-size:10px;font-weight:700;color:' + accent + ';letter-spacing:.1em;">CERTIFIED IMPACT</div>' +
            '<div style="font-size:32px;font-weight:900;color:#111;margin-top:4px;">' + carbon + '<span style="font-size:16px;color:#6b7280;font-weight:600;"> kg</span></div>' +
          '</div>' +
          '<div style="background:#fff;border-radius:50%;padding:8px;box-shadow:0 2px 4px rgba(0,0,0,.1);">✅</div>' +
        '</div>' +
        '<div style="display:flex;justify-content:space-between;margin-bottom:6px;">' +
          '<span style="font-size:11px;color:#374151;font-weight:600;">Goal Progress</span>' +
          (showPct ? '<span style="font-size:11px;font-weight:700;color:' + accent + ';">' + pct + '%</span>' : '') +
        '</div>' +
        bar(progress, '6px', '3px') +
        '<div style="margin-top:14px;font-size:10px;color:#9ca3af;text-align:center;">Verified by Eco Rewards</div>',
        '280px'
      );
    }

    if (v === 'illustrative-tree') {
      return wrap(
        '<div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:12px;">' +
          '<div>' +
            '<div style="font-size:10px;font-weight:700;color:#9ca3af;letter-spacing:.1em;">TOTAL IMPACT</div>' +
            '<div style="font-size:28px;font-weight:900;color:#111;margin-top:4px;">' + carbon + ' <span style="font-size:13px;color:#6b7280;">kg CO₂e</span></div>' +
          '</div>' +
          '<span style="font-size:32px;">🌳</span>' +
        '</div>' +
        '<div style="background:#f0fdf4;border-radius:8px;padding:10px 12px;font-size:12px;color:#374151;margin-bottom:12px;">' +
          '✅ Equivalent to <strong style="color:' + accent + ';">' + trees + ' trees planted</strong>' +
        '</div>' +
        bar(progress, '4px', '2px'),
        '280px'
      );
    }

    if (v === 'stats') {
      return wrap(
        '<div style="font-size:10px;font-weight:700;color:' + accent + ';letter-spacing:.1em;margin-bottom:12px;">📊 IMPACT DASHBOARD</div>' +
        '<div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-bottom:12px;">' +
          statCell(carbon, 'kg CO₂') + statCell(users, 'Users') + statCell(trees, 'Trees 🌳') +
        '</div>' +
        bar(progress, '5px', '3px') +
        '<div style="display:flex;justify-content:space-between;margin-top:6px;">' +
          '<span style="font-size:9px;color:#9ca3af;">Goal: ' + goal + 'kg</span>' +
          '<span style="font-size:9px;font-weight:700;color:' + accent + ';">' + pct + '% reached</span>' +
        '</div>',
        '300px'
      );
    }

    if (v === 'gradient') {
      return '<div style="background:linear-gradient(135deg,' + accent + ',' + accent + 'bb);border-radius:12px;padding:20px;max-width:280px;box-sizing:border-box;box-shadow:0 8px 24px ' + accent + '55;font-family:' + font + ',Inter,sans-serif;">' +
        '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">' +
          '<span style="font-size:9px;font-weight:700;color:rgba(255,255,255,.7);letter-spacing:1.5px;">ECO IMPACT</span>' +
          '<span style="padding:2px 8px;background:rgba(255,255,255,.2);border-radius:20px;font-size:9px;color:#fff;font-weight:600;">Verified ✓</span>' +
        '</div>' +
        '<div style="font-size:44px;font-weight:900;color:#fff;line-height:1;">' + carbon + '</div>' +
        '<div style="font-size:12px;color:rgba(255,255,255,.75);font-weight:500;margin:4px 0 16px;">kg CO₂ saved through Eco Rewards</div>' +
        '<div style="background:rgba(255,255,255,.25);border-radius:4px;height:6px;overflow:hidden;">' +
          '<div style="background:#fff;border-radius:4px;height:6px;width:' + Math.round(progress * 100) + '%;transition:width .8s ease;"></div>' +
        '</div>' +
        '<div style="display:flex;justify-content:space-between;margin-top:6px;">' +
          '<span style="font-size:9px;color:rgba(255,255,255,.6);">Progress to goal</span>' +
          '<span style="font-size:9px;color:#fff;font-weight:600;">' + pct + '%</span>' +
        '</div>' +
        '</div>';
    }

    if (v === 'neon') {
      return '<div style="background:#0a0a0a;border-radius:12px;padding:20px;max-width:280px;box-sizing:border-box;border:1px solid ' + accent + '44;box-shadow:0 0 28px ' + accent + '22;font-family:' + font + ',Inter,sans-serif;">' +
        '<div style="font-size:9px;font-weight:700;color:' + accent + ';opacity:.6;letter-spacing:2px;margin-bottom:8px;">CARBON OFFSET</div>' +
        '<div style="font-size:52px;font-weight:900;color:' + accent + ';line-height:1;text-shadow:0 0 12px ' + accent + ',0 0 28px ' + accent + '88;">' + carbon + '</div>' +
        '<div style="font-size:12px;color:rgba(255,255,255,.4);font-weight:500;margin:4px 0 16px;">kg CO₂ saved</div>' +
        '<div style="background:rgba(255,255,255,.06);border-radius:2px;height:3px;overflow:hidden;">' +
          '<div style="background:' + accent + ';border-radius:2px;height:3px;width:' + Math.round(progress * 100) + '%;box-shadow:0 0 10px ' + accent + ',0 0 20px ' + accent + '88;transition:width .8s ease;"></div>' +
        '</div>' +
        '<div style="display:flex;justify-content:space-between;margin-top:8px;">' +
          '<span style="font-size:9px;color:rgba(255,255,255,.25);">' + pct + '% of goal</span>' +
          '<span style="font-size:8px;font-weight:700;color:' + accent + ';opacity:.6;letter-spacing:1px;">ECO REWARDS</span>' +
        '</div>' +
        '</div>';
    }

    if (v === 'split') {
      return '<div style="display:inline-flex;max-width:320px;border-radius:12px;overflow:hidden;border:1px solid ' + accent + '26;box-shadow:0 4px 12px rgba(0,0,0,.06);font-family:' + font + ',Inter,sans-serif;">' +
        '<div style="background:' + accent + '18;padding:20px 16px;display:flex;flex-direction:column;justify-content:center;min-width:110px;">' +
          '<div style="font-size:9px;font-weight:700;color:' + accent + ';opacity:.8;letter-spacing:1.5px;margin-bottom:4px;">CO₂ SAVED</div>' +
          '<div style="font-size:36px;font-weight:900;color:#111;line-height:1;">' + carbon + '</div>' +
          '<div style="font-size:13px;color:#6b7280;font-weight:500;">kg</div>' +
        '</div>' +
        '<div style="background:#fff;padding:16px;display:flex;flex-direction:column;justify-content:center;flex:1;">' +
          '<div style="font-size:10px;color:#9ca3af;margin-bottom:6px;">Goal progress</div>' +
          '<div style="background:#e5e7eb;border-radius:3px;height:5px;margin-bottom:4px;overflow:hidden;">' +
            '<div style="background:' + accent + ';border-radius:3px;height:5px;width:' + Math.round(progress * 100) + '%;transition:width .8s ease;"></div>' +
          '</div>' +
          '<div style="font-size:18px;font-weight:800;color:' + accent + ';margin-bottom:10px;">' + pct + '%</div>' +
          '<div style="font-size:11px;font-weight:600;color:#374151;">🌳 ' + trees + ' trees</div>' +
        '</div>' +
        '</div>';
    }

    if (v === 'ticker') {
      return '<div style="background:#fff;border-radius:12px;padding:20px 16px;max-width:280px;box-sizing:border-box;border:1px solid #f3f4f6;box-shadow:0 2px 8px rgba(0,0,0,.05);font-family:' + font + ',Inter,sans-serif;text-align:center;">' +
        '<div style="font-size:9px;font-weight:700;color:#9ca3af;letter-spacing:2.5px;margin-bottom:8px;">LIVE IMPACT</div>' +
        '<div style="font-size:56px;font-weight:900;color:#111;line-height:1;">' + carbon + '</div>' +
        '<div style="font-size:10px;font-weight:700;color:' + accent + ';letter-spacing:1px;margin:4px 0 12px;">kg CO₂ OFFSET</div>' +
        '<div style="height:2px;background:linear-gradient(90deg,transparent,' + accent + ',transparent);border-radius:1px;margin-bottom:12px;"></div>' +
        '<div style="display:flex;justify-content:space-around;align-items:center;">' +
          '<div><div style="font-size:15px;font-weight:800;color:#111;">' + trees + '</div><div style="font-size:9px;color:#9ca3af;">trees</div></div>' +
          '<div style="width:1px;height:24px;background:#e5e7eb;"></div>' +
          '<div><div style="font-size:15px;font-weight:800;color:' + accent + ';">' + pct + '%</div><div style="font-size:9px;color:#9ca3af;">of goal</div></div>' +
          '<div style="width:1px;height:24px;background:#e5e7eb;"></div>' +
          '<div><div style="font-size:15px;font-weight:800;color:#111;">' + users + '</div><div style="font-size:9px;color:#9ca3af;">users</div></div>' +
        '</div>' +
        '</div>';
    }

    // banner (default)
    return wrap(
      '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">' +
        '<span style="font-size:14px;font-weight:700;color:#111;">Eco Impact</span>' +
        (showVals ? '<span style="font-size:12px;font-weight:700;color:' + accent + ';">🌿 ' + carbon + ' kg</span>' : '') +
      '</div>' +
      bar(progress, '10px', '5px') +
      '<div style="display:flex;justify-content:space-between;margin-top:8px;">' +
        '<span style="font-size:11px;color:#9ca3af;">Progress to goal</span>' +
        (showPct ? '<span style="font-size:11px;color:#9ca3af;">' + pct + '%</span>' : '') +
      '</div>'
    );
  }
})();`;

  return new Response(js, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/javascript; charset=utf-8',
      'Cache-Control': 'public, max-age=300',
    },
  });
});
