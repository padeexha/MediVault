import 'package:flutter_test/flutter_test.dart';
import 'package:medi_vault/data/models/record_model.dart';

// Mirror of _RecordListScreenState._filterRecords logic, tested in isolation.
List<RecordModel> filterRecords(
  List<RecordModel> records,
  String searchQuery,
  String selectedCategory,
) {
  return records.where((r) {
    final matchSearch =
        r.title.toLowerCase().contains(searchQuery.toLowerCase());
    final matchCat =
        selectedCategory == 'all' || r.category == selectedCategory;
    return matchSearch && matchCat;
  }).toList();
}

RecordModel _makeRecord(String id, String title, String category) {
  return RecordModel(
    id: id,
    patientId: 'pat1',
    title: title,
    category: category,
    fileName: 'file.pdf',
    fileType: 'application/pdf',
    fileSize: 1024,
    filePath: '/uploads/file.pdf',
    uploadDate: DateTime(2025, 1, 1),
    isDeleted: false,
  );
}

void main() {
  // five records across four categories - enough variety to test all the filter combinations
  final records = [
    _makeRecord('1', 'Blood Test Report', 'lab_report'),
    _makeRecord('2', 'Chest X-Ray', 'radiology'),
    _makeRecord('3', 'Amoxicillin Prescription', 'prescription'),
    _makeRecord('4', 'CBC Blood Panel', 'lab_report'),
    _makeRecord('5', 'Discharge Summary July', 'discharge_summary'),
  ];

  group('Record filter logic', () {
    test('empty query and all category returns all records', () {
      final result = filterRecords(records, '', 'all');
      expect(result.length, 5);
    });

    test('search by title is case-insensitive', () {
      final result = filterRecords(records, 'blood', 'all');
      expect(result.length, 2);
      expect(result.map((r) => r.title),
          containsAll(['Blood Test Report', 'CBC Blood Panel']));
    });

    test('search by title partial match works', () {
      final result = filterRecords(records, 'ray', 'all');
      expect(result.length, 1);
      expect(result.first.title, 'Chest X-Ray');
    });

    test('category filter returns only matching records', () {
      final result = filterRecords(records, '', 'lab_report');
      expect(result.length, 2);
      expect(result.every((r) => r.category == 'lab_report'), true);
    });

    test('combined search and category filter', () {
      // 'blood' matches records 1 and 4, both of which happen to be lab_report
      final result = filterRecords(records, 'blood', 'lab_report');
      expect(result.length, 2);
      expect(result.every((r) => r.category == 'lab_report'), true);
    });

    test('search with no match returns empty list', () {
      final result = filterRecords(records, 'nonexistent', 'all');
      expect(result, isEmpty);
    });

    test('category filter with no match returns empty list', () {
      final result = filterRecords(records, '', 'other');
      expect(result, isEmpty);
    });

    test('search matches across different categories', () {
      final result = filterRecords(records, 'prescription', 'all');
      expect(result.length, 1);
      expect(result.first.category, 'prescription');
    });

    test('empty records list returns empty result', () {
      final result = filterRecords([], 'blood', 'all');
      expect(result, isEmpty);
    });

    test('category=all ignores category filter entirely', () {
      final result = filterRecords(records, '', 'all');
      expect(result.length, records.length);
    });
  });
}
