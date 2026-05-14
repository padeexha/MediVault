import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/main.dart';

void main() {
  group('App smoke tests', () {
    testWidgets('App launches and navigates to LoginScreen when no session',
        (tester) async {
      // No stored token or role → should navigate to LoginScreen after splash
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MediVaultApp());
      await tester.pump();

      // Advance past the 2400ms splash delay so _checkSession completes
      await tester.pump(const Duration(milliseconds: 2400));
      await tester.pump();

      // LoginScreen headline should be visible
      expect(find.text('Welcome back,'), findsOneWidget);
    });

    testWidgets('App routes to PatientDashboard when patient session exists',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'token': 'fake-jwt-token',
        'role': 'patient',
      });

      await tester.pumpWidget(const MediVaultApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2400));
      // PatientDashboard makes an API call on init; pump without settle
      // so we don't block on the in-flight HTTP request.
      await tester.pump();

      // LoginScreen-specific text ("Sign in to access...") should not be visible;
      // quick-action tiles unique to PatientDashboard should be present.
      expect(find.text('Sign in to access your secured medical records.'),
          findsNothing);
      expect(find.text('Records'), findsOneWidget);
    });
  });
}
