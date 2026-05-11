import 'package:flutter/material.dart';
import '../../data/models/record_model.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class RecordDetailScreen extends StatefulWidget {
  final RecordModel record;
  const RecordDetailScreen({super.key, required this.record});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  String _selectedCategory = '';

  final List<Map<String, String>> _categories = [
    {'value': 'lab_report', 'label': 'Lab Report'},
    {'value': 'prescription', 'label': 'Prescription'},
    {'value': 'radiology', 'label': 'Radiology'},
    {'value': 'discharge_summary', 'label': 'Discharge Summary'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.record.title;
    _notesController.text = widget.record.notes ?? '';
    _selectedCategory = widget.record.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    final response = await ApiService.put(
      '${Constants.records}/${widget.record.id}',
      {
        'title': _titleController.text.trim(),
        'notes': _notesController.text.trim(),
        'category': _selectedCategory,
      },
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (response['success'] == true) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response['message'] ?? 'Update failed')),
      );
    }
  }

  Future<void> _logDownload() async {
    final response = await ApiService.post(
      '${Constants.records}/${widget.record.id}/download',
      {},
    );
    if (!mounted) return;
    if (response['success'] == true) {
      final uri = Uri.parse(widget.record.filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
  }

  Color get _categoryColor {
    switch (widget.record.category) {
      case 'lab_report': return const Color(0xFF185FA5);
      case 'prescription': return const Color(0xFF1D9E75);
      case 'radiology': return const Color(0xFF854F0B);
      case 'discharge_summary': return const Color(0xFF993C1D);
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: darkGlassAppBar(
        title: 'Record Details',
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DarkListCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _categoryColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.record.categoryDisplay,
                        style: TextStyle(
                          color: _categoryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.record.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Uploaded on ${widget.record.uploadDate.day}/${widget.record.uploadDate.month}/${widget.record.uploadDate.year}',
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isEditing) ...[
              const Text('Edit Record',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration:
                    darkInputDecoration('Title', prefixIcon: Icons.title),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: AppColors.bgCard,
                style: const TextStyle(color: Colors.white),
                decoration: darkInputDecoration('Category',
                    prefixIcon: Icons.category),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat['value'],
                    child: Text(cat['label']!),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration:
                    darkInputDecoration('Notes', prefixIcon: Icons.notes),
              ),
              const SizedBox(height: 24),
              DarkButton(
                label: 'Save Changes',
                onPressed: _saveChanges,
                isLoading: _isLoading,
              ),
            ] else ...[
              const Text('File Information',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DarkListCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _infoRow('File name', widget.record.fileName),
                      _infoRow('File type', widget.record.fileType),
                      _infoRow(
                        'File size',
                        '${(widget.record.fileSize / 1024).toStringAsFixed(1)} KB',
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.record.notes != null &&
                  widget.record.notes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Notes',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DarkListCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.record.notes!,
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _logDownload,
                  icon: const Icon(Icons.download, color: AppColors.accent),
                  label: const Text('Download Record',
                      style: TextStyle(color: AppColors.accent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
