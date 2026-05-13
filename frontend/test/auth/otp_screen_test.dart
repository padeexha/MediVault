import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/features/auth/otp_screen.dart';

const String _testEmail = 'user@example.com';

Widget _buildTestApp({String? role}) {
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

    testWidgets('renders 6 digit input boxes', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // There are 6 single-character TextField boxes (maxLength: 1)
      expect(find.byType(TextField), findsNWidgets(6));
      await _drainCountdown(tester);
    });

    testWidgets('shows Verify button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Verify'), findsOneWidget);
      await _drainCountdown(tester);
    });

    testWidgets('shows countdown timer text initially', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Countdown starts at 60 and shows "Resend code in XX s"
      expect(find.textContaining('Resend code in'), findsOneWidget);
      await _drainCountdown(tester);
    });

    testWidgets('resend link appears after countdown reaches zero',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Drain the 60-second countdown
      await tester.pump(const Duration(seconds: 60));
      await tester.pump(); // one more frame to rebuild

      expect(find.text('Resend code'), findsOneWidget);
      expect(find.textContaining('Resend code in'), findsNothing);
    });

    testWidgets('tapping Verify with fewer than 6 digits shows snackbar',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Enter only 3 digits
      final boxes = find.byType(TextField);
      await tester.enterText(boxes.at(0), '1');
      await tester.enterText(boxes.at(1), '2');
      await tester.enterText(boxes.at(2), '3');

      await tester.tap(find.text('Verify'));
      await tester.pump();

      expect(
        find.text('Please enter the complete 6-digit code'),
        findsOneWidget,
      );
      await _drainCountdown(tester);
    });
  });
}
