import 'package:flutter_test/flutter_test.dart';
import 'package:medi_vault/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    final Map<String, dynamic> patientJson = {
      'id': 'user123',
      'name': 'Jane Doe',
      'email': 'jane@example.com',
      'role': 'patient',
    };

    final Map<String, dynamic> doctorJson = {
      'id': 'doc456',
      'name': 'Dr. Smith',
      'email': 'smith@hospital.com',
      'role': 'doctor',
    };

    group('fromJson', () {
      test('parses all fields for a patient', () {
        final user = UserModel.fromJson(patientJson);

        expect(user.id, 'user123');
        expect(user.name, 'Jane Doe');
        expect(user.email, 'jane@example.com');
        expect(user.role, 'patient');
      });

      test('parses all fields for a doctor', () {
        final user = UserModel.fromJson(doctorJson);

        expect(user.id, 'doc456');
        expect(user.name, 'Dr. Smith');
        expect(user.email, 'smith@hospital.com');
        expect(user.role, 'doctor');
      });

      test('uses empty string defaults for missing fields', () {
        final user = UserModel.fromJson({});

        expect(user.id, '');
        expect(user.name, '');
        expect(user.email, '');
        expect(user.role, '');
      });
    });

    group('isPatient', () {
      test('returns true when role is patient', () {
        final user = UserModel.fromJson(patientJson);
        expect(user.isPatient, true);
      });

      test('returns false when role is doctor', () {
        final user = UserModel.fromJson(doctorJson);
        expect(user.isPatient, false);
      });

      test('returns false when role is empty', () {
        final user = UserModel.fromJson({});
        expect(user.isPatient, false);
      });
    });

    group('isDoctor', () {
      test('returns true when role is doctor', () {
        final user = UserModel.fromJson(doctorJson);
        expect(user.isDoctor, true);
      });

      test('returns false when role is patient', () {
        final user = UserModel.fromJson(patientJson);
        expect(user.isDoctor, false);
      });

      test('returns false when role is empty', () {
        final user = UserModel.fromJson({});
        expect(user.isDoctor, false);
      });
    });
  });
}
