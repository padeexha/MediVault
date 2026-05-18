import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/features/auth/register_screen.dart';

Widget _buildTestApp() {
  return const MaterialApp(home: RegisterScreen());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RegisterScreen UI', () {
    testWidgets('renders with Patient role selected by default', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Patient'), findsOneWidget);
      expect(find.text('Doctor'), findsOneWidget);
      // "Create Account" appears as both the page heading and the submit button label
      expect(find.text('Create Account'), findsNWidgets(2));
    });

    testWidgets('doctor-specific fields are hidden when Patient role is selected',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Specialization'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Organisation / Hospital'),
          findsNothing);
    });

    testWidgets('doctor-specific fields appear when Doctor role is tapped',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Doctor'));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Specialization'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Organisation / Hospital'),
          findsOneWidget);
    });

    testWidgets('switching back to Patient hides doctor fields again',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Doctor'));
      await tester.pump();

      // tapping Patient a second time should toggle the extra fields back off
      await tester.tap(find.text('Patient'));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Specialization'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Organisation / Hospital'),
          findsNothing);
    });
  });

  group('RegisterScreen form validation', () {
    testWidgets('shows Required error when first name is empty on submit',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // form is taller than the 600px viewport, scroll to button first
      final submitBtn = find.text('Create Account').last;
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 'Required' appears for first name (and others); at least one must be visible
      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('shows Invalid email error for email without @', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Fill first and last name to get past those validators
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Jane');
      await tester.enterText(fields.at(1), 'Doe');
      await tester.enterText(fields.at(2), 'notanemail');
      await tester.enterText(fields.at(3), 'password123');

      // form is taller than the 600px viewport, scroll to button first
      final submitBtn = find.text('Create Account').last;
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('shows Minimum 8 characters error for short password',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Jane');
      await tester.enterText(fields.at(1), 'Doe');
      await tester.enterText(fields.at(2), 'jane@example.com');
      await tester.enterText(fields.at(3), 'short');

      // form is taller than the 600px viewport, scroll to button first
      final submitBtn = find.text('Create Account').last;
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Minimum 8 characters'), findsOneWidget);
    });
  });
}
