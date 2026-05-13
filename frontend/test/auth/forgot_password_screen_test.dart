import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/features/auth/forgot_password_screen.dart';

Widget _buildTestApp() {
  return const MaterialApp(home: ForgotPasswordScreen());
}

// Use a phone-like surface so the ForgotPasswordScreen content fits without
// overflowing. The default test canvas (800×600) is too short.
Future<void> _setPhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ForgotPasswordScreen UI', () {
    testWidgets('renders form view with email field and Send Reset Link button',
        (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Forgot your password?'), findsOneWidget);
    });

    testWidgets('does not show success view initially', (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Email sent!'), findsNothing);
    });

    testWidgets('shows snackbar when submitting with empty email',
        (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      expect(
        find.text('Please enter your email address'),
        findsOneWidget,
      );
    });

    testWidgets('shows Back to Login button', (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('screen title is Reset Password', (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Reset Password'), findsOneWidget);
    });
  });
}
