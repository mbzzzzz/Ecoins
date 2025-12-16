import 'package:ecoins/core/constants.dart';
import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/screens/home_screen.dart';
import 'package:ecoins/ui/screens/login_screen.dart';
import 'package:ecoins/ui/screens/profile_screen.dart';
import 'package:ecoins/ui/screens/rewards_screen.dart';
import 'package:ecoins/ui/screens/brand/brand_dashboard_screen.dart';
import 'package:ecoins/ui/screens/role_select_screen.dart';
import 'package:ecoins/ui/screens/social_screen.dart';
import 'package:ecoins/ui/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

Future<void> _setupFCM() async {
  final messaging = FirebaseMessaging.instance;
  
  // Request permission
  await messaging.requestPermission();
  
  // Get Token
  final token = await messaging.getToken();
  if (token != null) {
    debugPrint('FCM Token: $token');
    // Save to Supabase (if user is logged in)
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser != null) {
      await supabase.from('profiles').update({'fcm_token': token}).eq('id', supabase.auth.currentUser!.id);
    }
    
    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) {
      if (supabase.auth.currentUser != null) {
        supabase.from('profiles').update({'fcm_token': newToken}).eq('id', supabase.auth.currentUser!.id);
      }
    });
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Constants.supabaseUrl,
    anonKey: Constants.supabaseAnonKey,
  );

  // Initialize Firebase (Requires google-services.json)
  // await Firebase.initializeApp();
  // _setupFCM();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const EcoinsApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/role-select',
      builder: (context, state) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/brand-auth',
      builder: (context, state) => const LoginScreen(isBrand: true),
    ),
    GoRoute(
      path: '/brand-dashboard',
      builder: (context, state) => const BrandDashboardScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainScaffold(),
    ),
  ],
);

class EcoinsApp extends StatelessWidget {
  const EcoinsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp.router(
          title: 'Ecoins',
          theme: themeNotifier.currentTheme,
          routerConfig: _router,
        );
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    SocialScreen(),
    RewardsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
