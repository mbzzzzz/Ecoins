import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Fetch redemptions with status 'active'
      // Join with offers and brands to get details
      final data = await _supabase
          .from('redemptions')
          .select('*, offers(*, brands(*))')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('redeemed_at', ascending: false);

      if (mounted) {
        setState(() {
          _coupons = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wallet: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('My Wallet',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_coupons.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.wallet_giftcard, size: 64, color: Colors.white.withOpacity(0.5)),
                   const SizedBox(height: 16),
                   Text(
                     'Your wallet is empty',
                     style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     'Redeem points for rewards to see them here.',
                     style: GoogleFonts.inter(color: Colors.white70),
                   )
                ],
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
              itemCount: _coupons.length,
              itemBuilder: (context, index) {
                return _buildCouponCard(_coupons[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> redemption) {
    final offer = redemption['offers'] as Map<String, dynamic>?;
    final brand = offer?['brands'] as Map<String, dynamic>?;
    
    // Key Logic Change:
    // QR Code = Unique System Code (promo_code)
    // Display Text = Brand's Code (discount_code) or fallback to unique code
    final uniqueQrCode = redemption['promo_code'] ?? 'UNKNOWN';
    final displayCode = offer?['discount_code'] ?? uniqueQrCode;
    
    final expiry = offer?['expires_at'];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Ticket Top (Info)
          GlassContainer(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            padding: const EdgeInsets.all(20),
            opacity: 0.15,
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: brand?['logo_url'] != null
                          ? NetworkImage(brand!['logo_url'])
                          : const AssetImage('assets/images/logo.png') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand?['name'] ?? 'Partner',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer?['title'] ?? 'Reward',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expiry != null 
                             ? 'Expires: ${DateFormat('MMM d, y').format(DateTime.parse(expiry))}'
                             : 'No Expiry',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          // Ticket Divider (Dashed)
          Container(
             color: Colors.white.withOpacity(0.05), // Match glass tint
             height: 1,
             width: double.infinity,
             child: CustomPaint(painter: DashedLinePainter()),
          ),
          
          // Ticket Bottom (QR & Code)
          GlassContainer(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            padding: const EdgeInsets.all(24),
            opacity: 0.2, // Slightly lighter/different for contrast
            child: Column(
              children: [
                Container(
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(16)
                   ),
                   padding: const EdgeInsets.all(12),
                   child: QrImageView(
                     data: uniqueQrCode, // SCAN THIS (Unique)
                     version: QrVersions.auto,
                     size: 140,
                     backgroundColor: Colors.white,
                     eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                     dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                   ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SCAN TO REDEEM',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayCode, // SHOW THIS (Brand Code)
                  style: GoogleFonts.sourceCodePro(
                    color: AppTheme.accentYellow,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 8, dashSpace = 6, startX = 0;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
