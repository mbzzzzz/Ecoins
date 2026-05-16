import 'dart:ui';
import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WidgetIntegrationScreen extends StatefulWidget {
  const WidgetIntegrationScreen({super.key});

  @override
  State<WidgetIntegrationScreen> createState() =>
      _WidgetIntegrationScreenState();
}

class _WidgetIntegrationScreenState extends State<WidgetIntegrationScreen> {
  String? _apiKey;
  bool _isLoading = true;
  double _realtimeCarbon = 0.0;
  bool _isLoadingData = false;

  // Customization State
  String _selectedVariant = 'banner'; // 'banner', 'ring', 'illustrative-tree'
  Color _accentColor = const Color(0xFF11BB82);
  String _selectedFont = 'Inter';
  bool _showPercentage = true;
  bool _showRawValues = true;

  final List<Map<String, dynamic>> _variants = [
    {'id': 'banner', 'name': 'Banner', 'icon': Icons.view_agenda_outlined},
    {'id': 'card', 'name': 'Impact Card', 'icon': Icons.badge_outlined},
    {'id': 'ring', 'name': 'Ring', 'icon': Icons.circle_outlined},
    {'id': 'minimal', 'name': 'Minimal', 'icon': Icons.remove_circle_outline},
    {'id': 'illustrative-tree', 'name': 'Tree', 'icon': Icons.forest_outlined},
  ];

  final List<Color> _accentOptions = [
    const Color(0xFF11BB82), // Primary Green
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFF59E0B), // Orange
    const Color(0xFFEC4899), // Pink
  ];

  final List<String> _fontOptions = [
    'Inter',
    'Outfit',
    'Roboto Mono',
    'Open Sans',
  ];

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
        if (_apiKey != null) {
          _fetchRealtimeData();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRealtimeData() async {
    if (_apiKey == null) return;
    setState(() => _isLoadingData = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'brand-api',
        method: HttpMethod.get,
        queryParameters: {'key': _apiKey},
      );
      final data = response.data ?? {};
      if (mounted) {
        setState(() {
          _realtimeCarbon = (data['total_carbon_saved'] ?? 0.0).toDouble();
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching realtime data: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  static const _widgetScriptUrl =
      'https://eenpgfvmynemualvozhd.supabase.co/functions/v1/serve-widget';

  String get _snippet {
    final key = _apiKey ?? 'YOUR_API_KEY';
    final accentHex = '#${_accentColor.value.toRadixString(16).substring(2)}';
    return '<script src="$_widgetScriptUrl"\n'
        '        data-key="$key"\n'
        '        data-variant="$_selectedVariant"\n'
        '        data-accent="$accentHex"\n'
        '        data-font="$_selectedFont"\n'
        '        data-show-percentage="$_showPercentage"\n'
        '        data-show-values="$_showRawValues">\n'
        '</script>';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgLight = const Color(0xFFF6F8F7);
    final bgDark = const Color(0xFF10221C);
    
    final bgGradientColors = isDark 
        ? [const Color(0xFF10221C), const Color(0xFF091511)]
        : [const Color(0xFFF6F8F7), const Color(0xFFE6F5EF)];

    final textMain = isDark ? Colors.white : const Color(0xFF0E1B17);
    final textSecondary = isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF0E1B17).withOpacity(0.7);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: isDark ? bgDark : bgLight,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgGradientColors,
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildBackButton(context, isDark, textMain),
                    Expanded(
                      child: Text(
                        'Widget Settings',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                          letterSpacing: -0.015,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), 
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Integration Tools',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textMain,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Customize and integrate your sustainability impact widget.',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildApiKeyCard(isDark, textMain),

                    const SizedBox(height: 12),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Customize Widget',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                          letterSpacing: -0.015,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildCustomizeCard(isDark, textMain, textSecondary),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Embed Code',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                          letterSpacing: -0.015,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildEmbedSnippetCard(isDark, textMain, textSecondary),

                    const SizedBox(height: 32),
                    
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                             fontSize: 14,
                             color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF0E1B17).withOpacity(0.5)
                          ),
                          children: [
                            const TextSpan(text: 'Having trouble? '),
                            TextSpan(
                              text: 'View documentation',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF11BB82),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isDark, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(24),
        hoverColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(Icons.arrow_back, color: color),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    required bool isDark,
    double padding = 20,
    bool glow = false,
  }) {
    return Container(
       padding: EdgeInsets.all(padding),
       decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2925).withOpacity(0.7) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
        ),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (glow)
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color: const Color(0xFF11BB82).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyCard(bool isDark, Color textMain) {
    return _buildGlassContainer(
      isDark: isDark,
      glow: true,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF11BB82).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.vpn_key, color: Color(0xFF11BB82), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Public API Key',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    _isLoading
                        ? 'Loading...'
                        : (_apiKey ?? 'No API key found for this account'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isLoading || _apiKey != null
                          ? textMain
                          : Colors.redAccent,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _apiKey == null
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: _apiKey!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API Key copied')),
                      );
                    },
              icon: const Icon(Icons.copy, size: 20),
              label: const Text('Copy Key'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11BB82), 
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizeCard(bool isDark, Color textMain, Color textSecondary) {
    return _buildGlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LIVE PREVIEW',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary.withOpacity(0.5),
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF11BB82).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _realtimeCarbon > 0 ? 'Live Data' : 'Sample Preview',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF11BB82),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2E26) : Colors.white,
              border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                 BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)), 
              ]
            ),
            child: _buildPreviewContent(isDark, textMain),
          ),
          
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          const SizedBox(height: 12),

          Text(
            'Widget Type',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textMain),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _variants.map((variant) {
                final isSelected = _selectedVariant == variant['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedVariant = variant['id']),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? const Color(0xFF11BB82).withOpacity(0.1) 
                        : (isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.6)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF11BB82) : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(variant['icon'], 
                             size: 18, 
                             color: isSelected ? const Color(0xFF11BB82) : textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          variant['name'],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF11BB82) : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Accent Color',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textMain),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _accentOptions.map((color) {
                final isSelected = _accentColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _accentColor = color),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                      border: isSelected 
                        ? Border.all(color: isDark ? const Color(0xFF1E2925) : const Color(0xFFF6F8F7), width: 2) 
                        : null,
                    ),
                    child: isSelected 
                      ? const Center(child: Icon(Icons.check, size: 18, color: Colors.white))
                      : null,
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 20),

          Text(
            'Typography',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textMain),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFont,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF2C3935) : Colors.white,
                icon: Icon(Icons.expand_more, color: textSecondary),
                style: TextStyle(color: textMain, fontSize: 14),
                items: _fontOptions.map((font) {
                  return DropdownMenuItem(
                    value: font,
                    child: Text(font, style: GoogleFonts.getFont(font)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedFont = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),
          
          _buildToggleOption(
            title: 'Show Percentage',
            subtitle: 'Display progress %',
            value: _showPercentage,
            onChanged: (v) => setState(() => _showPercentage = v),
            isDark: isDark,
            textMain: textMain,
            textSecondary: textSecondary,
          ),
           _buildToggleOption(
            title: 'Raw CO₂ Values',
            subtitle: 'Show kg saved',
            value: _showRawValues,
            onChanged: (v) => setState(() => _showRawValues = v),
             isDark: isDark,
            textMain: textMain,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(bool isDark, Color textMain) {
     final carbonVal = _realtimeCarbon;
     final displayVal = carbonVal; 
     
     // Mock Goal
     final goal = 2000;
     final progress = (displayVal / goal).clamp(0.0, 1.0);
     final percentage = (progress * 100).round();

     switch (_selectedVariant) {
       case 'minimal':
         return Center(
           child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             decoration: BoxDecoration(
               color: isDark ? Colors.black54 : Colors.white,
               borderRadius: BorderRadius.circular(50), 
               border: Border.all(color: Colors.grey.withOpacity(0.2)),
             ),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Container(
                   width: 24, height: 24,
                   decoration: BoxDecoration(color: _accentColor.withOpacity(0.2), shape: BoxShape.circle),
                   child: Icon(Icons.eco, size: 14, color: _accentColor),
                 ),
                 const SizedBox(width: 8),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text('OFFSET', style: GoogleFonts.getFont(_selectedFont, fontSize: 8, fontWeight: FontWeight.w700, color: Colors.grey)),
                     Text('${displayVal.toInt()} kg CO₂', style: GoogleFonts.getFont(_selectedFont, fontSize: 13, fontWeight: FontWeight.w800, color: textMain, height: 1.0)),
                   ],
                 )
               ],
             ),
           ),
         );

       case 'card':
         return Column(
           children: [
             Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: _accentColor.withOpacity(0.1),
                 borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('CERTIFIED IMPACT', style: GoogleFonts.getFont(_selectedFont, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: _accentColor)),
                       const SizedBox(height: 4),
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.baseline,
                         textBaseline: TextBaseline.alphabetic,
                         children: [
                           Text(displayVal.toInt().toString(), style: GoogleFonts.getFont(_selectedFont, fontSize: 28, fontWeight: FontWeight.w800, color: textMain)),
                           const SizedBox(width: 4),
                           Text('kg', style: GoogleFonts.getFont(_selectedFont, fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                         ],
                       )
                     ],
                   ),
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                     child: Icon(Icons.verified, color: _accentColor, size: 20),
                   )
                 ],
               ),
             ),
             Container(
               padding: const EdgeInsets.all(16),
               child: Column(
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Goal Progress', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textMain)),
                       Text('$percentage%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: _accentColor)),
                     ],
                   ),
                   const SizedBox(height: 6),
                   ClipRRect(
                     borderRadius: BorderRadius.circular(4),
                     child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(_accentColor)),
                   ),
                   const SizedBox(height: 16),
                   Text('Verified by Eco Rewards', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                 ],
               ),
             )
           ],
         );

       case 'ring':
         return Center(
           child: Column(
             children: [
               SizedBox(
                 height: 140,
                 width: 140,
                 child: Stack(
                   alignment: Alignment.center,
                   children: [
                     CircularProgressIndicator(
                       value: 1.0, 
                       strokeWidth: 12,
                       color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                     ),
                     CircularProgressIndicator(
                       value: progress,
                       strokeWidth: 12,
                       color: _accentColor,
                       strokeCap: StrokeCap.round,
                     ),
                     Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Text(
                           displayVal.toInt().toString(), 
                           style: GoogleFonts.getFont(
                             _selectedFont,
                             fontSize: 24,
                             fontWeight: FontWeight.bold,
                             color: textMain,
                           ),
                         ),
                         Text(
                           'kg CO₂',
                           style: GoogleFonts.getFont(
                             _selectedFont,
                             fontSize: 10,
                             fontWeight: FontWeight.w600,
                             color: Colors.grey,
                             letterSpacing: 1.0,
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 12),
               Text('Sustainability Goal', style: GoogleFonts.getFont(_selectedFont, fontSize: 11, fontWeight: FontWeight.w600, color: textMain)),
             ],
           ),
         );

       case 'illustrative-tree':
         return Column(
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text('TOTAL IMPACT', style: GoogleFonts.getFont(_selectedFont, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey)),
                     Row(
                       children: [
                         Text(displayVal.toInt().toString(), style: GoogleFonts.getFont(_selectedFont, fontSize: 24, fontWeight: FontWeight.bold, color: textMain)),
                         const SizedBox(width: 4),
                         Text('kg CO₂e', style: GoogleFonts.getFont(_selectedFont, fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                       ],
                     ),
                   ],
                 ),
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: _accentColor.withOpacity(0.1),
                     shape: BoxShape.circle
                   ),
                   child: Icon(Icons.forest, size: 24, color: _accentColor),
                 ),
               ],
             ),
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF6F8F7),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
               ),
               child: Row(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), shape: BoxShape.circle),
                     child: Icon(Icons.check, size: 14, color: _accentColor),
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text.rich(
                       TextSpan(
                         children: [
                           TextSpan(text: 'Equivalent to ', style: GoogleFonts.getFont(_selectedFont, fontSize: 11, color: textMain)),
                           TextSpan(text: '${(displayVal / 20).round()} trees planted', style: GoogleFonts.getFont(_selectedFont, fontSize: 11, fontWeight: FontWeight.bold, color: _accentColor)),
                         ]
                       )
                     ),
                   )
                 ],
               ),
             ),
             const SizedBox(height: 12),
             ClipRRect(
               borderRadius: BorderRadius.circular(2),
               child: LinearProgressIndicator(
                 value: progress,
                 minHeight: 4,
                 backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                 valueColor: AlwaysStoppedAnimation(_accentColor),
               ),
             )
           ],
         );

       case 'banner':
       default:
         return Column(
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                 Text(
                   'Eco Impact',
                   style: GoogleFonts.getFont(
                     _selectedFont,
                     fontWeight: FontWeight.bold,
                     fontSize: 14,
                     color: textMain,
                     letterSpacing: -0.02,
                   )
                 ),
                 if (_showRawValues)
                   Row(
                     children: [
                       Icon(Icons.eco, size: 14, color: _accentColor),
                       const SizedBox(width: 4),
                       Text(
                         '${displayVal.toInt()} kg',
                         style: GoogleFonts.jetBrainsMono(
                           fontSize: 12,
                           fontWeight: FontWeight.bold,
                           color: _accentColor,
                         ),
                       )
                     ],
                   ),
               ],
             ),
             const SizedBox(height: 12),
             Stack(
               children: [
                 Container(
                   height: 12,
                   width: double.infinity,
                   decoration: BoxDecoration(
                     color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                     borderRadius: BorderRadius.circular(6),
                   ),
                 ),
                 LayoutBuilder(
                   builder: (context, constraints) {
                     return Container(
                       height: 12,
                       width: constraints.maxWidth * progress, 
                       decoration: BoxDecoration(
                         color: _accentColor,
                         borderRadius: BorderRadius.circular(6),
                       ),
                       child: Container(
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.2), // highlight
                           borderRadius: BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
                         ),
                       ),
                     );
                   }
                 ),
               ],
             ),
             const SizedBox(height: 8),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('Progress to goal', style: GoogleFonts.getFont(_selectedFont, fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF0E1B17).withOpacity(0.5))),
                 if (_showPercentage)
                  Text('$percentage%', style: GoogleFonts.getFont(_selectedFont, fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF0E1B17).withOpacity(0.5))),
               ],
             ),
           ],
         );
     }
  }

  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color textMain,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: textMain)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF11BB82),
            activeTrackColor: const Color(0xFF11BB82).withOpacity(0.2),
            thumbColor: MaterialStateProperty.all(Colors.white),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
        ],
      ),
    );
  }

  Widget _buildEmbedSnippetCard(bool isDark, Color textMain, Color textSecondary) {
    return _buildGlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const Icon(Icons.code, color: Color(0xFF11BB82), size: 24),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       'Install the script',
                       style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textMain),
                     ),
                     const SizedBox(height: 4),
                     Text.rich(
                       TextSpan(
                         text: 'Settings are automatically applied to your unique key. Paste this into your ',
                         style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
                         children: [
                           WidgetSpan(
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                               decoration: BoxDecoration(
                                 color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                 borderRadius: BorderRadius.circular(4),
                               ),
                               child: Text('<head>', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF11BB82))),
                             )
                           ),
                           const TextSpan(text: '.'),
                         ]
                       )
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
               color: const Color(0xFF1E293B), // Slate 800
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Colors.white.withOpacity(0.1)),
               boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                     Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)), // Red
                     const SizedBox(width: 6),
                     Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFEAB308), shape: BoxShape.circle)), // Yellow
                     const SizedBox(width: 6),
                     Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)), // Green
                   ],
                 ),
                 const SizedBox(height: 12),
                 SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   child: SelectableText.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: '<script ', style: TextStyle(color: Color(0xFFC084FC))),
                            const TextSpan(text: 'src', style: TextStyle(color: Color(0xFF7DD3FC))),
                            const TextSpan(text: '=', style: TextStyle(color: Colors.white)),
                            TextSpan(text: '"$_widgetScriptUrl"\n        ', style: const TextStyle(color: Color(0xFF86EFAC))),
                            const TextSpan(text: 'data-key', style: TextStyle(color: Color(0xFF7DD3FC))),
                            const TextSpan(text: '=', style: TextStyle(color: Colors.white)),
                            TextSpan(text: '"${_apiKey ?? 'YOUR_API_KEY'}"\n        ', style: const TextStyle(color: Color(0xFF86EFAC))),
                            const TextSpan(text: 'data-variant', style: TextStyle(color: Color(0xFF7DD3FC))),
                            const TextSpan(text: '=', style: TextStyle(color: Colors.white)),
                            TextSpan(text: '"$_selectedVariant"\n        ', style: const TextStyle(color: Color(0xFF86EFAC))),
                            const TextSpan(text: 'data-accent', style: TextStyle(color: Color(0xFF7DD3FC))),
                            const TextSpan(text: '=', style: TextStyle(color: Colors.white)),
                            TextSpan(text: '"#${_accentColor.value.toRadixString(16).substring(2)}"\n        ', style: const TextStyle(color: Color(0xFF86EFAC))),
                            const TextSpan(text: 'data-font', style: TextStyle(color: Color(0xFF7DD3FC))),
                            const TextSpan(text: '=', style: TextStyle(color: Colors.white)),
                            TextSpan(text: '"$_selectedFont"\n        ', style: const TextStyle(color: Color(0xFF86EFAC))),
                            const TextSpan(text: 'data-show-percentage', style: TextStyle(color: Color(0xFF7DD3FC))),
                            const TextSpan(text: '=', style: TextStyle(color: Colors.white)),
                            TextSpan(text: '"$_showPercentage"\n        ', style: const TextStyle(color: Color(0xFF86EFAC))),
                            const TextSpan(text: 'data-show-values', style: TextStyle(color: Color(0xFF7DD3FC))),
                            const TextSpan(text: '=', style: TextStyle(color: Colors.white)),
                            TextSpan(text: '"$_showRawValues"', style: const TextStyle(color: Color(0xFF86EFAC))),
                            const TextSpan(text: '>\n', style: TextStyle(color: Color(0xFFC084FC))),
                            const TextSpan(text: '</script>', style: TextStyle(color: Color(0xFFC084FC))),
                          ],
                          style: GoogleFonts.jetBrainsMono(fontSize: 12, height: 1.5)
                        ),
                      ),
                 )
               ],
             ),
           ),
           const SizedBox(height: 16),
           SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                  Clipboard.setData(ClipboardData(text: _snippet));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Snippet copied to clipboard')),
                  );
              },
              icon: const Icon(Icons.file_copy_outlined, size: 20),
              label: const Text('Copy Snippet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11BB82),
                  foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF11BB82).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


}
