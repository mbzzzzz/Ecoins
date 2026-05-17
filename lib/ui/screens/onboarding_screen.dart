import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecoins/ui/widgets/scale_button.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

class _EcoInterest {
  final String emoji;
  final String label;
  const _EcoInterest(this.emoji, this.label);
}

const _interests = [
  _EcoInterest('🚗', 'Transport'),
  _EcoInterest('♻️', 'Recycling'),
  _EcoInterest('🌱', 'Food'),
  _EcoInterest('💧', 'Water'),
  _EcoInterest('⚡', 'Energy'),
  _EcoInterest('🛍️', 'Shopping'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Page control
  late final PageController _pageController;
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1 — interests
  final Set<int> _selectedInterests = {};

  // Step 2 — carbon goal
  double _carbonGoal = 5;

  // Step 3 — referral
  final TextEditingController _referralController = TextEditingController();
  String? _referralError;

  final _supabase = Supabase.instance.client;

  // Colors (matching splash)
  static const _primary = Color(0xFF5F9E6E);
  static const _primaryTeal = Color(0xFF6B9AC4);
  static const _primaryLight = Color(0xFFD1FAE5);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _carTripsHint(double kg) {
    // Average car trip emits ~2.3 kg CO₂
    final trips = (kg / 2.3).round();
    if (trips <= 1) return "That's like 1 short car trip";
    return "That's like $trips car trips";
  }

  bool get _canProceed {
    if (_currentStep == 0) return _selectedInterests.isNotEmpty;
    return true; // steps 1 and 2 always allow proceeding
  }

  void _goNext() {
    if (!_canProceed || _isLoading) return;
    HapticFeedback.lightImpact();
    if (_currentStep < 2) {
      final next = _currentStep + 1;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _goBack() {
    if (_currentStep == 0) return;
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      _currentStep - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  // ── Completion logic ───────────────────────────────────────────────────────

  Future<void> _complete() async {
    setState(() {
      _isLoading = true;
      _referralError = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      final code = _referralController.text.trim();

      // If a referral code was entered, look it up first
      if (code.isNotEmpty) {
        final referrer = await _supabase
            .from('profiles')
            .select('id, points_balance')
            .eq('referral_code', code)
            .maybeSingle();

        if (referrer == null) {
          setState(() {
            _referralError = 'Referral code not found. Try again or skip.';
            _isLoading = false;
          });
          return;
        }

        // Add 50 bonus points to the referrer
        final currentPoints = (referrer['points_balance'] as num?)?.toInt() ?? 0;
        await _supabase.from('profiles').update({
          'points_balance': currentPoints + 50,
        }).eq('id', referrer['id'] as String);

        // Mark current user as referred
        await _supabase.from('profiles').update({
          'onboarding_completed': true,
          'referred_by': code,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      } else {
        // No referral code
        await _supabase.from('profiles').update({
          'onboarding_completed': true,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      }

      HapticFeedback.mediumImpact();
      if (mounted) context.go('/home');
    } catch (e) {
      debugPrint('Onboarding error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Gradient background ──────────────────────────────────────────
          _buildBackground(size, isDark),

          // ── Blob decorations (matching splash) ───────────────────────────
          Positioned(
            top: -80,
            left: -80,
            child: _blob(320, _primary.withOpacity(isDark ? 0.18 : 0.10)),
          ),
          Positioned(
            top: size.height * 0.35,
            right: -100,
            child: _blob(280, _primaryTeal.withOpacity(isDark ? 0.10 : 0.13)),
          ),
          Positioned(
            bottom: -80,
            left: size.width / 2 - 180,
            child: _blob(360, _primary.withOpacity(isDark ? 0.08 : 0.06)),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Step dots
                _buildStepIndicator(isDark),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentStep = i),
                    children: [
                      _Step1Interests(
                        selected: _selectedInterests,
                        onToggle: (i) =>
                            setState(() => _selectedInterests.contains(i)
                                ? _selectedInterests.remove(i)
                                : _selectedInterests.add(i)),
                        primary: _primary,
                        primaryLight: _primaryLight,
                        textColor: textColor,
                        isDark: isDark,
                      ),
                      _Step2CarbonGoal(
                        goal: _carbonGoal,
                        onChanged: (v) => setState(() => _carbonGoal = v),
                        hint: _carTripsHint(_carbonGoal),
                        primary: _primary,
                        primaryLight: _primaryLight,
                        textColor: textColor,
                        isDark: isDark,
                      ),
                      _Step3Referral(
                        controller: _referralController,
                        error: _referralError,
                        onSkip: _isLoading ? null : () => _complete(),
                        primary: _primary,
                        primaryLight: _primaryLight,
                        textColor: textColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // ── Bottom nav ────────────────────────────────────────────
                _buildBottomNav(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Background gradient ────────────────────────────────────────────────────

  Widget _buildBackground(Size size, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0D1F12),
                  const Color(0xFF102210),
                  const Color(0xFF0A1A1F),
                ]
              : [
                  const Color(0xFFEDF7F0),
                  const Color(0xFFF3FAF6),
                  const Color(0xFFEAF4F8),
                ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.3,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }

  // ── Step indicator dots ────────────────────────────────────────────────────

  Widget _buildStepIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final isActive = i == _currentStep;
          final isPast = i < _currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: isActive ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: isActive
                  ? _primary
                  : isPast
                      ? _primary.withOpacity(0.5)
                      : (isDark ? Colors.white24 : Colors.grey[300]),
            ),
          );
        }),
      ),
    );
  }

  // ── Bottom navigation ──────────────────────────────────────────────────────

  Widget _buildBottomNav(bool isDark) {
    final isLastStep = _currentStep == 2;
    final buttonLabel = isLastStep ? 'Claim & Finish' : 'Next';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Row(
        children: [
          // Back button
          AnimatedOpacity(
            opacity: _currentStep > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _currentStep > 0 ? _goBack : null,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.7),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white70 : const Color(0xFF2D3748),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Next / Finish button
          Expanded(
            child: ScaleButton(
              onTap: _canProceed && !_isLoading ? _goNext : () {},
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: _canProceed && !_isLoading
                      ? const LinearGradient(
                          colors: [Color(0xFF5F9E6E), Color(0xFF4A8A5A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _canProceed && !_isLoading
                      ? null
                      : (isDark ? Colors.white12 : Colors.grey[200]),
                  boxShadow: _canProceed && !_isLoading
                      ? [
                          BoxShadow(
                            color: _primary.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              buttonLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _canProceed
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white38
                                        : Colors.grey[500]),
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (_canProceed) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1 — Eco Interests ───────────────────────────────────────────────────

class _Step1Interests extends StatelessWidget {
  final Set<int> selected;
  final void Function(int) onToggle;
  final Color primary;
  final Color primaryLight;
  final Color textColor;
  final bool isDark;

  const _Step1Interests({
    required this.selected,
    required this.onToggle,
    required this.primary,
    required this.primaryLight,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Hero icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    primary.withOpacity(0.15),
                    primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text('🌍', style: TextStyle(fontSize: 48)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'What do you care\nabout most?',
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick at least one area to personalize your eco journey.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: textColor.withOpacity(0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Interest chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_interests.length, (i) {
              final interest = _interests[i];
              final isSelected = selected.contains(i);
              return _InterestChip(
                emoji: interest.emoji,
                label: interest.label,
                isSelected: isSelected,
                primary: primary,
                primaryLight: primaryLight,
                isDark: isDark,
                textColor: textColor,
                onTap: () => onToggle(i),
              );
            }),
          ),

          const SizedBox(height: 16),
          if (selected.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Please select at least one interest to continue.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.orange[400],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final Color primary;
  final Color primaryLight;
  final bool isDark;
  final Color textColor;
  final VoidCallback onTap;

  const _InterestChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.primary,
    required this.primaryLight,
    required this.isDark,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: isSelected
              ? primary.withOpacity(0.15)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.7)),
          border: Border.all(
            color: isSelected
                ? primary.withOpacity(0.7)
                : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? primary
                    : textColor.withOpacity(0.75),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, color: primary, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Step 2 — Carbon Goal ─────────────────────────────────────────────────────

class _Step2CarbonGoal extends StatelessWidget {
  final double goal;
  final void Function(double) onChanged;
  final String hint;
  final Color primary;
  final Color primaryLight;
  final Color textColor;
  final bool isDark;

  const _Step2CarbonGoal({
    required this.goal,
    required this.onChanged,
    required this.hint,
    required this.primary,
    required this.primaryLight,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Hero icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    primary.withOpacity(0.15),
                    primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text('🎯', style: TextStyle(fontSize: 48)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Set your weekly\ncarbon goal',
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How much CO₂ do you want to save per week? You can always change this later.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: textColor.withOpacity(0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),

          // Goal display card
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    primary.withOpacity(isDark ? 0.25 : 0.12),
                    primary.withOpacity(isDark ? 0.12 : 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${goal.toStringAsFixed(goal.truncateToDouble() == goal ? 0 : 1)} kg',
                    style: GoogleFonts.outfit(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: primary,
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CO₂ per week',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor.withOpacity(0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: primary,
              inactiveTrackColor:
                  isDark ? Colors.white12 : Colors.grey.shade200,
              thumbColor: primary,
              overlayColor: primary.withOpacity(0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: goal,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: onChanged,
            ),
          ),

          // Min/max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 kg',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: textColor.withOpacity(0.4))),
                Text('20 kg',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: textColor.withOpacity(0.4))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hint
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(hint),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white.withOpacity(0.7),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🚗', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      hint,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3 — Referral Code ───────────────────────────────────────────────────

class _Step3Referral extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final VoidCallback? onSkip;
  final Color primary;
  final Color primaryLight;
  final Color textColor;
  final bool isDark;

  const _Step3Referral({
    required this.controller,
    required this.error,
    required this.onSkip,
    required this.primary,
    required this.primaryLight,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Hero icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    primary.withOpacity(0.15),
                    primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text('🎁', style: TextStyle(fontSize: 48)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Got a referral\ncode?',
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a friend\'s code to give them 50 bonus points as a thank-you.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: textColor.withOpacity(0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Bonus callout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? Colors.amber.withOpacity(0.08)
                  : Colors.amber.shade50,
              border: Border.all(
                color: Colors.amber.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your friend gets +50 points the moment you join with their code.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor.withOpacity(0.75),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Code input
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 3,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. ECO-ABC123',
              hintStyle: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
                color: textColor.withOpacity(0.3),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.75),
              prefixIcon: Icon(Icons.card_giftcard_outlined,
                  color: primary.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primary, width: 2),
              ),
              errorText: error,
              errorStyle: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.red[400],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Skip button
          Center(
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: textColor.withOpacity(0.45),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: Text(
                'Skip — I don\'t have a code',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: textColor.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
