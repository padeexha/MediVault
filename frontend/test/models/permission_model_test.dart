import 'package:flutter_test/flutter_test.dart';
import 'package:medi_vault/data/models/permission_model.dart';

void main() {
  group('PermissionModel', () {
    final Map<String, dynamic> fullJson = {
      '_id': 'perm001',
      'patient_id': 'pat123',
      'provider_id': 'doc456',
      'scope_type': 'all',
      'record_id': null,
      'shared_category': null,
      'access_status': 'granted',
      'granted_at': '2025-04-01T09:00:00.000Z',
      'revoked_at': null,
      'expires_at': null,
    };

    group('fromJson', () {
      test('parses all required fields', () {
        // fullJson has scope_type: 'all' which is the simplest case
        final perm = PermissionModel.fromJson(fullJson);

        expect(perm.id, 'perm001');
        expect(perm.patientId, 'pat123');
        expect(perm.providerId, 'doc456');
        expect(perm.scopeType, 'all');
        expect(perm.accessStatus, 'granted');
        expect(perm.grantedAt, DateTime.parse('2025-04-01T09:00:00.000Z'));
      });

      test('optional fields are null when absent', () {
        final perm = PermissionModel.fromJson(fullJson);

        expect(perm.recordId, isNull);
        expect(perm.sharedCategory, isNull);
        expect(perm.revokedAt, isNull);
        expect(perm.expiresAt, isNull);
      });

      test('parses category-scoped permission', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['scope_type'] = 'category';
        json['shared_category'] = 'lab_report';
        final perm = PermissionModel.fromJson(json);

        expect(perm.scopeType, 'category');
        expect(perm.sharedCategory, 'lab_report');
      });

      test('parses revoked_at when present', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['revoked_at'] = '2025-05-01T12:00:00.000Z';
        final perm = PermissionModel.fromJson(json);

        expect(perm.revokedAt, DateTime.parse('2025-05-01T12:00:00.000Z'));
      });

      test('parses expires_at when present', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['expires_at'] = '2025-12-31T23:59:00.000Z';
        final perm = PermissionModel.fromJson(json);

        expect(perm.expiresAt, DateTime.parse('2025-12-31T23:59:00.000Z'));
      });

      test('scopeType defaults to all when missing', () {
        // 'all' is the safest default - the UI should show full access if the server
        // somehow returns a permission record without a scope
        final json = Map<String, dynamic>.from(fullJson)..remove('scope_type');
        final perm = PermissionModel.fromJson(json);

        expect(perm.scopeType, 'all');
      });

      test('accessStatus defaults to granted when missing', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('access_status');
        final perm = PermissionModel.fromJson(json);

        expect(perm.accessStatus, 'granted');
      });
    });

    group('isGranted', () {
      test('returns true when access_status is granted', () {
        final perm = PermissionModel.fromJson(fullJson);
        expect(perm.isGranted, true);
      });

      test('returns false when access_status is revoked', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['access_status'] = 'revoked';
        final perm = PermissionModel.fromJson(json);
        expect(perm.isGranted, false);
      });

      test('returns false when access_status is expired', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['access_status'] = 'expired';
        final perm = PermissionModel.fromJson(json);
        expect(perm.isGranted, false);
      });
    });
  });
}
