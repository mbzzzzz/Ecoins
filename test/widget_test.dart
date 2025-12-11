import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/screens/login_screen.dart';

void main() {
  group('AppTheme Tests', () {
    test('Should return correct primary color', () {
      expect(AppTheme.primaryGreen, const Color(0xFF10B981));
    });

    test('Should generate light theme with correct values', () {
      final theme = AppTheme.lightTheme;
      expect(theme.primaryColor, AppTheme.primaryGreen);
      expect(theme.scaffoldBackgroundColor, AppTheme.background);
      expect(theme.useMaterial3, true);
    });
  });

  group('LoginScreen Tests', () {
    testWidgets('Should render Sign In UI correctly', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ));

      // Verify that "Welcome to Ecoins" is shown
      expect(find.text('Welcome to Ecoins'), findsOneWidget);

      // Verify TextFields exist
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

      // Verify Buttons exist
      // 'Sign In' appears in AppBar and on the ElevatedButton
      expect(find.text('Sign In'), findsAtLeastNWidgets(1)); 
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('Should toggle between Sign In and Sign Up', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ));

      // Initial State: Sign In link is visible
      expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);

      // Tap to switch to Sign Up
      await tester.tap(find.text('Don\'t have an account? Sign Up'));
      await tester.pump();

      // Verify Sign Up State
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
      // The button text should also update (finding 'Sign Up' at least in AppBar and Button)
      expect(find.text('Sign Up'), findsAtLeastNWidgets(1));
    });
  });
}
