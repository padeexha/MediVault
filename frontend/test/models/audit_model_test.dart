import 'package:flutter_test/flutter_test.dart';
import 'package:medi_vault/data/models/audit_model.dart';

void main() {
  group('AuditModel', () {
    final Map<String, dynamic> fullJson = {
      '_id': 'audit001',
      'action_type': 'upload',
      'action_status': 'success',
      'action_date': '2025-04-10T08:00:00.000Z',
      'details': 'Uploaded blood test',
      'actor_user_id': {
        'first_name': 'Jane',
        'last_name': 'Doe',
        'role': 'patient',
      },
      'record_id': {
        'title': 'Blood Test Results',
      },
    };

    group('fromJson', () {
      test('parses all fields correctly', () {
        final log = AuditModel.fromJson(fullJson);

        expect(log.id, 'audit001');
        expect(log.actionType, 'upload');
        expect(log.actionStatus, 'success');
        expect(log.actionDate, DateTime.parse('2025-04-10T08:00:00.000Z'));
        expect(log.details, 'Uploaded blood test');
        expect(log.actorName, 'Jane Doe');
        expect(log.actorRole, 'patient');
        expect(log.recordTitle, 'Blood Test Results');
      });

      test('actorName is Unknown when actor_user_id is null', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['actor_user_id'] = null;
        final log = AuditModel.fromJson(json);

        expect(log.actorName, 'Unknown');
      });

      test('actorRole is unknown when actor_user_id is null', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['actor_user_id'] = null;
        final log = AuditModel.fromJson(json);

        expect(log.actorRole, 'unknown');
      });

      test('recordTitle is null when record_id is null', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['record_id'] = null;
        final log = AuditModel.fromJson(json);

        expect(log.recordTitle, isNull);
      });

      test('actionStatus defaults to success when missing', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('action_status');
        final log = AuditModel.fromJson(json);

        expect(log.actionStatus, 'success');
      });

      test('details is null when not present', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('details');
        final log = AuditModel.fromJson(json);

        expect(log.details, isNull);
      });
    });

    group('actionDisplay', () {
      AuditModel makeLog(String actionType) {
        final json = Map<String, dynamic>.from(fullJson);
        json['action_type'] = actionType;
        return AuditModel.fromJson(json);
      }

      test('upload', () => expect(makeLog('upload').actionDisplay, 'Uploaded a record'));
      test('view', () => expect(makeLog('view').actionDisplay, 'Viewed a record'));
      test('download', () => expect(makeLog('download').actionDisplay, 'Downloaded a record'));
      test('delete', () => expect(makeLog('delete').actionDisplay, 'Deleted a record'));
      test('edit', () => expect(makeLog('edit').actionDisplay, 'Edited a record'));
      test('permission_granted', () => expect(makeLog('permission_granted').actionDisplay, 'Granted access'));
      test('permission_revoked', () => expect(makeLog('permission_revoked').actionDisplay, 'Revoked access'));
      test('login', () => expect(makeLog('login').actionDisplay, 'Logged in'));
      test('logout', () => expect(makeLog('logout').actionDisplay, 'Logged out'));
      test('password_reset', () => expect(makeLog('password_reset').actionDisplay, 'Reset password'));

      test('unknown type falls back to the raw action type', () {
        expect(makeLog('custom_action').actionDisplay, 'custom_action');
      });
    });
  });
}
