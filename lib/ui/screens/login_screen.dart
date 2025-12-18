import 'package:ecoins/core/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && mounted) {
        _checkRoleAndNavigate();
      }
    });
  }

  Future<void> _checkRoleAndNavigate() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Prevent double navigation if already loading or disposed
    // (Managed by go_router effectively, but we add a small delay or check mounted)

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      final role = data?['role'] as String? ?? 'user';

      if (role == 'user') {
        context.go('/home');
      } else {
        // Brand trying to log in as user
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('This account is a Brand. Please use the Brand Portal.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Role check error: $e');
      // If error, safeguard by staying or letting through?
      // For now, let through as user if unsure, but usually this means network error.
      // Better to show error.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error verifying account credentials.')),
        );
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? 'http://localhost:8080'
            : 'io.supabase.ecoins://login-callback',
      );
      // Navigation handled by auth listener
    } catch (error) {
      debugPrint('Google Sign In Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Google Sign-In failed'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _githubSignIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: kIsWeb ? null : 'io.supabase.ecoins://login-callback',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('GitHub Sign In Error: $error'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Please sign in.')),
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        // Navigation handled by auth listener
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
          const SnackBar(
              content: Text('Unexpected error occurred'),
              backgroundColor: Colors.red),
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
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF10221c) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subTextColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB);
    final inputFillColor = isDark ? const Color(0xFF1f2937) : Colors.white;

    final Size screenSize = MediaQuery.of(context).size;
    // Breakpoint for "Desktop"/"Tablet" view
    final bool isLargeScreen = screenSize.width > 900;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // Left Side - Image (Only on Large Screens)
          if (isLargeScreen)
            Expanded(
              flex: 1, // 50% width
              child: Container(
                color: const Color(0xFFf3f4f6),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAIVqL7RX69cpTXvqZMeU6zUc3fgIpnxIw4HbF4I3p0QQrPIvyDAtkPNvhwt8DgyITPun95jROGhMKI3uSyHpgKVLepRAmcp_T7QuMOANcoDGsMwFSJz9KoiYbzsTrFyUyT4EwHlyGLN_DJLejljSP8BzfNi8NEuqEF22wFGUSMpYuD4_sLq90KZx2rN4-rcCn_837envwyV2v39_ke-Xf-J2XC_i8m5wpoDUo3PgEiD0Yl9EBnp2VJk_7OpI07H1Zb50ptQhoOOw0', // Plant coins image
                      fit: BoxFit.cover,
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.1),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 40,
                      right: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Turn your habits into\nrewards.',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Join the community making a difference.',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Right Side - Form
          Expanded(
            flex: 1,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Mobile-only logo/header logic could go here, but keeping it clean

                          // Header
                          Text(
                            _isSignUp ? 'Create an account' : 'Welcome back',
                            style: GoogleFonts.inter(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isSignUp
                                ? 'Start your eco-journey today.'
                                : 'Please enter your details to sign in.',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: subTextColor,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Social Logins
                          _SocialButton(
                            icon: Icons.g_mobiledata, // Or custom Google SVG
                            label: 'Continue with Google',
                            onPressed: _googleSignIn,
                            isDark: isDark,
                            textColor: textColor,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 12),
                          _SocialButton(
                            icon: FontAwesomeIcons.github,
                            label: 'Continue with GitHub',
                            onPressed: _githubSignIn,
                            isDark: isDark,
                            textColor: textColor,
                            borderColor: borderColor,
                            iconSize: 20,
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(child: Divider(color: borderColor)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: subTextColor,
                                        fontWeight: FontWeight.w500)),
                              ),
                              Expanded(child: Divider(color: borderColor)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Inputs
                          _Label(text: 'Email', color: textColor),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            style: GoogleFonts.inter(color: textColor),
                            validator: (val) => (val == null ||
                                    val.isEmpty ||
                                    !val.contains('@'))
                                ? 'Invalid email'
                                : null,
                            decoration: _inputDecoration(
                                hint: 'Enter your email',
                                isDark: isDark,
                                borderColor: borderColor,
                                fillColor: inputFillColor,
                                subTextColor: subTextColor),
                          ),

                          const SizedBox(height: 20),

                          _Label(text: 'Password', color: textColor),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            style: GoogleFonts.inter(color: textColor),
                            obscureText: !_isPasswordVisible,
                            validator: (val) => (val == null || val.length < 6)
                                ? 'Min 6 chars'
                                : null,
                            decoration: _inputDecoration(
                              hint: '••••••••',
                              isDark: isDark,
                              borderColor: borderColor,
                              fillColor: inputFillColor,
                              subTextColor: subTextColor,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: subTextColor,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Remember Me
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: const Color(0xFF10b77f),
                                      side: BorderSide(color: subTextColor),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      onChanged: (val) => setState(
                                          () => _rememberMe = val ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: GoogleFonts.inter(
                                        fontSize: 14, color: subTextColor),
                                  ),
                                ],
                              ),

                              if (!_isSignUp)
                                TextButton(
                                  onPressed: () {}, // TODO: Forgot Password
                                  style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap),
                                  child: Text(
                                    'Forgot password',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF10b77f),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10b77f),
                              foregroundColor: const Color(0xFF11221c),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _isSignUp ? 'Sign up' : 'Log in',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUp
                                    ? 'Already have an account? '
                                    : "Don't have an account? ",
                                style: GoogleFonts.inter(
                                    color: subTextColor, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _isSignUp = !_isSignUp),
                                child: Text(
                                  _isSignUp ? 'Log in' : 'Sign up',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF10b77f),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    required Color borderColor,
    required Color fillColor,
    required Color subTextColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: subTextColor.withOpacity(0.5)),
      filled: true,
      fillColor: fillColor, // Colors.transparent or subtle fill
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF10b77f), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDark;
  final Color textColor;
  final Color borderColor;
  final double iconSize;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: textColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}
