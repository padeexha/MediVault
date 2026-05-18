import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/features/doctor/shared_records_screen.dart';

Widget _buildTestApp() {
  return const MaterialApp(home: SharedRecordsScreen());
}

void main() {
  setUp(() {
    // role must be 'doctor' since this screen is only reachable from the doctor dashboard
    SharedPreferences.setMockInitialValues({'token': 'test-token', 'role': 'doctor'});
  });

  group('SharedRecordsScreen UI', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      expect(find.byType(SharedRecordsScreen), findsOneWidget);
    });

    testWidgets('renders the Shared Records app bar title', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      expect(find.text('Shared Records'), findsOneWidget);
    });

    testWidgets('shows a Scaffold with an AppBar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
