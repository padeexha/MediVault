import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/record_model.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

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
  bool _canEdit = false;
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
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = await ApiService.getUser();
    if (!mounted) return;
    setState(() => _canEdit = user?['role'] == 'patient');
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
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record updated successfully'),
          backgroundColor: Color(0xFF0F6E56),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Update failed'),
          backgroundColor: Colors.red,
        ),
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
      final url = response['download_url'] ?? widget.record.filePath;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Color get _categoryColor {
    switch (_selectedCategory) {
      case 'lab_report': return const Color(0xFF185FA5);
      case 'prescription': return const Color(0xFF0F6E56);
      case 'radiology': return const Color(0xFF854F0B);
      case 'discharge_summary': return const Color(0xFF993C1D);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Details'),
        actions: [
          if (_canEdit)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _categoryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _categoryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _categoryDisplay(_selectedCategory),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _titleController.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploaded on ${widget.record.uploadDate.day}/${widget.record.uploadDate.month}/${widget.record.uploadDate.year}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isEditing) ...[
              const Text(
                'Edit Record',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat['value'],
                    child: Text(cat['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ] else ...[
              const Text(
                'File Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'File name', value: widget.record.fileName),
              _InfoRow(label: 'File type', value: widget.record.fileType),
              _InfoRow(
                label: 'File size',
                value: '${(widget.record.fileSize / 1024).toStringAsFixed(1)} KB',
              ),
              if (_notesController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_notesController.text.trim()),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _logDownload,
                icon: const Icon(Icons.download),
                label: const Text('Download Record'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: const Color(0xFF0F6E56),
                  side: const BorderSide(color: Color(0xFF0F6E56)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _categoryDisplay(String category) {
  switch (category) {
    case 'lab_report':
      return 'Lab Report';
    case 'prescription':
      return 'Prescription';
    case 'radiology':
      return 'Radiology';
    case 'discharge_summary':
      return 'Discharge Summary';
    default:
      return 'Other';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
