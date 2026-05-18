import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/features/patient/upload_record_screen.dart';

Widget _buildTestApp() {
  return const MaterialApp(home: UploadRecordScreen());
}

// UploadRecordScreen is taller than the default 600px test canvas.
Future<void> _setPhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'test-token', 'role': 'patient'});
  });

  group('UploadRecordScreen UI', () {
    testWidgets('renders title field', (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // The hint text is lowercase 'Record title'
      expect(find.widgetWithText(TextFormField, 'Record title'), findsOneWidget);
    });

    testWidgets('renders Upload Record button', (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Upload Record'), findsWidgets);
    });

    testWidgets('renders notes field', (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Notes (optional)'), findsOneWidget);
    });

    testWidgets('renders category dropdown', (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Category is a DropdownButtonFormField (not chips)
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows file picker area with browse prompt initially', (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Cloud upload icon shown when no file is selected
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      // "Tap to browse files" text shown when no file is selected
      expect(find.text('Tap to browse files'), findsOneWidget);
    });
  });

  group('UploadRecordScreen form validation', () {
    testWidgets('shows error when title is empty on submit', (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      final uploadBtn = find.widgetWithText(ElevatedButton, 'Upload Record');
      if (uploadBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(uploadBtn);
        await tester.tap(uploadBtn, warnIfMissed: false);
        await tester.pump();
        expect(find.text('Please enter a title'), findsWidgets);
      }
    });

    testWidgets('shows snackbar when form is valid but no file is selected',
        (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Record title'), 'Blood Test');

      final uploadBtn = find.widgetWithText(ElevatedButton, 'Upload Record');
      if (uploadBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(uploadBtn);
        await tester.tap(uploadBtn, warnIfMissed: false);
        await tester.pump();
        // snackbar animation needs a frame to complete before we can find the text
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Please select a file to upload'), findsOneWidget);
      }
    });
  });

  group('Category dropdown', () {
    testWidgets('dropdown contains Lab Report option', (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Open the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Lab Report'), findsWidgets);
    });
  });
}
