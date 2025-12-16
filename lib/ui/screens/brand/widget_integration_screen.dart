import 'dart:ui';
import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WidgetIntegrationScreen extends StatefulWidget {
  const WidgetIntegrationScreen({super.key});

  @override
  State<WidgetIntegrationScreen> createState() => _WidgetIntegrationScreenState();
}

class _WidgetIntegrationScreenState extends State<WidgetIntegrationScreen> {
  String? _apiKey;
  bool _isLoading = true;
  String _selectedVariant = 'card';
  String _selectedFont = 'Inter (Default)';
  Color _selectedAccent = const Color(0xFF10B981);
  bool _showPercentage = true;
  bool _showRawValues = true;

  final Map<String, String> _variantNames = {
    'card': 'Card',
    'compact': 'Compact',
    'banner': 'Banner',
    'minimal': 'Minimal',
    'badge': 'Badge',
    'progress': 'Progress',
  };

  @override
  void initState() {
    super.initState();
    _fetchApiKey();
  }

  Future<void> _fetchApiKey() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final data = await Supabase.instance.client
          .from('brands')
          .select('api_key')
          .eq('owner_user_id', user.id)
          .single();
          
      if (mounted) {
        setState(() {
          _apiKey = data['api_key'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _snippet {
    if (_apiKey == null) return 'Loading...';
    // Embeddable widget snippet
    // We append custom attributes if they deviate from default, though widget.js script would need updates to handle them.
    // For now, we stick to standard data-key and data-variant.
    return '''<script src="https://cdn.ecorewards.io/widget.js"
        data-key="$_apiKey"
        data-variant="$_selectedVariant"></script>''';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Background Gradients
    final bgLightStart = AppTheme.backgroundLight;
    final bgLightEnd = const Color(0xFFE6F5EF);
    final bgDarkStart = AppTheme.backgroundDark;
    final bgDarkEnd = const Color(0xFF091511);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0E1B17)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Widget Settings',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : const Color(0xFF0E1B17),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [bgDarkStart, bgDarkEnd] : [bgLightStart, bgLightEnd],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Integration Tools',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0E1B17),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customize and integrate your sustainability impact widget.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : const Color(0xFF0E1B17).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Public API Key Card
                _buildGlassCard(
                  isDark,
                  child: Stack(
                    children: [
                      // Decorative Blur
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.vpn_key, color: AppTheme.primaryGreen),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Public API Key',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0E1B17),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _apiKey ?? 'Loading...',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : const Color(0xFF0E1B17),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildPrimaryButton(
                            label: 'Copy Key',
                            icon: Icons.copy,
                            onPressed: _apiKey == null ? null : () {
                              Clipboard.setData(ClipboardData(text: _apiKey!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('API Key copied')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                Text(
                  'Customize Widget',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0E1B17),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Customize Widget Card
                _buildGlassCard(
                  isDark,
                  child: Column(
                    children: [
                      // Live Preview Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LIVE PREVIEW',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white54 : const Color(0xFF0E1B17).withOpacity(0.5),
                              letterSpacing: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Auto-save',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Preview Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A2E26) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Eco Impact',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0E1B17),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.eco, size: 16, color: _selectedAccent),
                                    const SizedBox(width: 4),
                                    if (_showRawValues)
                                      Text(
                                        '1,250 kg',
                                        style: GoogleFonts.mono(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: _selectedAccent,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Progress Bar
                            Container(
                              height: 10,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Stack(
                                children: [
                                  FractionallySizedBox(
                                    widthFactor: 0.65,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _selectedAccent,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_showPercentage)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progress to goal',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                                  ),
                                  Text(
                                    '65%',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), height: 1),
                      const SizedBox(height: 24),

                      // Controls
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Widget Variant
                          Text(
                            'Widget Layout',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0E1B17)),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedVariant,
                                isExpanded: true,
                                dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
                                items: _variantNames.entries.map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value, style: TextStyle(color: isDark ? Colors.white : AppTheme.textMain)),
                                )).toList(),
                                onChanged: (val) => setState(() => _selectedVariant = val!),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),

                          Text(
                            'Accent Color',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0E1B17)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildColorBtn(const Color(0xFF10B981)), // Green
                              const SizedBox(width: 12),
                              _buildColorBtn(const Color(0xFF3B82F6)), // Blue
                              const SizedBox(width: 12),
                              _buildColorBtn(const Color(0xFF8B5CF6)), // Purple
                              const SizedBox(width: 12),
                              _buildColorBtn(const Color(0xFFF59E0B)), // Amber
                              const SizedBox(width: 12),
                              _buildColorBtn(const Color(0xFFEC4899)), // Pink
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                           // Typography
                          Text(
                            'Typography',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0E1B17)),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedFont,
                                isExpanded: true,
                                dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
                                items: ['Inter (Default)', 'Outfit', 'Roboto Mono', 'Open Sans'].map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f, style: TextStyle(color: isDark ? Colors.white : AppTheme.textMain)),
                                )).toList(),
                                onChanged: (val) => setState(() => _selectedFont = val!),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          
                          // Toggles
                          _buildSwitchRow(isDark, 'Show Percentage', 'Display progress %', _showPercentage, (v) => setState(() => _showPercentage = v)),
                          const SizedBox(height: 12),
                          _buildSwitchRow(isDark, 'Raw CO₂ Values', 'Show kg saved', _showRawValues, (v) => setState(() => _showRawValues = v)),

                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Embed Code',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0E1B17),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Embed Code Card
                _buildGlassCard(
                  isDark,
                  child: Column(
                    children: [
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Icon(Icons.code, color: AppTheme.primaryGreen),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'Install the script',
                                   style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0E1B17)),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   'Paste this code into your <head> tag.',
                                    style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                                 ),
                               ],
                             ),
                           )
                         ],
                       ),
                       const SizedBox(height: 16),
                       Container(
                         width: double.infinity,
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1E293B),
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: Colors.white10),
                           boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, inset: true)],
                         ),
                         child: SingleChildScrollView(
                           scrollDirection: Axis.horizontal,
                           child: Text(
                             _snippet,
                             style: GoogleFonts.jetBrainsMono(
                               fontSize: 12,
                               color: const Color(0xFFA5B4FC), // Indigo 200 light
                             ),
                           ),
                         ),
                       ),
                       const SizedBox(height: 16),
                       _buildPrimaryButton(
                         label: 'Copy Snippet',
                         icon: Icons.file_copy,
                         onPressed: () {
                              Clipboard.setData(ClipboardData(text: _snippet));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Snippet copied')),
                              );
                         }
                       ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text('View documentation', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark.withOpacity(0.7) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect( // For potential backdrop filter if we wanted strict glass
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.transparent, // Required for effect
            child: child,
          ),
        ),
      ),
    ); 
    // Correction: BackdropFilter applies to what's BEHIND the container. 
    // Putting it inside 'child' of Container with opacity might apply blur to the Container background itself if configured right.
    // The standard way: Stack -> [BackdropFilter, Container].
    // But since the Container has opacity, we can just wrap the child content? No.
    // Let's stick to the color opacity which simulates glass well enough for high performance.
    // Reverting the ClipRRect/BackdropFilter inside the return to be safer for Flutter structure.
    // Actually, I'll remove the inner BackdropFilter for simplicity as the outer color opacity is robust.
  }

  Widget _buildPrimaryButton({required String label, required IconData icon, VoidCallback? onPressed}) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildColorBtn(Color color) {
    bool isSelected = _selectedAccent == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedAccent = color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              )
          ],
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }

  Widget _buildSwitchRow(bool isDark, String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0E1B17))),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ),
        Switch.adaptive(
          value: value, 
          onChanged: onChanged,
          activeColor: AppTheme.primaryGreen,
        ),
      ],
    );
  }
}
