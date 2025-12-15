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
  String _projectUrl = 'gwmcmlpuqummaumjloci.supabase.co'; // Should be dynamic or env but hardcoding for now based on context

  final Map<String, Map<String, dynamic>> _variants = {
    'card': {
      'name': 'Card',
      'description': 'Centered card with logo and stats',
      'icon': Icons.credit_card,
    },
    'compact': {
      'name': 'Compact',
      'description': 'Horizontal layout, smaller footprint',
      'icon': Icons.view_compact,
    },
    'banner': {
      'name': 'Banner',
      'description': 'Wide horizontal banner style',
      'icon': Icons.view_agenda,
    },
    'minimal': {
      'name': 'Minimal',
      'description': 'Simple stats only',
      'icon': Icons.minimize,
    },
    'badge': {
      'name': 'Badge',
      'description': 'Small badge style',
      'icon': Icons.badge,
    },
    'progress': {
      'name': 'Progress',
      'description': 'With animated progress bar',
      'icon': Icons.track_changes,
    },
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
    // Embeddable widget snippet using the brand's public API key
    return '''<div id="eco-rewards-widget"></div>
<script src="https://cdn.ecorewards.io/widget.js"
        data-key="$_apiKey"
        data-variant="$_selectedVariant"></script>''';
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme:
            IconThemeData(color: isDark ? Colors.white : AppTheme.textMain),
        title: Text(
          'Widget Settings',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : AppTheme.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Intro
              Text(
                'Integration Tools',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 6),
            Text(
                'Manage your public API key and embeddable widget to track sustainability impact in real-time.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : AppTheme.textSub,
                ),
              ),
              const SizedBox(height: 20),

              // API key card
            Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.surfaceDark.withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.vpn_key,
                              color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Public API Key',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textMain,
                          ),
                      ),
                    ],
                  ),
                    const SizedBox(height: 16),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                    child: Text(
                              _apiKey ?? 'Loading...',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0E1B17),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _apiKey == null
                            ? null
                            : () {
                                Clipboard.setData(
                                    ClipboardData(text: _apiKey!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('API key copied')),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text(
                          'Copy Key',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

              // Widget Variant Selection
              Text(
                'Widget Design',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a design variant that matches your website style.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : AppTheme.textSub,
                ),
              ),
              const SizedBox(height: 12),
              
              // Variant Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _variants.length,
                itemBuilder: (context, index) {
                  final variantKey = _variants.keys.elementAt(index);
                  final variant = _variants[variantKey]!;
                  final isSelected = _selectedVariant == variantKey;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVariant = variantKey;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen.withOpacity(0.15)
                            : (isDark
                                ? AppTheme.surfaceDark.withOpacity(0.9)
                                : Colors.white.withOpacity(0.9)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : (isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.white.withOpacity(0.6)),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppTheme.primaryGreen.withOpacity(0.2)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: isSelected ? 12 : 8,
                            offset: Offset(0, isSelected ? 4 : 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              variant['icon'] as IconData,
                              color: isSelected ? Colors.white : AppTheme.primaryGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            variant['name'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textMain,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            variant['description'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isDark ? Colors.grey[400] : AppTheme.textSub,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 4),
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryGreen,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),

              // Embeddable widget section
              Text(
                'Embeddable Widget',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add the container div and script tag to your website HTML.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : AppTheme.textSub,
                ),
              ),
              const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.surfaceDark.withOpacity(0.95)
                      : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.code,
                            color: AppTheme.primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Install the script',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '1. Add the container div where you want the widget to appear\n2. Add the script tag in your <head> or before closing </body>',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : AppTheme.textSub,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              _snippet,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                height: 1.5,
                                color: Colors.green[200],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _snippet));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Snippet copied to clipboard')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.file_copy, size: 18),
                        label: const Text(
                          'Copy Snippet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
