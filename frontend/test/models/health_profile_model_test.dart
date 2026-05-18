import 'package:flutter_test/flutter_test.dart';
import 'package:medi_vault/data/models/health_profile_model.dart';

void main() {
  group('HealthProfileAccessRequest', () {
    // includes both respondedAt scenarios (present and absent) to test null handling
    final Map<String, dynamic> fullJson = {
      '_id': 'req001',
      'doctor_id': 'doc123',
      'doctor_name': 'Dr. Alice Chen',
      'doctor_email': 'alice@hospital.com',
      'status': 'approved',
      'requested_at': '2025-04-01T09:00:00.000Z',
      'responded_at': '2025-04-02T11:00:00.000Z',
    };

    group('fromJson', () {
      test('parses all fields correctly', () {
        final req = HealthProfileAccessRequest.fromJson(fullJson);

        expect(req.id, 'req001');
        expect(req.doctorId, 'doc123');
        expect(req.doctorName, 'Dr. Alice Chen');
        expect(req.doctorEmail, 'alice@hospital.com');
        expect(req.status, 'approved');
        expect(req.requestedAt, DateTime.parse('2025-04-01T09:00:00.000Z'));
        expect(req.respondedAt, DateTime.parse('2025-04-02T11:00:00.000Z'));
      });

      test('respondedAt is null when missing from JSON', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('responded_at');
        final req = HealthProfileAccessRequest.fromJson(json);
        expect(req.respondedAt, isNull);
      });

      test('respondedAt is null when explicitly null in JSON', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['responded_at'] = null;
        final req = HealthProfileAccessRequest.fromJson(json);
        expect(req.respondedAt, isNull);
      });

      test('status defaults to pending when missing', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('status');
        final req = HealthProfileAccessRequest.fromJson(json);
        expect(req.status, 'pending');
      });

      test('uses empty string defaults for missing string fields', () {
        final req = HealthProfileAccessRequest.fromJson({
          'requested_at': '2025-01-01T00:00:00.000Z',
        });
        expect(req.id, '');
        expect(req.doctorId, '');
        expect(req.doctorName, '');
        expect(req.doctorEmail, '');
      });
    });

    group('status helpers', () {
      HealthProfileAccessRequest makeReq(String status) {
        final json = Map<String, dynamic>.from(fullJson);
        json['status'] = status;
        return HealthProfileAccessRequest.fromJson(json);
      }

      test('isPending is true only for pending status', () {
        expect(makeReq('pending').isPending, true);
        expect(makeReq('approved').isPending, false);
        expect(makeReq('rejected').isPending, false);
        expect(makeReq('revoked').isPending, false);
      });

      test('isApproved is true only for approved status', () {
        expect(makeReq('approved').isApproved, true);
        expect(makeReq('pending').isApproved, false);
        expect(makeReq('revoked').isApproved, false);
      });

      test('isRejected is true only for rejected status', () {
        expect(makeReq('rejected').isRejected, true);
        expect(makeReq('approved').isRejected, false);
      });

      test('isRevoked is true only for revoked status', () {
        expect(makeReq('revoked').isRevoked, true);
        expect(makeReq('approved').isRevoked, false);
      });
    });
  });

  group('HealthProfileModel', () {
    final Map<String, dynamic> fullJson = {
      '_id': 'prof001',
      'patient_id': 'user123',
      'full_name': 'Jane Doe',
      'age': 30,
      'gender': 'female',
      'height': '165cm',
      'weight': '60kg',
      'blood_group': 'O+',
      'allergies': ['Penicillin', 'Pollen'],
      'current_medications': ['Metformin'],
      'chronic_conditions': ['Diabetes Type 2'],
      'emergency_contact_name': 'John Doe',
      'emergency_contact_number': '0771234567',
      'access_requests': [
        {
          '_id': 'req1',
          'doctor_id': 'doc1',
          'doctor_name': 'Dr. Smith',
          'doctor_email': 'smith@hospital.com',
          'status': 'approved',
          'requested_at': '2025-04-01T09:00:00.000Z',
        },
        {
          '_id': 'req2',
          'doctor_id': 'doc2',
          'doctor_name': 'Dr. Jones',
          'doctor_email': 'jones@clinic.com',
          'status': 'pending',
          'requested_at': '2025-05-01T09:00:00.000Z',
        },
      ],
    };

    group('fromJson', () {
      test('parses all scalar fields correctly', () {
        final profile = HealthProfileModel.fromJson(fullJson);

        expect(profile.id, 'prof001');
        expect(profile.patientId, 'user123');
        expect(profile.fullName, 'Jane Doe');
        expect(profile.age, 30);
        expect(profile.gender, 'female');
        expect(profile.height, '165cm');
        expect(profile.weight, '60kg');
        expect(profile.bloodGroup, 'O+');
        expect(profile.emergencyContactName, 'John Doe');
        expect(profile.emergencyContactNumber, '0771234567');
      });

      test('parses list fields correctly', () {
        final profile = HealthProfileModel.fromJson(fullJson);

        expect(profile.allergies, ['Penicillin', 'Pollen']);
        expect(profile.currentMedications, ['Metformin']);
        expect(profile.chronicConditions, ['Diabetes Type 2']);
      });

      test('parses access_requests into HealthProfileAccessRequest objects', () {
        final profile = HealthProfileModel.fromJson(fullJson);

        expect(profile.accessRequests, hasLength(2));
        expect(profile.accessRequests[0].doctorName, 'Dr. Smith');
        expect(profile.accessRequests[0].status, 'approved');
        expect(profile.accessRequests[1].doctorName, 'Dr. Jones');
        expect(profile.accessRequests[1].status, 'pending');
      });

      test('id is null when _id is missing', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('_id');
        final profile = HealthProfileModel.fromJson(json);
        expect(profile.id, isNull);
      });

      test('age is null when missing', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('age');
        final profile = HealthProfileModel.fromJson(json);
        expect(profile.age, isNull);
      });

      test('defaults list fields to empty lists when missing', () {
        final profile = HealthProfileModel.fromJson({'patient_id': 'u1'});

        expect(profile.allergies, isEmpty);
        expect(profile.currentMedications, isEmpty);
        expect(profile.chronicConditions, isEmpty);
        expect(profile.accessRequests, isEmpty);
      });

      test('defaults string fields to empty string when missing', () {
        final profile = HealthProfileModel.fromJson({'patient_id': 'u1'});

        expect(profile.fullName, '');
        expect(profile.gender, '');
        expect(profile.height, '');
        expect(profile.weight, '');
        expect(profile.bloodGroup, '');
        expect(profile.emergencyContactName, '');
        expect(profile.emergencyContactNumber, '');
      });
    });

    group('toJson', () {
      test('serialises all fields correctly', () {
        final profile = HealthProfileModel.fromJson(fullJson);
        final json = profile.toJson();

        expect(json['full_name'], 'Jane Doe');
        expect(json['age'], 30);
        expect(json['gender'], 'female');
        expect(json['height'], '165cm');
        expect(json['weight'], '60kg');
        expect(json['blood_group'], 'O+');
        expect(json['allergies'], ['Penicillin', 'Pollen']);
        expect(json['current_medications'], ['Metformin']);
        expect(json['chronic_conditions'], ['Diabetes Type 2']);
        expect(json['emergency_contact_name'], 'John Doe');
        expect(json['emergency_contact_number'], '0771234567');
      });

      test('toJson does not include _id or access_requests (server-managed)', () {
        final profile = HealthProfileModel.fromJson(fullJson);
        final json = profile.toJson();

        // _id and access_requests are server-assigned; sending them back in a
        // PUT/POST body could cause unexpected overwrites on the server side
        expect(json.containsKey('_id'), false);
        expect(json.containsKey('access_requests'), false);
      });
    });

    group('computed properties', () {
      test('pendingRequestCount counts only pending entries', () {
        final profile = HealthProfileModel.fromJson(fullJson);
        // the fixture has 1 approved request and 1 pending request
        expect(profile.pendingRequestCount, 1);
      });

      test('approvedDoctorCount counts only approved entries', () {
        final profile = HealthProfileModel.fromJson(fullJson);
        expect(profile.approvedDoctorCount, 1);
      });

      test('pendingRequestCount is zero when all requests are approved', () {
        final json = Map<String, dynamic>.from(fullJson);
        json['access_requests'] = [
          {
            '_id': 'r1', 'doctor_id': 'd1', 'doctor_name': 'Dr. A',
            'doctor_email': 'a@h.com', 'status': 'approved',
            'requested_at': '2025-01-01T00:00:00.000Z',
          },
        ];
        final profile = HealthProfileModel.fromJson(json);
        expect(profile.pendingRequestCount, 0);
        expect(profile.approvedDoctorCount, 1);
      });

      group('isComplete', () {
        test('returns true when all required fields are filled', () {
          final profile = HealthProfileModel.fromJson(fullJson);
          expect(profile.isComplete, true);
        });

        test('returns false when fullName is empty', () {
          final profile = HealthProfileModel(
            patientId: 'u1', fullName: '', age: 30,
            bloodGroup: 'O+', emergencyContactName: 'Bob',
            emergencyContactNumber: '0771234567',
          );
          expect(profile.isComplete, false);
        });

        test('returns false when age is null', () {
          final profile = HealthProfileModel(
            patientId: 'u1', fullName: 'Jane', age: null,
            bloodGroup: 'O+', emergencyContactName: 'Bob',
            emergencyContactNumber: '0771234567',
          );
          expect(profile.isComplete, false);
        });

        test('returns false when bloodGroup is empty', () {
          final profile = HealthProfileModel(
            patientId: 'u1', fullName: 'Jane', age: 30,
            bloodGroup: '', emergencyContactName: 'Bob',
            emergencyContactNumber: '0771234567',
          );
          expect(profile.isComplete, false);
        });

        test('returns false when emergencyContactName is empty', () {
          final profile = HealthProfileModel(
            patientId: 'u1', fullName: 'Jane', age: 30,
            bloodGroup: 'O+', emergencyContactName: '',
            emergencyContactNumber: '0771234567',
          );
          expect(profile.isComplete, false);
        });

        test('returns false when emergencyContactNumber is empty', () {
          final profile = HealthProfileModel(
            patientId: 'u1', fullName: 'Jane', age: 30,
            bloodGroup: 'O+', emergencyContactName: 'Bob',
            emergencyContactNumber: '',
          );
          expect(profile.isComplete, false);
        });

        test('returns false for a completely empty profile', () {
          final profile = HealthProfileModel(patientId: 'u1');
          expect(profile.isComplete, false);
        });
      });
    });
  });
}
