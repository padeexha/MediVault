class RecordModel {
  final String id;
  final String patientId;
  final String title;
  final String category;
  final String? notes;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String filePath;
  final DateTime uploadDate;
  final bool isDeleted;

  RecordModel({
    required this.id,
    required this.patientId,
    required this.title,
    required this.category,
    this.notes,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.filePath,
    required this.uploadDate,
    required this.isDeleted,
  });

  factory RecordModel.fromJson(Map<String, dynamic> json) {
    return RecordModel(
      id: json['_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      notes: json['notes'],
      fileName: json['file_name'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: json['file_size'] ?? 0,
      filePath: json['file_path'] ?? '',
      uploadDate: DateTime.parse(json['upload_date'] ?? DateTime.now().toIso8601String()),
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  String get categoryDisplay {
    switch (category) {
      case 'lab_report': return 'Lab Report';
      case 'prescription': return 'Prescription';
      case 'radiology': return 'Radiology';
      case 'discharge_summary': return 'Discharge Summary';
      default: return 'Other';
    }
  }
}