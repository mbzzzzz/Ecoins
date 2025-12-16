(function () {
    const scriptTag = document.currentScript;
    const apiKey = scriptTag.getAttribute('data-key') || new URL(scriptTag.src).searchParams.get('key');
    const variant = scriptTag.getAttribute('data-variant') || 'card';

    if (!apiKey) {
        console.error('Eco Rewards Widget: Missing API Key');
        return;
    }

    const container = document.getElementById('eco-rewards-widget');
    if (!container) return;

    // Insert styles for all variants
    const style = document.createElement('style');
    style.innerHTML = `
    /* Base styles */
    .eco-widget-base {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      box-sizing: border-box;
    }
    
    /* Tree Icon SVG */
    .eco-widget-tree-icon {
      width: 24px;
      height: 24px;
      display: inline-block;
      vertical-align: middle;
      margin-right: 4px;
    }
    
    /* Card Variant - Centered Card (Default) */
    .eco-widget-card {
      background: #ffffff;
      border: 1px solid #e5e7eb;
      border-radius: 16px;
      padding: 20px;
      width: 100%;
      max-width: 320px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
    }
    .eco-widget-card .eco-widget-logo {
      width: 60px;
      height: 60px;
      border-radius: 50%;
      object-fit: cover;
      margin-bottom: 12px;
      border: 2px solid #10B981;
    }
    .eco-widget-card .eco-widget-title {
      font-size: 16px;
      font-weight: 600;
      color: #1f2937;
      margin: 0 0 4px 0;
    }
    .eco-widget-card .eco-widget-subtitle {
      font-size: 12px;
      color: #6b7280;
      margin-bottom: 16px;
    }
    .eco-widget-card .eco-widget-stat {
      font-size: 24px;
      font-weight: 800;
      color: #10B981;
      margin: 0;
    }
    .eco-widget-card .eco-widget-label {
      font-size: 12px;
      color: #6b7280;
      margin-top: 4px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .eco-widget-card .eco-widget-equivalent {
      margin-top: 12px;
      padding: 10px 14px;
      background: #f0fdf4;
      border-radius: 10px;
      border: 1px solid #dcfce7;
      width: 100%;
    }
    .eco-widget-card .eco-widget-equivalent-text {
      font-size: 11px;
      color: #15803d;
      font-weight: 600;
      line-height: 1.4;
    }
    .eco-widget-card .eco-widget-equivalent-number {
      font-size: 18px;
      font-weight: 800;
      color: #10B981;
      margin: 4px 0;
    }
    .eco-widget-card .eco-widget-footer {
      margin-top: 16px;
      font-size: 10px;
      color: #9ca3af;
    }
    
    /* Compact Variant - Horizontal Layout */
    .eco-widget-compact {
      background: #ffffff;
      border: 1px solid #e5e7eb;
      border-radius: 12px;
      padding: 12px 16px;
      width: 100%;
      max-width: 400px;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .eco-widget-compact .eco-widget-logo {
      width: 48px;
      height: 48px;
      border-radius: 8px;
      object-fit: cover;
      flex-shrink: 0;
    }
    .eco-widget-compact .eco-widget-content {
      flex: 1;
      min-width: 0;
    }
    .eco-widget-compact .eco-widget-title {
      font-size: 14px;
      font-weight: 600;
      color: #1f2937;
      margin: 0 0 2px 0;
    }
    .eco-widget-compact .eco-widget-stat {
      font-size: 20px;
      font-weight: 800;
      color: #10B981;
      margin: 0;
      line-height: 1.2;
    }
    .eco-widget-compact .eco-widget-label {
      font-size: 10px;
      color: #6b7280;
      margin-top: 2px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    
    /* Banner Variant - Wide Horizontal Banner */
    .eco-widget-banner {
      background: linear-gradient(135deg, #10B981 0%, #059669 100%);
      border-radius: 12px;
      padding: 20px 24px;
      width: 100%;
      max-width: 600px;
      box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 20px;
      color: white;
    }
    .eco-widget-banner .eco-widget-left {
      display: flex;
      align-items: center;
      gap: 16px;
    }
    .eco-widget-banner .eco-widget-logo {
      width: 56px;
      height: 56px;
      border-radius: 12px;
      object-fit: cover;
      border: 2px solid rgba(255, 255, 255, 0.3);
      background: rgba(255, 255, 255, 0.1);
    }
    .eco-widget-banner .eco-widget-info h3 {
      font-size: 16px;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: white;
    }
    .eco-widget-banner .eco-widget-info p {
      font-size: 11px;
      margin: 0;
      opacity: 0.9;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .eco-widget-banner .eco-widget-right {
      text-align: right;
    }
    .eco-widget-banner .eco-widget-stat {
      font-size: 32px;
      font-weight: 800;
      margin: 0;
      color: white;
      line-height: 1;
    }
    .eco-widget-banner .eco-widget-label {
      font-size: 11px;
      margin-top: 4px;
      opacity: 0.9;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    
    /* Minimal Variant - Simple Stats Only */
    .eco-widget-minimal {
      background: transparent;
      padding: 0;
      display: inline-flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
    }
    .eco-widget-minimal .eco-widget-stat {
      font-size: 36px;
      font-weight: 800;
      color: #10B981;
      margin: 0;
      line-height: 1;
    }
    .eco-widget-minimal .eco-widget-label {
      font-size: 11px;
      color: #6b7280;
      margin-top: 6px;
      text-transform: uppercase;
      letter-spacing: 1px;
      font-weight: 500;
    }
    .eco-widget-minimal .eco-widget-footer {
      margin-top: 8px;
      font-size: 9px;
      color: #9ca3af;
    }
    
    /* Badge Variant - Small Badge Style */
    .eco-widget-badge {
      background: #ffffff;
      border: 2px solid #10B981;
      border-radius: 24px;
      padding: 8px 16px;
      display: inline-flex;
      align-items: center;
      gap: 10px;
      box-shadow: 0 2px 8px rgba(16, 185, 129, 0.15);
    }
    .eco-widget-badge .eco-widget-logo {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      object-fit: cover;
      border: 1px solid #10B981;
    }
    .eco-widget-badge .eco-widget-content {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }
    .eco-widget-badge .eco-widget-stat {
      font-size: 16px;
      font-weight: 800;
      color: #10B981;
      margin: 0;
      line-height: 1;
    }
    .eco-widget-badge .eco-widget-label {
      font-size: 9px;
      color: #6b7280;
      margin: 0;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    
    /* Progress Variant - With Progress Bar */
    .eco-widget-progress {
      background: linear-gradient(to bottom, #f0fdf4 0%, #ffffff 30%);
      border: 1px solid #dcfce7;
      border-radius: 20px;
      padding: 20px;
      width: 100%;
      max-width: 380px;
      box-shadow: 0 4px 12px rgba(16, 185, 129, 0.1);
      position: relative;
      overflow: hidden;
    }
    .eco-widget-progress::before {
      content: '';
      position: absolute;
      top: -50px;
      right: -50px;
      width: 150px;
      height: 150px;
      background: radial-gradient(circle, rgba(16, 185, 129, 0.1) 0%, transparent 70%);
      border-radius: 50%;
    }
    .eco-widget-progress .eco-widget-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 16px;
      position: relative;
      z-index: 1;
    }
    .eco-widget-progress .eco-widget-logo {
      width: 48px;
      height: 48px;
      border-radius: 10px;
      object-fit: cover;
      border: 2px solid #dcfce7;
    }
    .eco-widget-progress .eco-widget-header-text h3 {
      font-size: 16px;
      font-weight: 600;
      color: #1f2937;
      margin: 0 0 2px 0;
    }
    .eco-widget-progress .eco-widget-header-text p {
      font-size: 11px;
      color: #6b7280;
      margin: 0;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .eco-widget-progress .eco-widget-stat-container {
      margin-bottom: 16px;
      position: relative;
      z-index: 1;
    }
    .eco-widget-progress .eco-widget-stat {
      font-size: 32px;
      font-weight: 800;
      color: #10B981;
      margin: 0 0 4px 0;
    }
    .eco-widget-progress .eco-widget-label {
      font-size: 12px;
      color: #6b7280;
      margin: 0;
    }
    .eco-widget-progress .eco-widget-equivalent-box {
      background: white;
      border: 1px solid #dcfce7;
      border-radius: 12px;
      padding: 12px;
      margin-bottom: 16px;
      position: relative;
      z-index: 1;
    }
    .eco-widget-progress .eco-widget-equivalent-header {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 8px;
    }
    .eco-widget-progress .eco-widget-equivalent-label {
      font-size: 10px;
      font-weight: 700;
      color: #15803d;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .eco-widget-progress .eco-widget-equivalent-text {
      font-size: 13px;
      color: #1f2937;
      font-weight: 600;
      line-height: 1.4;
      margin: 0;
    }
    .eco-widget-progress .eco-widget-equivalent-text .eco-widget-tree-count {
      color: #10B981;
      font-weight: 800;
    }
    .eco-widget-progress .eco-widget-progress-bar {
      height: 10px;
      background: #e5e7eb;
      border-radius: 6px;
      overflow: hidden;
      margin-top: 12px;
      position: relative;
      z-index: 1;
    }
    .eco-widget-progress .eco-widget-progress-fill {
      height: 100%;
      background: linear-gradient(90deg, #10B981 0%, #34D399 100%);
      border-radius: 6px;
      transition: width 0.8s ease;
      animation: slideIn 0.8s ease;
      box-shadow: 0 0 10px rgba(16, 185, 129, 0.3);
    }
    .eco-widget-progress .eco-widget-progress-labels {
      display: flex;
      justify-content: space-between;
      margin-top: 6px;
      font-size: 10px;
      color: #9ca3af;
    }
    @keyframes slideIn {
      from { width: 0; }
    }
    .eco-widget-progress .eco-widget-footer {
      margin-top: 12px;
      font-size: 10px;
      color: #9ca3af;
      text-align: center;
      position: relative;
      z-index: 1;
    }
    
    /* Common footer link styles */
    .eco-widget-footer a {
      color: #10B981;
      text-decoration: none;
    }
    .eco-widget-footer a:hover {
      text-decoration: underline;
    }
  `;
    document.head.appendChild(style);

    // Conversion functions
    const CO2_PER_TREE_PER_YEAR = 20; // kg CO₂ absorbed per mature tree per year
    const CO2_PER_CAR_MILE = 0.411; // kg CO₂ per mile driven
    const CO2_PER_GALLON_GAS = 8.887; // kg CO₂ per gallon of gasoline
    
    function calculateTreeEquivalent(kgCO2) {
        return Math.round(kgCO2 / CO2_PER_TREE_PER_YEAR);
    }
    
    function calculateCarMilesEquivalent(kgCO2) {
        return Math.round(kgCO2 / CO2_PER_CAR_MILE);
    }
    
    function formatNumber(num) {
        return num.toLocaleString('en-US');
    }

    // Fetch Data
    fetch(`https://gwmcmlpuqummaumjloci.supabase.co/functions/v1/brand-api?key=${apiKey}`)
        .then(res => res.json())
        .then(data => {
            if (data.error) {
                container.innerHTML = `<div style="color:red; font-size:12px;">Error: ${data.error}</div>`;
                return;
            }

            const carbonSaved = parseFloat(data.total_carbon_saved || 0);
            const carbonSavedFormatted = carbonSaved.toFixed(1);
            const treesEquivalent = calculateTreeEquivalent(carbonSaved);
            const carMilesEquivalent = calculateCarMilesEquivalent(carbonSaved);
            
            // Progress calculation: goal of 200 trees (4000 kg CO₂)
            const treeGoal = 200;
            const progressPercent = Math.min((treesEquivalent / treeGoal) * 100, 100);

            let html = '';
            
            switch(variant) {
                case 'compact':
                    html = `
                        <div class="eco-widget-base eco-widget-compact">
                            <img src="${data.logo_url || 'https://via.placeholder.com/48'}" alt="${data.name} Logo" class="eco-widget-logo" onerror="this.src='https://via.placeholder.com/48'"/>
                            <div class="eco-widget-content">
                                <h3 class="eco-widget-title">${data.name}</h3>
                                <div class="eco-widget-stat">${carbonSavedFormatted} kg</div>
                                <div class="eco-widget-label">CO₂ Saved • ${formatNumber(treesEquivalent)} trees</div>
                            </div>
                        </div>
                    `;
                    break;
                    
                case 'banner':
                    html = `
                        <div class="eco-widget-base eco-widget-banner">
                            <div class="eco-widget-left">
                                <img src="${data.logo_url || 'https://via.placeholder.com/56'}" alt="${data.name} Logo" class="eco-widget-logo" onerror="this.src='https://via.placeholder.com/56'"/>
                                <div class="eco-widget-info">
                                    <h3>${data.name}</h3>
                                    <p>Sustainability Partner</p>
                                </div>
                            </div>
                            <div class="eco-widget-right">
                                <div class="eco-widget-stat">${carbonSavedFormatted} kg</div>
                                <div class="eco-widget-label">CO₂ Saved • ${formatNumber(treesEquivalent)} trees</div>
                            </div>
                        </div>
                    `;
                    break;
                    
                case 'minimal':
                    html = `
                        <div class="eco-widget-base eco-widget-minimal">
                            <div class="eco-widget-stat">${carbonSavedFormatted} kg</div>
                            <div class="eco-widget-label">CO₂ Saved</div>
                            <div style="margin-top: 8px; font-size: 11px; color: #10B981; font-weight: 600;">
                                ≈ ${formatNumber(treesEquivalent)} trees planted
                            </div>
                            <div class="eco-widget-footer">
                                Powered by <a href="https://eco-rewards.com" target="_blank">Eco Rewards</a>
                            </div>
                        </div>
                    `;
                    break;
                    
                case 'badge':
                    html = `
                        <div class="eco-widget-base eco-widget-badge">
                            <img src="${data.logo_url || 'https://via.placeholder.com/32'}" alt="${data.name} Logo" class="eco-widget-logo" onerror="this.src='https://via.placeholder.com/32'"/>
                            <div class="eco-widget-content">
                                <div class="eco-widget-stat">${formatNumber(treesEquivalent)}</div>
                                <div class="eco-widget-label">Trees Planted</div>
                            </div>
                        </div>
                    `;
                    break;
                    
                case 'progress':
                    html = `
                        <div class="eco-widget-base eco-widget-progress">
                            <div class="eco-widget-header">
                                <img src="${data.logo_url || 'https://via.placeholder.com/48'}" alt="${data.name} Logo" class="eco-widget-logo" onerror="this.src='https://via.placeholder.com/48'"/>
                                <div class="eco-widget-header-text">
                                    <h3>${data.name}</h3>
                                    <p>Sustainability Impact</p>
                                </div>
                            </div>
                            <div class="eco-widget-stat-container">
                                <div class="eco-widget-stat">${carbonSavedFormatted} kg</div>
                                <div class="eco-widget-label">CO₂ Removed from Atmosphere</div>
                            </div>
                            <div class="eco-widget-equivalent-box">
                                <div class="eco-widget-equivalent-header">
                                    <svg class="eco-widget-tree-icon" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                        <path d="M10 21 L14 21 L13 15 L11 15 Z" fill="#5D4037"/>
                                        <path d="M12 2 C7 2 4 6 4 10 C4 12 5 14 7 15 L17 15 C19 14 20 12 20 10 C20 6 17 2 12 2 Z" fill="#4ADE80" opacity="0.4"/>
                                        <path d="M12 4 C8 4 6 7 6 10 C6 11.5 7 13 8.5 13.5 L15.5 13.5 C17 13 18 11.5 18 10 C18 7 16 4 12 4 Z" fill="#22C55E" opacity="0.7"/>
                                        <path d="M12 6 C9.5 6 8 8 8 10 C8 11 8.5 12 9.5 12 L14.5 12 C15.5 12 16 11 16 10 C16 8 13.5 6 12 6 Z" fill="#15803D"/>
                                    </svg>
                                    <span class="eco-widget-equivalent-label">Current Milestone</span>
                                </div>
                                <p class="eco-widget-equivalent-text">
                                    Equivalent to planting <span class="eco-widget-tree-count">${formatNumber(treesEquivalent)} trees</span> in the Amazon Rainforest.
                                </p>
                            </div>
                            <div class="eco-widget-progress-bar">
                                <div class="eco-widget-progress-fill" style="width: ${progressPercent}%"></div>
                            </div>
                            <div class="eco-widget-progress-labels">
                                <span>0</span>
                                <span>Goal: ${formatNumber(treeGoal)} trees</span>
                            </div>
                            <div class="eco-widget-footer">
                                Powered by <a href="https://eco-rewards.com" target="_blank">Eco Rewards</a>
                            </div>
                        </div>
                    `;
                    break;
                    
                case 'card':
                default:
                    html = `
                        <div class="eco-widget-base eco-widget-card">
                            <img src="${data.logo_url || 'https://via.placeholder.com/60'}" alt="${data.name} Logo" class="eco-widget-logo" onerror="this.src='https://via.placeholder.com/60'"/>
                            <h3 class="eco-widget-title">${data.name}</h3>
                            <p class="eco-widget-subtitle">Sustainability Partner</p>
                            <h2 class="eco-widget-stat">${carbonSavedFormatted} kg</h2>
                            <p class="eco-widget-label">CO₂ Saved by Community</p>
                            <div class="eco-widget-equivalent">
                                <div class="eco-widget-equivalent-text">
                                    Equivalent to planting
                                </div>
                                <div class="eco-widget-equivalent-number">${formatNumber(treesEquivalent)} trees</div>
                                <div class="eco-widget-equivalent-text" style="font-size: 10px; margin-top: 4px;">
                                    in the Amazon Rainforest
                                </div>
                            </div>
                            <div class="eco-widget-footer">
                                Powered by <a href="https://eco-rewards.com" target="_blank">Eco Rewards</a>
                            </div>
                        </div>
                    `;
            }
            
            container.innerHTML = html;
        })
        .catch(err => {
            console.error(err);
            container.innerHTML = `<div style="color:red; font-size:12px;">Failed to load widget</div>`;
        });

})();
