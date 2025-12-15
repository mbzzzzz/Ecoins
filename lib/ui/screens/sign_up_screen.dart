import 'package:ecoins/core/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();

      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw const AuthException('Please fill in all fields');
      }

      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      // Create profile if user exists
      if (res.user != null) {
        await _supabase.from('profiles').insert({
          'id': res.user!.id,
          'full_name': name,
          'points_balance': 0,
          'carbon_saved_kg': 0.0,
        });
      }

      if (mounted) {
        // Navigate to onboarding for new users
        context.go('/onboarding');
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? 'http://localhost:8080' : null,
      );
      // Profile creation and onboarding check handled in login screen's auth state listener
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: $error'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }
  
   Future<void> _appleSignIn() async {
     // Apple Sign In logic placeholder
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apple Sign-In not fully configured')),
        );
      }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               const SizedBox(height: 20),
              // Header Image
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuB3ein4_E2NpfSZMjfa2ZFacUyYJD3cfOhr5f_Ys8A7KnD_a_xSn19jZ4IciAxzxN_uhX7a50u8wiAx41E2cgLw2QaHhnTIl3eZevHq4dJJPHOl2-XJfIVkvATi-b0OiTjKfcERGVP4JJ_HQrCqYFf3q0Sll_uWRKqUnfsCIll8376kEuvaDSR_RFNmM34QAfAA_P-AfcL2-C29I64O_g3FxPXcRpP1B5BGXybwVwgGJg8W2j_ofUMVNe8_0W2Wf_LogtBsgmP5nnc"),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.bottomLeft,
                    child: const Row(
                      children: [
                        Icon(Icons.eco, color: AppTheme.primaryGreen),
                         SizedBox(width: 8),
                        Text(
                          'Ecoins',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Start earning Ecoins today.',
                textAlign: TextAlign.center,
                style: GoogleFonts.splineSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0D1B0D),
                  height: 1.1,
                ),
              ),
               const SizedBox(height: 8),
               Text(
                'Join thousands making a difference for the planet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: isDark ? const Color(0xFFA0BCA0) : const Color(0xFF405640),
                ),
              ),

              const SizedBox(height: 24),

              // Form
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 6),
                    child: Text('Full Name', style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[200] : const Color(0xFF0D1B0D)
                    )),
                  ),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                       hintText: 'e.g. Alex Johnson',
                       fillColor: isDark ? const Color(0xFF1A2E1A) : Colors.white,
                       enabledBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(999), 
                         borderSide: BorderSide(color: isDark ? const Color(0xFF2A452A) : const Color(0xFFCFE7CF))
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(999), 
                         borderSide: const BorderSide(color: AppTheme.primaryGreen)
                       ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 6),
                    child: Text('Email Address', style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[200] : const Color(0xFF0D1B0D)
                    )),
                  ),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                     decoration: InputDecoration(
                       hintText: 'name@example.com',
                       fillColor: isDark ? const Color(0xFF1A2E1A) : Colors.white,
                       enabledBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(999), 
                         borderSide: BorderSide(color: isDark ? const Color(0xFF2A452A) : const Color(0xFFCFE7CF))
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(999), 
                         borderSide: const BorderSide(color: AppTheme.primaryGreen)
                       ),
                    ),
                  ),

                   const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 6),
                    child: Text('Password', style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[200] : const Color(0xFF0D1B0D)
                    )),
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                     decoration: InputDecoration(
                       hintText: 'Min. 8 characters',
                       fillColor: isDark ? const Color(0xFF1A2E1A) : Colors.white,
                       enabledBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(999), 
                         borderSide: BorderSide(color: isDark ? const Color(0xFF2A452A) : const Color(0xFFCFE7CF))
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(999), 
                         borderSide: const BorderSide(color: AppTheme.primaryGreen)
                       ),
                       suffixIcon: IconButton(
                         icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                         onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                         color: isDark ? const Color(0xFF88A888) : const Color(0xFF405640),
                       )
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const SizedBox(width: 8),
                   const Icon(Icons.verified_user, color: AppTheme.primaryGreen, size: 18),
                   const SizedBox(width: 8),
                   Text('100% Free & Secure Data', style: TextStyle(
                     fontSize: 12, 
                     fontWeight: FontWeight.w500,
                     color: isDark ? const Color(0xFFA0BCA0) : const Color(0xFF405640)
                   )),
                 ],
              ),

              const SizedBox(height: 16),
              
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: const Color(0xFF052905),
                    elevation: 4,
                    shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                    : const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),
              
              Row(
                children: [
                   Expanded(child: Divider(color: isDark ? const Color(0xFF2A452A) : const Color(0xFFCFE7CF))),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     child: Text('Or continue with', style: TextStyle(
                       fontSize: 14,
                       color: isDark ? const Color(0xFFA0BCA0) : const Color(0xFF405640)
                     )),
                   ),
                   Expanded(child: Divider(color: isDark ? const Color(0xFF2A452A) : const Color(0xFFCFE7CF))),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _googleSignIn,
                        icon: const Icon(FontAwesomeIcons.google, size: 20),
                        label: Text('Google', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0D1B0D))),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? const Color(0xFF2A452A) : const Color(0xFFCFE7CF)),
                          backgroundColor: isDark ? const Color(0xFF1A2E1A) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                    ),
                  ),
                   const SizedBox(width: 12),
                   Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _appleSignIn,
                        icon: const Icon(FontAwesomeIcons.apple, size: 22),
                        label: Text('Apple', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0D1B0D))),
                         style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? const Color(0xFF2A452A) : const Color(0xFFCFE7CF)),
                           backgroundColor: isDark ? const Color(0xFF1A2E1A) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
               const SizedBox(height: 32),
               
               Center(
                 child: GestureDetector(
                   onTap: () => context.go('/login'),
                   child: RichText(
                     text: TextSpan(
                       style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFFA0BCA0) : const Color(0xFF405640)),
                       children: [
                         const TextSpan(text: 'Already a member? '),
                         TextSpan(
                           text: 'Log In',
                           style: TextStyle(
                             color: isDark ? AppTheme.primaryGreen : const Color(0xFF0D1B0D),
                             fontWeight: FontWeight.bold,
                             decoration: TextDecoration.underline
                           ),
                         ),
                       ],
                     ),
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
