import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../../models/record_model.dart';

class SharedRecordsScreen extends StatefulWidget {
  const SharedRecordsScreen({super.key});

  @override
  State<SharedRecordsScreen> createState() => _SharedRecordsScreenState();
}

class _SharedRecordsScreenState extends State<SharedRecordsScreen> {
  List<Map<String, dynamic>> _patientData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSharedRecords();
  }

  Future<void> _loadSharedRecords() async {
    setState(() => _isLoading = true);
    final response = await ApiService.get(Constants.sharedWithMe);
    if (response['success'] == true) {
      setState(() {
        _patientData = List<Map<String, dynamic>>.from(response['data']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'lab_report': return const Color(0xFF185FA5);
      case 'prescription': return const Color(0xFF1D9E75);
      case 'radiology': return const Color(0xFF854F0B);
      case 'discharge_summary': return const Color(0xFF993C1D);
      default: return AppColors.textSecondary;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'lab_report': return Icons.science;
      case 'prescription': return Icons.medication;
      case 'radiology': return Icons.image_search;
      case 'discharge_summary': return Icons.assignment;
      default: return Icons.description;
    }
  }

  Future<void> _logDownload(String recordId, String title) async {
    await ApiService.post('${Constants.records}/$recordId/download', {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download logged for: $title')),
    );
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      const Text('No records shared with you yet',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: _loadSharedRecords,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _patientData.length,
                    itemBuilder: (_, i) {
                      final item = _patientData[i];
                      final patient = item['patient'];
                      final records = (item['records'] as List)
                          .map((r) => RecordModel.fromJson(r))
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 8, bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentBlue
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.person,
                                      size: 14,
                                      color: AppColors.accentBlue),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Patient: ${patient['_id'].toString().substring(0, 8)}...',
                                  style: const TextStyle(
                                    color: AppColors.accentBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentBlue
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${records.length} records',
                                    style: const TextStyle(
                                        color: AppColors.accentBlue,
                                        fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...records.map((record) {
                            final color = _categoryColor(record.category);
                            return DarkListCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                      _categoryIcon(record.category),
                                      color: color,
                                      size: 20),
                                ),
                                title: Text(record.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                subtitle: Text(
                                  '${record.categoryDisplay} · ${record.uploadDate.day}/${record.uploadDate.month}/${record.uploadDate.year}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.download_outlined,
                                      color: AppColors.accent),
                                  onPressed: () =>
                                      _logDownload(record.id, record.title),
                                ),
                              ),
                            );
                          }),
                          Divider(
                              color: Colors.white.withValues(alpha: 0.07)),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}
