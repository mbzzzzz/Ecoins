import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrandAuthScreen extends StatefulWidget {
  const BrandAuthScreen({super.key});

  @override
  State<BrandAuthScreen> createState() => _BrandAuthScreenState();
}

class _BrandAuthScreenState extends State<BrandAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _supabase = Supabase.instance.client;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw const AuthException('Please fill in all fields');
      }

      if (_isLogin) {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        // Strict Role Check
        if (!mounted) return;
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final profileToCheck = await _supabase
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();

          final role = profileToCheck?['role'] as String? ?? 'user';

          if (role == 'user') {
            // Auto-upgrade user to brand_admin for seamless onboarding
            await _supabase
                .from('profiles')
                .update({'role': 'brand_admin'}).eq('id', user.id);
          }

          // Role is valid (brand_admin or maybe null/admin), check brand existence
          final brandData = await _supabase
              .from('brands')
              .select()
              .eq('owner_user_id', user.id)
              .maybeSingle();

          if (brandData == null) {
            // No brand found, stay on dashboard which will show onboarding
            if (mounted) context.go('/brand-dashboard');
          } else {
            // Brand exists, go to dashboard
            if (mounted) context.go('/brand-dashboard');
          }
        }
      } else {
        // Sign up
        await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'role': 'brand_admin'
          }, // Ensure enum match (was 'brand', enum is 'brand_admin')
        );

        // After signup, redirect to brand portal for onboarding
        if (!mounted) return;
        context.go('/brand-dashboard');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error in brand auth: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.eco, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isLogin ? 'Brand Portal' : 'Join as a Brand',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Access campaigns, widgets and analytics for your sustainable brand.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : AppTheme.textSub,
                ),
              ),
              const SizedBox(height: 24),

              // Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _isLogin
                                ? (isDark ? AppTheme.surfaceDark : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Log in',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: _isLogin
                                  ? AppTheme.primaryGreen
                                  : (isDark
                                      ? Colors.grey[400]
                                      : AppTheme.textSub),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: !_isLogin
                                ? (isDark ? AppTheme.surfaceDark : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Sign up',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: !_isLogin
                                  ? AppTheme.primaryGreen
                                  : (isDark
                                      ? Colors.grey[400]
                                      : AppTheme.textSub),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Email
              Text(
                'Email address',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: isDark ? Colors.grey[200] : Colors.black),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline),
                  hintText: 'name@brand.com',
                ),
              ),
              const SizedBox(height: 16),

              // Password
              Text(
                'Password',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: isDark ? Colors.grey[200] : Colors.black),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          _isLogin
                              ? 'Enter Brand Portal'
                              : 'Create Brand Account',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
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
