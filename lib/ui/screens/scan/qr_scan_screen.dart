import 'dart:ui';
import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:vibration/vibration.dart'; // Optional: for haptic feedback if available, or just ignore

class QRScanScreen extends StatefulWidget {
  final bool isBrandMode;
  const QRScanScreen({super.key, this.isBrandMode = false});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Animation for the scanning line
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processCode(String? code) async {
    if (code == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('Scanned Code: $code [BrandMode: ${widget.isBrandMode}]');

      if (widget.isBrandMode) {
        // --- BRAND MODE: Verify User Redemption ---
        final redemption = await _supabase
            .from('redemptions')
            .select('*, offers(title)')
            .eq('promo_code', code)
            .maybeSingle();

        if (redemption == null) throw 'Invalid code.';
        if (redemption['status'] != 'active') {
          throw 'This code has already been used or is expired (Status: ${redemption['status']}).';
        }

        // Mark as redeemed/used
        await _supabase
            .from('redemptions')
            .update({'status': 'used', 'redeemed_at': DateTime.now().toIso8601String()}) // Update timestamp to usage time
            .eq('id', redemption['id']);

        if (mounted) {
           _showSuccessDialog('Validated!', 'Code for "${redemption['offers']['title']}" marked as used.');
        }

      } else {
        // --- USER MODE: Claim New Offer ---
        final offer = await _supabase
            .from('offers')
            .select()
            .eq('discount_code', code)
            .eq('is_active', true)
            .maybeSingle();

        if (offer == null) {
          throw 'Invalid or expired offer code.';
        }

        final user = _supabase.auth.currentUser;
        if (user == null) throw 'User not logged in';

        // Check if already claimed? Maybe allow multiple for now.
        
        // Generate unique validation code for the brand to scan later
        final uniquePromoCode = 'ECO-${DateTime.now().millisecondsSinceEpoch}-${(100 + (code.hashCode % 900))}';

        await _supabase.from('redemptions').insert({
          'user_id': user.id,
          'offer_id': offer['id'],
          'reward_id': offer['id'], 
          'code': code, // The scanned public code (e.g. SUMMER20)
          'promo_code': uniquePromoCode, // The unique private code (e.g. ECO-12345)
          'status': 'active', // Active in wallet, ready to be used
          'carbon_value_snapshot': 10.0, // TODO: Fetch real value?
          'redeemed_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
           _showSuccessDialog('Success!', 'You claimed: ${offer['title']}');
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isProcessing = false);
        });
      }
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.outfit(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Awesome!'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                _processCode(barcode.rawValue);
              }
            },
          ),

          // 2. Overlay (Darkened background with transparent cutout)
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(scanRect: _getScanRect(context)),
            ),
          ),

          // 3. Animated Scan Line
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final rect = _getScanRect(context);
              final dy = rect.top + (rect.height * _animationController.value);
              return Positioned(
                top: dy,
                left: rect.left,
                width: rect.width,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          
          // 4. UI Controls
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGlassButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      Text(
                        'Scan Code',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildGlassButton(
                        icon: Icons.flash_on,
                        onTap: () => _cameraController.toggleTorch(),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Bottom Instructions
                Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Text(
                    'Align QR code within the frame',
                    style: GoogleFonts.inter(
                       color: Colors.white.withOpacity(0.8),
                       fontSize: 14,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Rect _getScanRect(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanSize = size.width * 0.7;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanSize,
      height: scanSize,
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white.withOpacity(0.2),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

// Custom Painter for the dark overlay with cutout
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanRect;

  ScannerOverlayPainter({required this.scanRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
    
    // Draw Corner Borders
    final borderPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
      
    final r = 20.0;
    final l = 30.0; // length of corner line
    
    // Top Left
    canvas.drawPath(Path()..moveTo(scanRect.left, scanRect.top + l)..lineTo(scanRect.left, scanRect.top + r)..quadraticBezierTo(scanRect.left, scanRect.top, scanRect.left + r, scanRect.top)..lineTo(scanRect.left + l, scanRect.top), borderPaint);
    // Top Right
    canvas.drawPath(Path()..moveTo(scanRect.right - l, scanRect.top)..lineTo(scanRect.right - r, scanRect.top)..quadraticBezierTo(scanRect.right, scanRect.top, scanRect.right, scanRect.top + r)..lineTo(scanRect.right, scanRect.top + l), borderPaint);
    // Bottom Left
    canvas.drawPath(Path()..moveTo(scanRect.left, scanRect.bottom - l)..lineTo(scanRect.left, scanRect.bottom - r)..quadraticBezierTo(scanRect.left, scanRect.bottom, scanRect.left + r, scanRect.bottom)..lineTo(scanRect.left + l, scanRect.bottom), borderPaint);
    // Bottom Right
    canvas.drawPath(Path()..moveTo(scanRect.right - l, scanRect.bottom)..lineTo(scanRect.right - r, scanRect.bottom)..quadraticBezierTo(scanRect.right, scanRect.bottom, scanRect.right, scanRect.bottom - r)..lineTo(scanRect.right, scanRect.bottom - l), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
