class HealthProfileAccessRequest {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorEmail;
  final String status; // pending | approved | rejected | revoked
  final DateTime requestedAt;
  final DateTime? respondedAt;

  const HealthProfileAccessRequest({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorEmail,
    required this.status,
    required this.requestedAt,
    this.respondedAt,
  });

  factory HealthProfileAccessRequest.fromJson(Map<String, dynamic> json) {
    return HealthProfileAccessRequest(
      id:           json['_id']?.toString() ?? '',
      doctorId:     json['doctor_id']?.toString() ?? '',
      doctorName:   json['doctor_name'] ?? '',
      doctorEmail:  json['doctor_email'] ?? '',
      status:       json['status'] ?? 'pending',
      requestedAt:  DateTime.tryParse(json['requested_at'] ?? '') ?? DateTime.now(),
      respondedAt:  json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
    );
  }

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isRevoked  => status == 'revoked';
}

class HealthProfileModel {
  final String? id;
  final String patientId;
  final String fullName;
  final int? age;
  final String gender;
  final String height;
  final String weight;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> currentMedications;
  final List<String> chronicConditions;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final List<HealthProfileAccessRequest> accessRequests;

  const HealthProfileModel({
    this.id,
    required this.patientId,
    this.fullName = '',
    this.age,
    this.gender = '',
    this.height = '',
    this.weight = '',
    this.bloodGroup = '',
    this.allergies = const [],
    this.currentMedications = const [],
    this.chronicConditions = const [],
    this.emergencyContactName = '',
    this.emergencyContactNumber = '',
    this.accessRequests = const [],
  });

  factory HealthProfileModel.fromJson(Map<String, dynamic> json) {
    final reqs = (json['access_requests'] as List? ?? [])
        .map((r) => HealthProfileAccessRequest.fromJson(r as Map<String, dynamic>))
        .toList();
    return HealthProfileModel(
      id:                     json['_id']?.toString(),
      patientId:              json['patient_id']?.toString() ?? '',
      fullName:               json['full_name'] ?? '',
      age:                    json['age'] as int?,
      gender:                 json['gender'] ?? '',
      height:                 json['height'] ?? '',
      weight:                 json['weight'] ?? '',
      bloodGroup:             json['blood_group'] ?? '',
      allergies:              List<String>.from(json['allergies'] ?? []),
      currentMedications:     List<String>.from(json['current_medications'] ?? []),
      chronicConditions:      List<String>.from(json['chronic_conditions'] ?? []),
      emergencyContactName:   json['emergency_contact_name'] ?? '',
      emergencyContactNumber: json['emergency_contact_number'] ?? '',
      accessRequests:         reqs,
    );
  }

  Map<String, dynamic> toJson() => {
        'full_name':                fullName,
        'age':                      age,
        'gender':                   gender,
        'height':                   height,
        'weight':                   weight,
        'blood_group':              bloodGroup,
        'allergies':                allergies,
        'current_medications':      currentMedications,
        'chronic_conditions':       chronicConditions,
        'emergency_contact_name':   emergencyContactName,
        'emergency_contact_number': emergencyContactNumber,
      };

  int get pendingRequestCount  => accessRequests.where((r) => r.isPending).length;
  int get approvedDoctorCount  => accessRequests.where((r) => r.isApproved).length;

  bool get isComplete =>
      fullName.isNotEmpty &&
      age != null &&
      bloodGroup.isNotEmpty &&
      emergencyContactName.isNotEmpty &&
      emergencyContactNumber.isNotEmpty;
}
