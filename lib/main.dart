import 'package:ecoins/core/analytics_service.dart';
import 'package:ecoins/core/constants.dart';
import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/screens/home_screen.dart';
import 'package:ecoins/ui/screens/login_screen.dart';
import 'package:ecoins/ui/screens/onboarding_screen.dart';
import 'package:ecoins/ui/screens/profile_screen.dart';
import 'package:ecoins/ui/screens/rewards_screen.dart';
import 'package:ecoins/ui/screens/brand/brand_dashboard_screen.dart';
import 'package:ecoins/ui/screens/brand/brand_auth_screen.dart';
import 'package:ecoins/ui/screens/role_select_screen.dart';
import 'package:ecoins/ui/screens/social_screen.dart';
import 'package:ecoins/ui/screens/splash_screen.dart';
import 'package:ecoins/core/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> _setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission();

  final token = await messaging.getToken();
  if (token != null) {
    debugPrint('FCM Token: $token');
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser != null) {
      await supabase
          .from('profiles')
          .update({'fcm_token': token}).eq('id', supabase.auth.currentUser!.id);
    }

    messaging.onTokenRefresh.listen((newToken) {
      if (supabase.auth.currentUser != null) {
        supabase.from('profiles').update({'fcm_token': newToken}).eq(
            'id', supabase.auth.currentUser!.id);
      }
    });
  }

  // Handle notification tap when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

  // Handle notification tap when app was terminated
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    _handleNotificationTap(initialMessage);
  }
}

void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  final context = _rootNavigatorKey.currentContext;
  if (context == null) return;

  final screen = data['screen'] as String?;
  switch (screen) {
    case 'social':
      context.go('/home', extra: 1); // Community tab
      break;
    case 'rewards':
      context.go('/home', extra: 2);
      break;
    case 'profile':
      context.go('/home', extra: 3);
      break;
    default:
      context.go('/home');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Constants.supabaseUrl,
    anonKey: Constants.supabaseAnonKey,
  );

  // Initialize Firebase (non-fatal — app works without push notifications)
  try {
    await Firebase.initializeApp();
    await _setupFCM();
  } catch (e) {
    debugPrint('Firebase init failed (non-fatal): $e');
  }

  // Initialize Local Notifications
  await NotificationService().initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const EcoinsApp(),
    ),
  );
}

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
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
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/brand-auth',
      builder: (context, state) => const BrandAuthScreen(),
    ),
    GoRoute(
      path: '/brand-dashboard',
      builder: (context, state) => const BrandDashboardScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => MainScaffold(
        initialTab: state.extra is int ? state.extra as int : 0,
      ),
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
  final int initialTab;
  const MainScaffold({super.key, this.initialTab = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      NotificationService().listenToUserNotifications(userId);
    }
    AnalyticsService.instance.track(AnalyticsService.appOpened);
  }

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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
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
