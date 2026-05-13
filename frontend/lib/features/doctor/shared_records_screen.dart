import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/record_model.dart';
import 'doctor_health_profile_screen.dart';

class SharedRecordsScreen extends StatefulWidget {
  const SharedRecordsScreen({super.key});

  @override
  State<SharedRecordsScreen> createState() => _SharedRecordsScreenState();
}

class _SharedRecordsScreenState extends State<SharedRecordsScreen> {
  List<Map<String, dynamic>> _patientData = [];
  bool _isLoading = true;
  String? _openingRecordId;

  @override
  void initState() {
    super.initState();
    _loadSharedRecords();
  }

  Future<void> _loadSharedRecords() async {
    setState(() => _isLoading = true);
    final response = await ApiService.get(Constants.sharedWithMe);
    if (!mounted) return;
    if (response['success'] == true) {
      setState(() {
        _patientData = List<Map<String, dynamic>>.from(response['data']);
        _isLoading   = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openRecord(RecordModel record) async {
    setState(() => _openingRecordId = record.id);
    try {
      final res = await ApiService.post(
          '${Constants.records}/${record.id}/download', {});
      if (!mounted) return;

      final rawUrl = (res['success'] == true
              ? res['download_url'] as String?
              : null) ??
          record.filePath;

      if (rawUrl.isEmpty) {
        _showSnackBar('File URL not available', isError: true);
        return;
      }

      final uri      = Uri.parse(rawUrl);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showSnackBar('Could not open file — no app found for this type',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _openingRecordId = null);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.redAccent : AppColors.ecgGreen,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg,
                    style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.bgSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'lab_report':        return const Color(0xFF185FA5);
      case 'prescription':      return const Color(0xFF1D9E75);
      case 'radiology':         return const Color(0xFF854F0B);
      case 'discharge_summary': return const Color(0xFF993C1D);
      default:                  return AppColors.textSecondary;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'lab_report':        return Icons.science;
      case 'prescription':      return Icons.medication;
      case 'radiology':         return Icons.image_search;
      case 'discharge_summary': return Icons.assignment;
      default:                  return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: darkGlassAppBar(title: 'Shared Records'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _patientData.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: _loadSharedRecords,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: _patientData.length,
                    itemBuilder: (_, i) {
                      final item = _patientData[i];
                      final patient =
                          item['patient'] as Map<String, dynamic>;
                      final records = (item['records'] as List)
                          .map((r) => RecordModel.fromJson(r))
                          .toList();
                      final patientId =
                          patient['id']?.toString() ?? patient['_id']?.toString() ?? '';
                      final patientName = (patient['name'] as String? ?? '')
                              .trim()
                              .isNotEmpty
                          ? patient['name'] as String
                          : 'Unknown Patient';
                      final patientEmail =
                          (patient['email'] as String?) ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _patientHeader(
                              patient: patient,
                              patientId: patientId,
                              patientName: patientName,
                              patientEmail: patientEmail,
                              recordCount: records.length,
                            ),
                            const SizedBox(height: 8),
                            ...records.map(
                                (r) => _recordCard(r)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_shared_outlined,
                size: 72, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 20),
            const Text('No Records Shared With You',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Patients must grant you access from their app before you can view their records.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientHeader({
    required Map<String, dynamic> patient,
    required String patientId,
    required String patientName,
    required String patientEmail,
    required int recordCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentBlue.withValues(alpha: 0.14),
            AppColors.accentBlue.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            profilePicture: patient['profile_picture'] as String?,
            gender: patient['gender'] as String?,
            role: 'patient',
            radius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patientName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                if (patientEmail.isNotEmpty)
                  Text(patientEmail,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Health profile button
          if (patientId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorHealthProfileScreen(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A6E78).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF0A6E78)
                            .withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.health_and_safety_outlined,
                      color: Color(0xFF0A6E78), size: 16),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$recordCount record${recordCount == 1 ? '' : 's'}',
              style: const TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordCard(RecordModel record) {
    final color    = _categoryColor(record.category);
    final isOpening = _openingRecordId == record.id;
    final isImage  = record.fileType.contains('image') ||
        record.fileType == 'jpg' ||
        record.fileType == 'jpeg' ||
        record.fileType == 'png';
    final fileLabel = isImage ? 'IMG' : 'PDF';
    final fileColor = isImage ? const Color(0xFF534AB7) : Colors.redAccent;

    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_categoryIcon(record.category),
                  color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: fileColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(fileLabel,
                            style: TextStyle(
                                color: fileColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(record.categoryDisplay,
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(record.uploadDate),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isOpening
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent),
                  )
                : IconButton(
                    icon: const Icon(Icons.open_in_new,
                        color: AppColors.accent, size: 20),
                    tooltip: 'Open / Download',
                    onPressed: _openingRecordId != null
                        ? null
                        : () => _openRecord(record),
                  ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
