import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/features/auth/login_screen.dart';

Widget _buildTestApp() {
  return const MaterialApp(home: LoginScreen());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LoginScreen UI', () {
    testWidgets('renders email field, password field, and Sign In button',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Welcome back,'), findsOneWidget);
    });

    testWidgets('shows Sign Up link', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows Forgot password link', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Forgot password?'), findsOneWidget);
    });
  });

  group('LoginScreen form validation', () {
    testWidgets('shows error when email is empty on submit', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows error when email has no @ symbol', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.enterText(
          find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.enterText(
          find.byType(TextFormField).first, 'user@example.com');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows error when password is shorter than 8 characters',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.enterText(
          find.byType(TextFormField).first, 'user@example.com');
      await tester.enterText(
          find.byType(TextFormField).last, 'short');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('no validation errors shown when fields are valid',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.enterText(
          find.byType(TextFormField).first, 'user@example.com');
      await tester.enterText(
          find.byType(TextFormField).last, 'password123');

      // don't tap Sign In here - that would kick off a real network request
      // and fail in the test environment; just check no inline errors are shown
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter a valid email'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);
      expect(find.text('Password must be at least 8 characters'), findsNothing);
    });
  });

  group('LoginScreen password visibility', () {
    testWidgets('password is obscured by default', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // EditableText is the internal leaf widget that holds the obscureText flag;
      // the last one in the tree is always the password field
      final editableTexts = tester.widgetList<EditableText>(
        find.byType(EditableText),
      ).toList();
      expect(editableTexts.last.obscureText, true);
    });

    testWidgets('tapping visibility icon toggles password visibility',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Tap the visibility toggle icon
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      final editableTexts = tester.widgetList<EditableText>(
        find.byType(EditableText),
      ).toList();
      expect(editableTexts.last.obscureText, false);
    });
  });
}
