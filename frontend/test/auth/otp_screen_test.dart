import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/features/auth/otp_screen.dart';

const String _testEmail = 'user@example.com';

Widget _buildTestApp({String? role}) {
  // wrap in MaterialApp so Navigator and theme are available
  return MaterialApp(
    home: OtpScreen(email: _testEmail, role: role),
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

  group('OtpScreen UI', () {
    testWidgets('displays the email address passed as argument', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text(_testEmail), findsOneWidget);
      await _drainCountdown(tester);
    });

    testWidgets('shows Back to Sign In button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // email-link flow, so there's a Back to Sign In button instead of Verify
      expect(find.text('Back to Sign In'), findsOneWidget);
      await _drainCountdown(tester);
    });

    testWidgets('shows countdown timer text initially', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Countdown starts at 60 and shows "Resend email in XX s"
      expect(find.textContaining('Resend email in'), findsOneWidget);
      await _drainCountdown(tester);
    });

    testWidgets('resend link appears after countdown reaches zero',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Drain the 60-second countdown
      await tester.pump(const Duration(seconds: 60));
      await tester.pump(); // one more frame to rebuild

      expect(find.text('Resend verification email'), findsOneWidget);
      expect(find.textContaining('Resend email in'), findsNothing);
    });

    testWidgets('does not use digit input boxes (email-link flow)',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // verification happens via a link in the email, not a typed code,
      // so there should be no text input fields on this screen
      expect(find.byType(TextField), findsNothing);
      await _drainCountdown(tester);
    });
  });
}
