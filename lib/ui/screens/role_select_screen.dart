import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            // Subtle radial background pattern similar to the mock
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.2,
              colors: [
                Color.fromARGB(20, 16, 183, 127),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            children: [
              // Top bar with logo
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.eco, color: AppTheme.primaryGreen, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'Ecoins',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textMain,
                          ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      // Headline
                      Column(
                        children: [
                          Text(
                            'Welcome to Ecoins',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color:
                                      isDark ? Colors.white : AppTheme.textMain,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'How will you be using the platform today?',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF92C9B7)
                                      : AppTheme.textSub,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Individual card
                      _RoleCard(
                        isPrimary: true,
                        title: 'Individual',
                        subtitle:
                            'Earn rewards for your daily eco-friendly actions.',
                        icon: Icons.person,
                        buttonLabel: 'Continue as Individual',
                        onTap: () => context.go('/login'),
                      ),

                      const SizedBox(height: 16),

                      // Brand card
                      _RoleCard(
                        isPrimary: false,
                        title: 'Brand Partner',
                        subtitle:
                            'Connect with eco-conscious customers.',
                        icon: Icons.storefront,
                        buttonLabel: 'Continue as Brand',
                        onTap: () => context.go('/brand-auth'),
                      ),

                      const Spacer(),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            Text.rich(
                              TextSpan(
                                text: 'Already have an account? ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                children: [
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () => context.go('/login'),
                                      child: Text(
                                        'Log in here',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.primaryGreen,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool isPrimary;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.isPrimary,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isPrimary
        ? AppTheme.primaryGreen
        : (isDark ? Colors.grey[700]! : Colors.grey.shade300);

    // Give the card a fixed height so the internal Row gets finite constraints.
    return SizedBox(
      height: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF19332B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor.withOpacity(isPrimary ? 1 : 0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image-like side
              Container(
                width: 110,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(
                      isPrimary
                          ? 'https://lh3.googleusercontent.com/aida-public/AB6AXuAIVqL7RX69cpTXvqZMeU6zUc3fgIpnxIw4HbF4I3p0QQrPIvyDAtkPNvhwt8DgyITPun95jROGhMKI3uSyHpgKVLepRAmcp_T7QuMOANcoDGsMwFSJz9KoiYbzsTrFyUyT4EwHlyGLN_DJLejljSP8BzfNi8NEuqEF22wFGUSMpYuD4_sLq90KZx2rN4-rcCn_837envwyV2v39_ke-Xf-J2XC_i8m5wpoDUo3PgEiD0Yl9EBnp2VJk_7OpI07H1Zb50ptQhoOOw0'
                          : 'https://lh3.googleusercontent.com/aida-public/AB6AXuDIxePDE8tiI1hmRtKdwHCuAP3KPnyNiA2Zq0lCEaRoCA1M0MYfcxAqXQC5AyaIKWbxmouywXvefoSBL-OZwB_lXbraVOrBFvCb5HEywr_Ut0tO9r-EW1N-CpYfNQ93JQcCEDkJXD1XTsP_BetxxVIVYwHY1O8RLsRor7rlPKYs1yME-WCU1e6I78F_aqmu7YFrMz9R1xwg9Ydwp004uXa24CFh6mR4-0efOAIz7K-Q6ws45THufyVt9iKxPrplNoHr2HCIfJO153k',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.textMain,
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isPrimary
                                  ? AppTheme.primaryGreen.withOpacity(0.12)
                                  : (isDark
                                      ? Colors.white10
                                      : Colors.grey.shade100),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 20,
                              color: isPrimary
                                  ? AppTheme.primaryGreen
                                  : (isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700]),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPrimary
                                ? AppTheme.primaryGreen
                                : Colors.transparent,
                            foregroundColor: isPrimary
                                ? const Color(0xFF11221C)
                                : (isDark
                                    ? Colors.white
                                    : AppTheme.textMain),
                            elevation: 0,
                            side: isPrimary
                                ? BorderSide.none
                                : BorderSide(
                                    color: isDark
                                        ? Colors.grey[600]!
                                        : Colors.grey.shade400,
                                  ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            buttonLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

