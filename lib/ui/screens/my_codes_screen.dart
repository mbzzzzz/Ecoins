import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MyCodesScreen extends StatefulWidget {
  const MyCodesScreen({super.key});

  @override
  State<MyCodesScreen> createState() => _MyCodesScreenState();
}

class _MyCodesScreenState extends State<MyCodesScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _codes = [];

  @override
  void initState() {
    super.initState();
    _fetchCodes();
  }

  Future<void> _fetchCodes() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final res = await _supabase
          .from('redemptions')
          .select('*, offers(title, description, points_cost, brands(name, logo_url))')
          .eq('user_id', user.id)
          .order('redeemed_at', ascending: false);

      if (mounted) {
        setState(() {
          _codes = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('MyCodesScreen error: $e');
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png', fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.primaryDark)),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom app bar over bg image
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text('My Redeemed Codes',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _fetchCodes,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _hasError
                          ? _buildError()
                          : _codes.isEmpty
                              ? _buildEmpty()
                              : RefreshIndicator(
                                  onRefresh: _fetchCodes,
                                  color: AppTheme.primaryGreen,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                                    itemCount: _codes.length,
                                    itemBuilder: (_, i) => _buildCodeCard(_codes[i]),
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(Map<String, dynamic> r) {
    final offer = r['offers'] as Map?;
    final brand = offer?['brands'] as Map?;
    final title = offer?['title'] ?? 'Reward';
    final brandName = brand?['name'] ?? 'Brand Partner';
    final code = r['promo_code'] ?? '—';
    final statusStr = r['status']?.toString() ?? 'active';
    final at = r['redeemed_at'] != null
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(r['redeemed_at']).toLocal())
        : '—';

    final isActive = statusStr == 'active';
    final statusColor = isActive ? AppTheme.primaryGreen : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header strip with brand color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Brand logo
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryGreen.withOpacity(0.15)),
                  child: brand?['logo_url'] != null
                      ? ClipOval(child: Image.network(brand!['logo_url'], fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.store, color: AppTheme.primaryGreen, size: 18)))
                      : const Icon(Icons.store, color: AppTheme.primaryGreen, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                      Text(brandName, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSub)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(isActive ? 'Active' : statusStr, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),
          ),

          // Code section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // The code itself — large and prominent
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          code,
                          style: GoogleFonts.robotoMono(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied "$code"'),
                              backgroundColor: AppTheme.primaryGreen,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.copy_rounded, color: AppTheme.primaryGreen, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Redeemed on $at', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSub)),
                    if (isActive)
                      Text('Show at checkout', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard_outlined, color: Colors.white54, size: 72),
            const SizedBox(height: 20),
            Text('No codes yet', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Redeem offers in the Marketplace\nto collect your discount codes here.',
                textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 56),
          const SizedBox(height: 16),
          Text('Could not load codes', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchCodes,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryDark),
          ),
        ],
      ),
    );
  }
}
