import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class BrandRedemptionsScreen extends StatefulWidget {
  const BrandRedemptionsScreen({super.key});

  @override
  State<BrandRedemptionsScreen> createState() => _BrandRedemptionsScreenState();
}

class _BrandRedemptionsScreenState extends State<BrandRedemptionsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _redemptions = [];
  List<Map<String, dynamic>> _offers = [];
  String? _selectedOfferId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final brand = await _supabase
          .from('brands')
          .select('id')
          .eq('owner_user_id', user.id)
          .maybeSingle();

      if (brand == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final brandId = brand['id'] as String;

      // Load brand's offers for filter
      final offersRes = await _supabase
          .from('offers')
          .select('id, title')
          .eq('brand_id', brandId)
          .order('created_at', ascending: false);

      // Load redemptions for this brand's offers
      var query = _supabase
          .from('redemptions')
          .select('*, offers!inner(id, title, brand_id, discount_code), profiles(display_name, avatar_url)')
          .eq('offers.brand_id', brandId)
          .order('redeemed_at', ascending: false);

      final redemptionsRes = await query;

      if (mounted) {
        setState(() {
          _offers = List<Map<String, dynamic>>.from(offersRes);
          _redemptions = List<Map<String, dynamic>>.from(redemptionsRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Redemptions fetch error: $e');
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedOfferId == null) return _redemptions;
    return _redemptions.where((r) {
      final offer = r['offers'] as Map?;
      return offer?['id'] == _selectedOfferId;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.backgroundDark : const Color(0xFFF0FDF4);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Code Redemptions', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.textMain),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _hasError
              ? _buildError()
              : Column(
                  children: [
                    _buildFilterChips(isDark),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchData,
                        color: AppTheme.primaryGreen,
                        child: _filtered.isEmpty
                            ? _buildEmpty()
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, i) => _buildRedemptionTile(_filtered[i], isDark),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Container(
      height: 56,
      color: isDark ? AppTheme.backgroundDark : const Color(0xFFF0FDF4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _filterChip(null, 'All Offers', isDark),
          ..._offers.map((o) => _filterChip(o['id'], o['title'] ?? 'Offer', isDark)),
        ],
      ),
    );
  }

  Widget _filterChip(String? offerId, String label, bool isDark) {
    final selected = _selectedOfferId == offerId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedOfferId = offerId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryGreen : (isDark ? Colors.white12 : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppTheme.primaryGreen : Colors.grey.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : (isDark ? Colors.white70 : AppTheme.textSub),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRedemptionTile(Map<String, dynamic> r, bool isDark) {
    final offer = r['offers'] as Map?;
    final profile = r['profiles'] as Map?;
    final offerTitle = offer?['title'] ?? 'Unknown Offer';
    final code = r['promo_code'] ?? '—';
    final userName = profile?['display_name'] ?? 'Anonymous';
    final at = r['redeemed_at'] != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(r['redeemed_at']).toLocal())
        : '—';
    final statusStr = r['status']?.toString() ?? 'active';
    final statusColor = statusStr == 'active'
        ? AppTheme.primaryGreen
        : statusStr == 'used'
            ? Colors.orange
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: AppTheme.primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offerTitle, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textMain)),
                const SizedBox(height: 2),
                Text(userName, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSub)),
                const SizedBox(height: 4),
                Text(at, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSub.withOpacity(0.7))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied'), duration: Duration(seconds: 1)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(code, style: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textMain)),
                      const SizedBox(width: 4),
                      Icon(Icons.copy, size: 12, color: isDark ? Colors.white38 : Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusStr,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No redemptions yet', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 8),
          Text('When customers redeem your offers,\ntheir codes will appear here.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppTheme.textSub)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Could not load redemptions', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
