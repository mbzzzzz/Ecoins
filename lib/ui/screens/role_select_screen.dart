import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF10221c) : const Color(0xFFf6f8f7);
    final surfaceColor = isDark ? const Color(0xFF19332b) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827); // gray-900 equivalent
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563); // gray-400 / gray-600

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Background Pattern (Subtle Radial)
             Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.9, 0.8), // 90% 80%
                    radius: 0.5,
                    colors: [
                      const Color(0xFF10b77f).withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
             Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                 decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.1, 0.2), // 10% 20%
                    radius: 0.5,
                    colors: [
                       const Color(0xFF10b77f).withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.eco, color: Color(0xFF10b77f), size: 32),
                      const SizedBox(width: 8),
                      Text(
                        'Ecoins',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // Headline
                        Text(
                          'Welcome to Ecoins',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'How will you be using the platform today?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDark ? const Color(0xFF92c9b7) : const Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // Individual Card
                        _RoleCard(
                          title: 'Individual',
                          subtitle: 'Earn rewards for your daily eco-friendly actions.',
                          icon: Icons.person,
                          buttonLabel: 'Continue as Individual',
                          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAIVqL7RX69cpTXvqZMeU6zUc3fgIpnxIw4HbF4I3p0QQrPIvyDAtkPNvhwt8DgyITPun95jROGhMKI3uSyHpgKVLepRAmcp_T7QuMOANcoDGsMwFSJz9KoiYbzsTrFyUyT4EwHlyGLN_DJLejljSP8BzfNi8NEuqEF22wFGUSMpYuD4_sLq90KZx2rN4-rcCn_837envwyV2v39_ke-Xf-J2XC_i8m5wpoDUo3PgEiD0Yl9EBnp2VJk_7OpI07H1Zb50ptQhoOOw0',
                          isPrimary: true,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          onTap: () => context.go('/login'),
                        ),

                        const SizedBox(height: 20),

                        // Brand Partner Card
                        _RoleCard(
                          title: 'Brand Partner',
                          subtitle: 'Connect with eco-conscious customers.',
                          icon: Icons.storefront,
                          buttonLabel: 'Continue as Brand',
                          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDIxePDE8tiI1hmRtKdwHCuAP3KPnyNiA2Zq0lCEaRoCA1M0MYfcxAqXQC5AyaIKWbxmouywXvefoSBL-OZwB_lXbraVOrBFvCb5HEywr_Ut0tO9r-EW1N-CpYfNQ93JQcCEDkJXD1XTsP_BetxxVIVYwHY1O8RLsRor7rlPKYs1yME-WCU1e6I78F_aqmu7YFrMz9R1xwg9Ydwp004uXa24CFh6mR4-0efOAIz7K-Q6ws45THufyVt9iKxPrplNoHr2HCIfJO153k',
                          isPrimary: false,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          onTap: () => context.go('/brand-auth'),
                        ),

                        const SizedBox(height: 32),

                        // Footer
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: Text(
                                  'Log in here',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF10b77f),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final String imageUrl;
  final bool isPrimary;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    required this.imageUrl,
    required this.isPrimary,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF10b77f);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isPrimary ? primaryGreen : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          width: isPrimary ? 2 : 1, // Highlight border for primary
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              // Top Highlight Stripe if primary
              if (isPrimary)
                Container(height: 4, width: double.infinity, color: primaryGreen),
              
              IntrinsicHeight( // Use IntrinsicHeight to make Row children adapt
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Section (Left)
                    Expanded(
                      flex: 4, // equivalent to w-1/3 approx if we assume total 12
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                           color: Colors.black.withOpacity(isDark ? 0.3 : 0.0), // dim image slightly in dark mode
                        ),
                      ),
                    ),
                    
                    // Content Section (Right)
                    Expanded(
                      flex: 7, 
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isPrimary ? primaryGreen.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.grey[100]),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 20,
                                    color: isPrimary ? primaryGreen : (isDark ? Colors.grey[300] : Colors.grey[600]),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 13, // text-sm
                                color: subtitleColor,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: isPrimary 
                                ? ElevatedButton(
                                    onPressed: onTap,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      foregroundColor: const Color(0xFF11221c),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16), // Adjusted padding
                                      minimumSize: const Size(0, 40), // h-10
                                    ),
                                    child: Text(
                                      buttonLabel,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  )
                                : OutlinedButton(
                                    onPressed: onTap,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)), // gray-600 / gray-300
                                      foregroundColor: textColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                      minimumSize: const Size(0, 40),
                                    ),
                                    child: Text(
                                      buttonLabel,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
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
            ],
          ),
        ),
      ),
    );
  }
}

