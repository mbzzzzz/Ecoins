import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

/// A reusable card that displays the user's referral code with copy actions.
///
/// Renders a green-gradient card with:
///   - "Invite Friends" heading
///   - A short description of the referral incentive
///   - Large monospace display of [referralCode]
///   - "Copy Code" and "Share" buttons (both copy to clipboard)
class ReferralCard extends StatelessWidget {
  /// The referral code to display, e.g. "ECO-AB12CD34".
  final String referralCode;

  const ReferralCard({
    super.key,
    required this.referralCode,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: referralCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryDark,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _shareCode(BuildContext context) async {
    // Copies the full invite message to clipboard so the user can paste it
    // anywhere — no additional package dependency required.
    const message =
        'Join me on Ecoins and earn rewards for eco-friendly actions! '
        'Use my referral code and we both get 50 bonus points when you join.';
    await Clipboard.setData(
      ClipboardData(text: '$message\n\nCode: $referralCode'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share message copied — paste it anywhere!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryDark,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Slightly adjust gradient end colour for dark mode so the card still pops
    // against a dark scaffold background.
    final gradientEnd =
        isDark ? const Color(0xFF065F46) : AppTheme.primaryDark; // Emerald 800 / 700

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Heading row ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Invite Friends',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Description ────────────────────────────────────────────────────
          Text(
            'Share your code and both get 50 bonus points when they join',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          // ── Referral code display ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              referralCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Courier',          // monospace
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Action buttons ─────────────────────────────────────────────────
          Row(
            children: [
              // Copy Code
              Expanded(
                child: _ActionButton(
                  label: 'Copy Code',
                  icon: Icons.copy_rounded,
                  onTap: () => _copyToClipboard(context),
                  filled: true,
                ),
              ),
              const SizedBox(width: 10),
              // Share
              Expanded(
                child: _ActionButton(
                  label: 'Share',
                  icon: Icons.ios_share_rounded,
                  onTap: () => _shareCode(context),
                  filled: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helper widget
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        filled ? Colors.white : Colors.white.withOpacity(0.15);
    final fgColor =
        filled ? AppTheme.primaryDark : Colors.white;
    final borderColor =
        filled ? Colors.transparent : Colors.white.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
