import 'package:flutter_test/flutter_test.dart';
import 'package:medi_vault/data/models/record_model.dart';

void main() {
  group('RecordModel', () {
    final Map<String, dynamic> fullJson = {
      '_id': 'rec123',
      'patient_id': 'pat456',
      'title': 'Blood Test Results',
      'category': 'lab_report',
      'notes': 'Annual checkup results',
      'file_name': 'blood_test.pdf',
      'file_type': 'application/pdf',
      'file_size': 204800,
      'file_path': '/uploads/blood_test.pdf',
      'upload_date': '2025-03-15T10:30:00.000Z',
      'is_deleted': false,
    };

    group('fromJson', () {
      test('parses all fields correctly', () {
        final record = RecordModel.fromJson(fullJson);

        expect(record.id, 'rec123');
        expect(record.patientId, 'pat456');
        expect(record.title, 'Blood Test Results');
        expect(record.category, 'lab_report');
        expect(record.notes, 'Annual checkup results');
        expect(record.fileName, 'blood_test.pdf');
        expect(record.fileType, 'application/pdf');
        expect(record.fileSize, 204800);
        expect(record.filePath, '/uploads/blood_test.pdf');
        expect(record.uploadDate, DateTime.parse('2025-03-15T10:30:00.000Z'));
        expect(record.isDeleted, false);
      });

      test('uses empty string defaults for missing string fields', () {
        final record = RecordModel.fromJson({});

        expect(record.id, '');
        expect(record.patientId, '');
        expect(record.title, '');
        expect(record.category, '');
        expect(record.fileName, '');
        expect(record.fileType, '');
        expect(record.filePath, '');
        expect(record.fileSize, 0);
        expect(record.isDeleted, false);
        expect(record.notes, isNull);
      });

      test('notes is null when not present in json', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('notes');
        final record = RecordModel.fromJson(json);
        expect(record.notes, isNull);
      });

      test('notes is null when explicitly set to null', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['notes'] = null;
        final record = RecordModel.fromJson(json);
        expect(record.notes, isNull);
      });

      test('is_deleted defaults to false when missing', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('is_deleted');
        final record = RecordModel.fromJson(json);
        expect(record.isDeleted, false);
      });

      test('is_deleted is true when set', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['is_deleted'] = true;
        final record = RecordModel.fromJson(json);
        expect(record.isDeleted, true);
      });

      test('parses upload_date as DateTime', () {
        final record = RecordModel.fromJson(fullJson);
        expect(record.uploadDate.year, 2025);
        expect(record.uploadDate.month, 3);
        expect(record.uploadDate.day, 15);
      });
    });

    group('categoryDisplay', () {
      RecordModel makeRecord(String category) {
        final json = Map<String, dynamic>.from(fullJson);
        json['category'] = category;
        return RecordModel.fromJson(json);
      }

      test('lab_report displays as Lab Report', () {
        expect(makeRecord('lab_report').categoryDisplay, 'Lab Report');
      });

      test('prescription displays as Prescription', () {
        expect(makeRecord('prescription').categoryDisplay, 'Prescription');
      });

      test('radiology displays as Radiology', () {
        expect(makeRecord('radiology').categoryDisplay, 'Radiology');
      });

      test('discharge_summary displays as Discharge Summary', () {
        expect(makeRecord('discharge_summary').categoryDisplay, 'Discharge Summary');
      });

      test('other displays as Other', () {
        expect(makeRecord('other').categoryDisplay, 'Other');
      });

      test('unknown category falls back to Other', () {
        expect(makeRecord('unknown_type').categoryDisplay, 'Other');
      });

      test('empty string category falls back to Other', () {
        expect(makeRecord('').categoryDisplay, 'Other');
      });
    });
  });
}
