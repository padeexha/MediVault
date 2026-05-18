import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';

class UploadRecordScreen extends StatefulWidget {
  const UploadRecordScreen({super.key});

  @override
  State<UploadRecordScreen> createState() => _UploadRecordScreenState();
}

class _UploadRecordScreenState extends State<UploadRecordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _titleCtrl     = TextEditingController();
  final _notesCtrl     = TextEditingController();
  String _selectedCategory = 'lab_report';
  File?  _selectedFile;
  String? _selectedFileName;
  bool _isLoading = false;

  // Success state
  bool _uploadSuccess = false;
  String _uploadedTitle    = '';
  String _uploadedCategory = '';
  late AnimationController _successCtrl;
  late Animation<double> _scaleAnim;

  static const _categories = [
    {'value': 'lab_report',        'label': 'Lab Report'},
    {'value': 'prescription',      'label': 'Prescription'},
    {'value': 'radiology',         'label': 'Radiology'},
    {'value': 'discharge_summary', 'label': 'Discharge Summary'},
    {'value': 'other',             'label': 'Other'},
  ];

  static const _categoryColors = {
    'lab_report':        Color(0xFF185FA5),
    'prescription':      Color(0xFF1D9E75),
    'radiology':         Color(0xFF854F0B),
    'discharge_summary': Color(0xFF993C1D),
    'other':             AppColors.textSecondary,
  };

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile     = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Please select a file to upload',
                  style: TextStyle(color: AppThemeColors.of(context).textPrimary)),
            ),
          ]),
          backgroundColor: AppThemeColors.of(context).bgSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final response = await ApiService.uploadFile(
      Constants.uploadRecord,
      _selectedFile!,
      {
        'title':    _titleCtrl.text.trim(),
        'category': _selectedCategory,
        'notes':    _notesCtrl.text.trim(),
      },
    );
    setState(() => _isLoading = false);
    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _uploadSuccess    = true;
        _uploadedTitle    = _titleCtrl.text.trim();
        _uploadedCategory = _selectedCategory;
      });
      _successCtrl.forward();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(response['message'] ?? 'Upload failed',
                  style: TextStyle(color: AppThemeColors.of(context).textPrimary)),
            ),
          ]),
          backgroundColor: AppThemeColors.of(context).bgSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _categoryLabel(String val) {
    return _categories
            .firstWhere((c) => c['value'] == val,
                orElse: () => {'label': 'Other'})['label'] ??
        'Other';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.of(context).bg,
      appBar: darkGlassAppBar(
        context: context,
        title: _uploadSuccess ? 'Upload Complete' : 'Upload Record',
      ),
      body: _uploadSuccess
          ? _successScreen()
          : _uploadForm(),
    );
  }

  Widget _successScreen() {
    final catColor =
        _categoryColors[_uploadedCategory] ?? AppThemeColors.of(context).textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.ecgGreen.withValues(alpha: 0.3),
                    AppColors.ecgGreen.withValues(alpha: 0.0),
                  ]),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle_rounded,
                      size: 72, color: AppColors.ecgGreen),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Upload Successful!',
                style: TextStyle(
                    color: AppThemeColors.of(context).textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Your medical record has been securely stored.',
                style: TextStyle(color: AppThemeColors.of(context).textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            // Record summary card
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppThemeColors.of(context).divider,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.insert_drive_file_outlined,
                            color: catColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_uploadedTitle,
                                style: TextStyle(
                                    color: AppThemeColors.of(context).textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(_categoryLabel(_uploadedCategory),
                                  style: TextStyle(
                                      color: catColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            DarkButton(
              label: 'Upload Another',
              icon: Icons.upload_file_outlined,
              onPressed: () {
                _successCtrl.reset();
                setState(() {
                  _uploadSuccess    = false;
                  _titleCtrl.clear();
                  _notesCtrl.clear();
                  _selectedFile     = null;
                  _selectedFileName = null;
                  _selectedCategory = 'lab_report';
                });
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.arrow_back_outlined, size: 18),
              label: const Text('Back to Dashboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.25)),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleCtrl,
              style: TextStyle(color: AppThemeColors.of(context).textPrimary),
              decoration: darkInputDecoration('Record title', context: context,
                  prefixIcon: Icons.title),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: AppThemeColors.of(context).bgCard,
              style: TextStyle(color: AppThemeColors.of(context).textPrimary),
              decoration: darkInputDecoration('Category', context: context,
                  prefixIcon: Icons.category),
              items: _categories
                  .map((c) =>
                      DropdownMenuItem(value: c['value'], child: Text(c['label']!)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              style: TextStyle(color: AppThemeColors.of(context).textPrimary),
              decoration: darkInputDecoration('Notes (optional)', context: context,
                  prefixIcon: Icons.notes),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Select File',
                    style: TextStyle(
                        color: AppThemeColors.of(context).textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Flexible(
                  child: Text('PDF, JPEG, PNG — max 20 MB',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppThemeColors.of(context).textSecondary.withValues(alpha: 0.7),
                          fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickFile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppThemeColors.of(context).bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppColors.accentBlue
                        : Colors.white.withValues(alpha: 0.1),
                    width: _selectedFile != null ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.check_circle_outline_rounded
                          : Icons.cloud_upload_outlined,
                      size: 48,
                      color: _selectedFile != null
                          ? AppColors.ecgGreen
                          : AppThemeColors.of(context).textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFileName ?? 'Tap to browse files',
                      style: TextStyle(
                        color: _selectedFile != null
                            ? Colors.white
                            : AppThemeColors.of(context).textSecondary,
                        fontWeight: _selectedFile != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Tap to change',
                        style: TextStyle(
                            color: AppThemeColors.of(context).textSecondary
                                .withValues(alpha: 0.6),
                            fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            DarkButton(
              label: 'Upload Record',
              onPressed: _upload,
              isLoading: _isLoading,
              icon: Icons.upload_file,
            ),
          ],
        ),
      ),
    );
  }
}
