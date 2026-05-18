import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/features/patient/permissions_screen.dart';

Widget _buildTestApp() {
  return const MaterialApp(home: PermissionsScreen());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'test-token', 'role': 'patient'});
  });

  group('PermissionsScreen UI', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      expect(find.byType(PermissionsScreen), findsOneWidget);
    });

    testWidgets('renders the Manage Access app bar title', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      expect(find.text('Manage Access'), findsOneWidget);
    });

    testWidgets('has a FloatingActionButton to grant access', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      // the FAB is the entry point for granting a doctor access
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows a Scaffold with an AppBar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
