import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/features/patient/audit_log_screen.dart';

Widget _buildTestApp() {
  return const MaterialApp(home: AuditLogScreen());
}

void main() {
  setUp(() {
    // audit log screen reads the token to make its API call, so we need a fake one
    SharedPreferences.setMockInitialValues({'token': 'test-token', 'role': 'patient'});
  });

  group('AuditLogScreen UI', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      expect(find.byType(AuditLogScreen), findsOneWidget);
    });

    testWidgets('renders the Audit Log app bar title', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Audit Log'), findsOneWidget);
    });

    testWidgets('shows a Scaffold with an AppBar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
