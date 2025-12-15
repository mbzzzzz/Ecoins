import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  int _currentStep = 0;
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      // Update profile with onboarding data
      await _supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppTheme.primaryGreen
                            : (isDark ? Colors.grey[800] : Colors.grey[300]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: PageController(initialPage: _currentStep),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildWelcomeStep(isDark),
                  _buildNameStep(isDark),
                  _buildCompleteStep(isDark),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_currentStep < 2) {
                              setState(() => _currentStep++);
                            } else {
                              _completeOnboarding();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            _currentStep < 2 ? 'Next' : 'Get Started',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: AppTheme.primaryGreen, size: 64),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Ecoins!',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textMain,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s set up your profile so you can start earning rewards for your eco-friendly actions.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : AppTheme.textSub,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What should we call you?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textMain,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            style: TextStyle(color: isDark ? Colors.white : AppTheme.textMain),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Bio (Optional)',
              hintText: 'Tell us about your eco journey...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            style: TextStyle(color: isDark ? Colors.white : AppTheme.textMain),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 64),
          ),
          const SizedBox(height: 32),
          Text(
            'You\'re all set!',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textMain,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Start logging activities to earn Ecoins and grow your impact tree.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : AppTheme.textSub,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

