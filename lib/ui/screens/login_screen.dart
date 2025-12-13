import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
<<<<<<< HEAD
// import 'package:google_sign_in/google_sign_in.dart';
=======
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
>>>>>>> 990c220 (feat: Gamified tree growth and AI verification improvements)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && mounted) {
        context.go('/home');
      }
    });
  }

<<<<<<< HEAD
  // Future<void> _googleSignIn() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     // 1. Native Google Sign In
  //     // Ensure you configured SHA-1 in Firebase/Google Cloud Console for Android
  //     // and Info.plist for iOS.
  //     const webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'; // User must replace this
  //     const iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com'; // User must replace this
  //
  //     final GoogleSignIn googleSignIn = GoogleSignIn();
  //     final googleUser = await googleSignIn.signIn();
  //     final googleAuth = await googleUser?.authentication;
  //
  //     if (googleAuth == null) {
  //       throw 'Google Sign-In canceled.';
  //     }
  //
  //     final accessToken = googleAuth.accessToken;
  //     final idToken = googleAuth.idToken;
  //
  //     if (idToken == null) {
  //       throw 'No ID Token found.';
  //     }
  //
  //     // 2. Sign In to Supabase
  //     await Supabase.instance.client.auth.signInWithIdToken(
  //       provider: OAuthProvider.google,
  //       idToken: idToken,
  //       accessToken: accessToken,
  //     );
  //
  //     if (mounted) {
  //       context.go('/home');
  //     }
  //   } catch (error) {
  //      debugPrint('Google Sign In Error: $error');
  //      if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Google Sign-In failed (Check Setup)'), backgroundColor: Colors.red),
  //       );
  //     }
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }
=======
  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      // -----------------------------------------------------------------------
      // TODO: DEVELOPER - Replace these with your actual Client IDs!
      // -----------------------------------------------------------------------
      const String webClientId = '83614823865-t2jfqplkhg4knkof06a860s187q5c0ag.apps.googleusercontent.com'; // Web Required
      const String iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com'; // iOS Optional
      
      // Check for default strings to warn user
      if (kIsWeb && webClientId.startsWith('YOUR_WEB_CLIENT_ID')) {
        throw 'MISSING_WEB_CLIENT_ID';
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? webClientId : iosClientId, // On Android, usually auto-detected
        serverClientId: kIsWeb ? webClientId : null, // Needed for ID Token on Web
      );
      
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;

      if (googleAuth == null) {
        throw 'Google Sign-In canceled.';
      }

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
       debugPrint('Google Sign In Error: $error');
       String errorMessage = 'Google Sign-In failed.';
       
       if (error == 'MISSING_WEB_CLIENT_ID') {
         errorMessage = 'Configuration Error: Missing Web Client ID.\nPlease update login_screen.dart with your Google Cloud Key.';
       } else if (error.toString().contains('DeveloperConsoleNotConfigured')) {
         errorMessage = 'Configuration Error: SHA-1 or Client ID mismatch.\nCheck firebase_options.dart or google-services.json.';
       }

       if (mounted) {
        showDialog(
          context: context, 
          builder: (context) => AlertDialog(
            title: const Text('Authentication Error'),
            content: Text(errorMessage),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
>>>>>>> 990c220 (feat: Gamified tree growth and AI verification improvements)

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
          SnackBar(content: Text('GitHub Sign In Error: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Logic continues via _authStateSubscription when app resumes
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Please sign in.')),
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) context.go('/home');
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
          const SnackBar(content: Text('Unexpected error occurred'), backgroundColor: Colors.red),
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
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(title: Text(_isSignUp ? 'Sign Up' : 'Sign In')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/images/logo.png', width: 120, height: 120, fit: BoxFit.contain),
              // const Icon(Icons.eco, size: 64, color: Color(0xFF10B981)),
              const SizedBox(height: 32),
              Text(
                'Welcome to Ecoins',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isSignUp ? 'Sign Up' : 'Sign In', style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              // OutlinedButton.icon(
              //   onPressed: _isLoading ? null : _googleSignIn,
              //   style: OutlinedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(vertical: 16),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //   ),
              //   icon: const Icon(Icons.g_mobiledata, size: 28), // Or custom asset
              //   label: const Text('Continue with Google'),
              // ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                  });
                },
                child: Text(_isSignUp
                    ? 'Already have an account? Sign In'
                    : 'Don\'t have an account? Sign Up'),
              ),
            ],
          ),
=======
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _isSignUp ? 'Join the Movement' : 'Welcome Back',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
>>>>>>> 990c220 (feat: Gamified tree growth and AI verification improvements)
        ),
        centerTitle: true,
        leading: const SizedBox(), // Hide back button for auth root
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(30),
                    child: Column(
                      children: [
                        Image.asset('assets/images/logo.png', width: 80, height: 80, fit: BoxFit.contain),
                        const SizedBox(height: 16),
                        Text(
                          'Ecoins',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        Text(
                          'Eco-Rewards & Redemptions',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Form
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(24),
                    opacity: 0.15,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isSignUp ? 'Create Account' : 'Sign In',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.email, color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          obscureText: true,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_isSignUp ? 'Sign Up' : 'Sign In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.white24)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            ),
                            const Expanded(child: Divider(color: Colors.white24)),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _googleSignIn,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text('Continue with Google'),
                        ),

                        const SizedBox(height: 16),

                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _githubSignIn,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const FaIcon(FontAwesomeIcons.github, size: 28),
                          label: const Text('Continue with GitHub'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: RichText(
                      text: TextSpan(
                        text: _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                        children: [
                          TextSpan(
                            text: _isSignUp ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
