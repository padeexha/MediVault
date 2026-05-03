class PermissionModel {
  final String id;
  final String patientId;
  final String providerId;
  final String scopeType;
  final String? recordId;
  final String? sharedCategory;
  final String accessStatus;
  final DateTime grantedAt;
  final DateTime? revokedAt;
  final DateTime? expiresAt;

  PermissionModel({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.scopeType,
    this.recordId,
    this.sharedCategory,
    required this.accessStatus,
    required this.grantedAt,
    this.revokedAt,
    this.expiresAt,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: json['_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      providerId: json['provider_id'] ?? '',
      scopeType: json['scope_type'] ?? 'all',
      recordId: json['record_id'],
      sharedCategory: json['shared_category'],
      accessStatus: json['access_status'] ?? 'granted',
      grantedAt: DateTime.parse(json['granted_at'] ?? DateTime.now().toIso8601String()),
      revokedAt: json['revoked_at'] != null ? DateTime.parse(json['revoked_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }

  bool get isGranted => accessStatus == 'granted';
}