import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/features/doctor/doctor_dashboard.dart';

Widget _buildTestApp() {
  return const MaterialApp(home: DoctorDashboard());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'test-token', 'role': 'doctor'});
  });

  group('DoctorDashboard UI', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      expect(find.byType(DoctorDashboard), findsOneWidget);
    });

    testWidgets('renders the logo image in the app bar (showLogo=true)', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      // DoctorDashboard uses showLogo: true so the AppBar shows an Image, not a Text title
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('shows a Scaffold', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has an edit profile action button in the app bar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      // quick-access edit profile is in the app bar rather than buried in a menu
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('has a logout action button in the app bar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });
}
