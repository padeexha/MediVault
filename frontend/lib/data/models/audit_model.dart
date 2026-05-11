class AuditModel {
  final String id;
  final String actionType;
  final String actionStatus;
  final DateTime actionDate;
  final String? details;
  final String? recordTitle;
  final String actorName;
  final String actorRole;

  AuditModel({
    required this.id,
    required this.actionType,
    required this.actionStatus,
    required this.actionDate,
    this.details,
    this.recordTitle,
    required this.actorName,
    required this.actorRole,
  });

  factory AuditModel.fromJson(Map<String, dynamic> json) {
    final actor = json['actor_user_id'];
    final record = json['record_id'];
    return AuditModel(
      id: json['_id'] ?? '',
      actionType: json['action_type'] ?? '',
      actionStatus: json['action_status'] ?? 'success',
      actionDate: DateTime.parse(json['action_date'] ?? DateTime.now().toIso8601String()),
      details: json['details'],
      recordTitle: record != null ? record['title'] : null,
      actorName: actor != null ? '${actor['first_name']} ${actor['last_name']}' : 'Unknown',
      actorRole: actor != null ? actor['role'] : 'unknown',
    );
  }

  String get actionDisplay {
    switch (actionType) {
      case 'upload': return 'Uploaded a record';
      case 'view': return 'Viewed a record';
      case 'download': return 'Downloaded a record';
      case 'delete': return 'Deleted a record';
      case 'edit': return 'Edited a record';
      case 'permission_granted': return 'Granted access';
      case 'permission_revoked': return 'Revoked access';
      case 'login': return 'Logged in';
      case 'logout': return 'Logged out';
      case 'password_reset': return 'Reset password';
      default: return actionType;
    }
  }
}