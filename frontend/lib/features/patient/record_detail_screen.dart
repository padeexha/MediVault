import 'dart:ui';
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
  final _titleCtrl    = TextEditingController();
  final _notesCtrl    = TextEditingController();
  bool _isEditing     = false;
  bool _isLoading     = false;
  bool _isDownloading = false;
  String _selectedCategory = '';

  static const _categories = [
    {'value': 'lab_report',        'label': 'Lab Report'},
    {'value': 'prescription',      'label': 'Prescription'},
    {'value': 'radiology',         'label': 'Radiology'},
    {'value': 'discharge_summary', 'label': 'Discharge Summary'},
    {'value': 'other',             'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl.text  = widget.record.title;
    _notesCtrl.text  = widget.record.notes ?? '';
    _selectedCategory = widget.record.category;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnackBar('Title cannot be empty', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final response = await ApiService.put(
      '${Constants.records}/${widget.record.id}',
      {
        'title':    _titleCtrl.text.trim(),
        'notes':    _notesCtrl.text.trim(),
        'category': _selectedCategory,
      },
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (response['success'] == true) {
      setState(() => _isEditing = false);
      _showSnackBar('Record updated successfully', isError: false);
    } else {
      _showSnackBar(response['message'] ?? 'Update failed', isError: true);
    }
  }

  Future<void> _logDownload() async {
    setState(() => _isDownloading = true);
    final response = await ApiService.post(
      '${Constants.records}/${widget.record.id}/download',
      {},
    );
    setState(() => _isDownloading = false);
    if (!mounted) return;
    if (response['success'] == true) {
      final uri = Uri.parse(widget.record.filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open file', isError: true);
      }
    } else {
      _showSnackBar(response['message'] ?? 'Download failed', isError: true);
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

  Color get _catColor {
    switch (widget.record.category) {
      case 'lab_report':        return const Color(0xFF185FA5);
      case 'prescription':      return const Color(0xFF1D9E75);
      case 'radiology':         return const Color(0xFF854F0B);
      case 'discharge_summary': return const Color(0xFF993C1D);
      default:                  return AppColors.textSecondary;
    }
  }

  bool get _isImageFile {
    final t = widget.record.fileType.toLowerCase();
    return t.contains('image') || t == 'jpg' || t == 'jpeg' || t == 'png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: darkGlassAppBar(
        title: 'Record Details',
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit record',
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _titleCtrl.text = widget.record.title;
                  _notesCtrl.text = widget.record.notes ?? '';
                  _selectedCategory = widget.record.category;
                });
              },
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _headerCard(),
            const SizedBox(height: 20),

            if (_isEditing) ...[
              _editSection(),
            ] else ...[
              _fileInfoCard(),
              if (widget.record.notes != null &&
                  widget.record.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _notesCard(),
              ],
              const SizedBox(height: 24),
              _downloadButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _catColor.withValues(alpha: 0.18),
                _catColor.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _catColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _catColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.record.categoryDisplay,
                      style: TextStyle(
                          color: _catColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _fileTypeBadge(),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.record.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    'Uploaded ${_formatDate(widget.record.uploadDate)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fileTypeBadge() {
    final isImg = _isImageFile;
    final label = isImg ? 'Image' : 'PDF';
    final color = isImg ? const Color(0xFF534AB7) : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isImg ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
              size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _fileInfoCard() {
    final sizeKb =
        (widget.record.fileSize / 1024).toStringAsFixed(1);
    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.insert_drive_file_outlined,
                    size: 15, color: AppColors.accent),
                SizedBox(width: 8),
                Text('File Information',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow('File Name', widget.record.fileName),
            _infoRow('File Type', widget.record.fileType.toUpperCase()),
            _infoRow('File Size', '$sizeKb KB'),
          ],
        ),
      ),
    );
  }

  Widget _notesCard() {
    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.notes_outlined,
                    size: 15, color: AppColors.accent),
                SizedBox(width: 8),
                Text('Notes',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.record.notes!,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isDownloading ? null : _logDownload,
        icon: _isDownloading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.download_outlined, size: 20),
        label:
            Text(_isDownloading ? 'Opening…' : 'Download / Open Record'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _editSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Edit Record',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: darkInputDecoration('Title', prefixIcon: Icons.title),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          dropdownColor: AppColors.bgCard,
          style: const TextStyle(color: Colors.white),
          decoration:
              darkInputDecoration('Category', prefixIcon: Icons.category),
          items: _categories.map((c) {
            return DropdownMenuItem(
                value: c['value'], child: Text(c['label']!));
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedCategory = v);
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _notesCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: darkInputDecoration('Notes', prefixIcon: Icons.notes),
        ),
        const SizedBox(height: 24),
        DarkButton(
          label: 'Save Changes',
          onPressed: _saveChanges,
          isLoading: _isLoading,
          icon: Icons.save_outlined,
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
