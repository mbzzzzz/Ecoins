import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class BrandStatsScreen extends StatefulWidget {
  const BrandStatsScreen({super.key});

  @override
  State<BrandStatsScreen> createState() => _BrandStatsScreenState();
}

class _BrandStatsScreenState extends State<BrandStatsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _hasError = false;

  int _totalRedemptions = 0;
  int _activeOffers = 0;
  int _totalUsers = 0;
  double _totalCo2 = 0;
  List<Map<String, dynamic>> _topOffers = [];
  List<Map<String, dynamic>> _recentRedemptions = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Support both owner_id and owner_user_id
      final brand = await _supabase
          .from('brands')
          .select()
          .or('owner_id.eq.${user.id},owner_user_id.eq.${user.id}')
          .maybeSingle();

      if (brand == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final brandId = brand['id'] as String;
      _totalCo2 = (brand['total_carbon_saved'] ?? 0).toDouble();

      // Step 1: fetch all offers for this brand (RLS now allows brand to see own offers)
      final offersRes = await _supabase
          .from('offers')
          .select()
          .eq('brand_id', brandId)
          .order('redeemed_count', ascending: false);

      final offers = offersRes as List;
      final offerIds = offers.map((o) => o['id'] as String).toList();
      final offerLookup = {for (final o in offers) o['id'] as String: o};

      // Step 2: fetch redemptions via inFilter — no join filtering, avoids RLS issues
      List<dynamic> redemptions = [];
      if (offerIds.isNotEmpty) {
        redemptions = await _supabase
            .from('redemptions')
            .select('id, offer_id, user_id, promo_code, status, redeemed_at')
            .inFilter('offer_id', offerIds)
            .order('redeemed_at', ascending: false)
            .limit(20);
      }

      final activeCount = offers.where((o) => o['is_active'] == true).length;
      // Use redeemed_count from offers for total (more reliable than counting rows)
      final totalRedeemed = offers.fold<int>(0, (sum, o) => sum + ((o['redeemed_count'] as int?) ?? 0));

      final uniqueUsers = redemptions
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .length;

      // Enrich recent redemptions with offer title client-side
      final enrichedRedemptions = redemptions.map((r) {
        final oid = r['offer_id'] as String?;
        return {
          ...Map<String, dynamic>.from(r),
          'offer': oid != null ? offerLookup[oid] : null,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _activeOffers = activeCount;
          _totalRedemptions = totalRedeemed;
          _totalUsers = uniqueUsers;
          _topOffers = List<Map<String, dynamic>>.from(offers.take(5));
          _recentRedemptions = List<Map<String, dynamic>>.from(enrichedRedemptions.take(10));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Stats error: $e');
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.backgroundDark : const Color(0xFFF0FDF4);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Analytics', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.textMain),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _hasError
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _fetchStats,
                  color: AppTheme.primaryGreen,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildKpiRow(isDark),
                      const SizedBox(height: 24),
                      _buildCo2Card(isDark),
                      const SizedBox(height: 24),
                      _buildTopOffersCard(isDark),
                      const SizedBox(height: 24),
                      _buildRecentRedemptionsCard(isDark),
                      const SizedBox(height: 40),
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
          Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Could not load analytics', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchStats,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(bool isDark) {
    return Row(
      children: [
        Expanded(child: _kpiCard('Redemptions', '$_totalRedemptions', Icons.redeem_rounded, AppTheme.primaryGreen, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _kpiCard('Live Offers', '$_activeOffers', Icons.campaign_rounded, Colors.blue, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _kpiCard('Unique Users', '$_totalUsers', Icons.people_rounded, Colors.purple, isDark)),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.grey[400] : AppTheme.textSub)),
        ],
      ),
    );
  }

  Widget _buildCo2Card(bool isDark) {
    final trees = (_totalCo2 / 20).floor();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total CO₂ Saved', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('${_totalCo2.toStringAsFixed(1)} kg', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Equivalent to $trees trees planted', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const Text('🌳', style: TextStyle(fontSize: 56)),
        ],
      ),
    );
  }

  Widget _buildTopOffersCard(bool isDark) {
    return _card(
      isDark: isDark,
      title: 'Campaign Performance',
      icon: Icons.bar_chart_rounded,
      child: _topOffers.isEmpty
          ? _empty('No campaigns yet')
          : Column(
              children: _topOffers.map((o) {
                final count = (o['redeemed_count'] as int?) ?? 0;
                final active = o['is_active'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppTheme.primaryGreen : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o['title'] ?? '—', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textMain)),
                            Text(o['discount_code'] ?? '—', style: GoogleFonts.robotoMono(fontSize: 11, color: AppTheme.primaryGreen)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$count redeemed', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildRecentRedemptionsCard(bool isDark) {
    return _card(
      isDark: isDark,
      title: 'Recent Redemptions',
      icon: Icons.receipt_long_rounded,
      child: _recentRedemptions.isEmpty
          ? _empty('No redemptions yet')
          : Column(
              children: _recentRedemptions.map((r) {
                final offerTitle = (r['offer'] as Map?)?['title'] ?? 'Unknown Offer';
                final code = r['promo_code'] ?? '—';
                final at = r['redeemed_at'] != null
                    ? DateFormat('MMM d, h:mm a').format(DateTime.parse(r['redeemed_at']).toLocal())
                    : '—';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.confirmation_number_outlined, color: AppTheme.primaryGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(offerTitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textMain)),
                            Text(at, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSub)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Text(code, style: GoogleFonts.robotoMono(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppTheme.textMain)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _card({required bool isDark, required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _empty(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(child: Text(msg, style: GoogleFonts.inter(color: AppTheme.textSub))),
  );
}
