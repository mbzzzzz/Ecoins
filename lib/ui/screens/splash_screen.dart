import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _redirect();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    // Artificial delay to show the splash screen animations
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      context.go('/home');
    } else {
      context.go('/role-select');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors from CSS
    const primary = Color(0xFF5F9E6E);
    const primaryTeal = Color(0xFF6B9AC4);
    const backgroundLight = Color(0xFFf6f8f6);
    const backgroundDark = Color(0xFF102210);
    const brandDark = Color(0xFF2D3748);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? backgroundDark : backgroundLight;
    final textColor = isDark ? Colors.white : brandDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Blobs
            // 1. Top-Left Blob
            Positioned(
              top: -96, // -24rem
              left: -96,
              child: Container(
                width: 384, // 96rem
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withOpacity(isDark ? 0.2 : 0.1),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(isDark ? 0.2 : 0.1),
                        blurRadius: 100,
                        spreadRadius: 50,
                      )
                    ],
                  ),
                ),
              ),
            ),
            // 2. Middle-Right Blob
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 160,
              right: -128,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryTeal.withOpacity(isDark ? 0.1 : 0.15),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryTeal.withOpacity(isDark ? 0.1 : 0.15),
                        blurRadius: 80,
                        spreadRadius: 40,
                      )
                    ],
                  ),
                ),
              ),
            ),
            // 3. Bottom-Center Blob
            Positioned(
              bottom: -96,
              left: MediaQuery.of(context).size.width / 2 - 250,
              child: Container(
                width: 500, // 500px in CSS
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      primary.withOpacity(isDark ? 0.1 : 0.05),
                      Colors.transparent
                    ],
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(isDark ? 0.1 : 0.05),
                        blurRadius: 100,
                        spreadRadius: 20,
                      )
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // Center Content
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Opacity(
                                  opacity: isDark
                                      ? 0.95
                                      : 1.0, // Slight opacity animation handled by controller if needed, but fixed here
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo Image
                                Image.asset(
                                  'assets/images/icon.png',
                                  width: 120, // Adjust size as needed
                                  height: 120,
                                ),
                                const SizedBox(height: 16),
                                // Gradient Text Title
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primary,
                                      primaryTeal,
                                      primary,
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Ecoins',
                                    style: GoogleFonts.outfit(
                                      fontSize: 64, // ~7xl/8xl
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                      color: Colors.white, // Required for mask
                                      letterSpacing: -2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Eco-Rewards & Redemptions',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: textColor.withOpacity(0.7),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                                child: Text(
                                  'LOADING ASSETS',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: primary,
                                    letterSpacing: 1.5, // tracking-widest
                                  ),
                                ),
                              ),
                              // Loading Bar
                              Container(
                                height: 6, // h-1.5
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Stack(
                                      children: [
                                        // Animated Bar
                                        // Simple pulse animation for width or position
                                        // The CSS uses a width of 45% and animate-pulse
                                        // We'll mimic a static 45% bar with gradient for now
                                        AnimatedBuilder(
                                          animation: _progressAnimation,
                                          builder: (context, child) {
                                            return Container(
                                              width: constraints.maxWidth *
                                                  _progressAnimation.value,
                                              height: double.infinity,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    primary,
                                                    primaryTeal
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Earn while you save the planet',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: textColor.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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
}
