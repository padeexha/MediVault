import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/features/auth/email_verification_screen.dart';

const String _testEmail = 'user@example.com';

Widget _buildTestApp({String? role}) {
  return MaterialApp(
    home: EmailVerificationScreen(email: _testEmail, role: role),
  );
}

// Advance fake clock enough to drain the 60-second countdown timer so
// no pending timers remain when the test finishes.
Future<void> _drainCountdown(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 61));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EmailVerificationScreen UI', () {
    testWidgets('displays the email address passed as argument', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text(_testEmail), findsOneWidget);
      await _drainCountdown(tester);
    });

    testWidgets('shows Back to Sign In button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Back to Sign In'), findsOneWidget);
      await _drainCountdown(tester);
    });

    testWidgets('shows resend countdown text immediately after screen opens', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.textContaining('Resend email in'), findsOneWidget);
      await _drainCountdown(tester);
    });

    testWidgets('resend link appears after countdown reaches zero', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.pump(const Duration(seconds: 60));
      await tester.pump();

      expect(find.text('Resend verification email'), findsOneWidget);
      expect(find.textContaining('Resend email in'), findsNothing);
    });

    testWidgets('has no text input fields because verification is done via email link', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byType(TextField), findsNothing);
      await _drainCountdown(tester);
    });
  });
}
