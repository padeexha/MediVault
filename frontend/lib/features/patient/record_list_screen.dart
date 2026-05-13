import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/record_model.dart';
import 'record_detail_screen.dart';

enum _SortOption { dateDesc, dateAsc, titleAZ, titleZA }

enum _SharedFilter { all, shared, private }

class RecordListScreen extends StatefulWidget {
  const RecordListScreen({super.key});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  List<RecordModel> _records = [];
  List<RecordModel> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  _SortOption _sortOption = _SortOption.dateDesc;
  _SharedFilter _sharedFilter = _SharedFilter.all;
  Set<String> _favouriteIds = {};
  Set<String> _sharedRecordIds = {};
  DateTime? _dateFrom;
  DateTime? _dateTo;

  static const _categories = [
    {'value': 'all',              'label': 'All'},
    {'value': 'lab_report',       'label': 'Lab'},
    {'value': 'prescription',     'label': 'Rx'},
    {'value': 'radiology',        'label': 'Radiology'},
    {'value': 'discharge_summary','label': 'Discharge'},
    {'value': 'other',            'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadFavourites(), _loadRecords()]);
  }

  Future<void> _loadFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favourite_records') ?? [];
    setState(() => _favouriteIds = saved.toSet());
  }

  Future<void> _loadRecords() async {
    final results = await Future.wait([
      ApiService.get(Constants.records),
      ApiService.get(Constants.myDoctors),
    ]);

    if (!mounted) return;

    final recordsRes = results[0];
    final permRes    = results[1];

    if (recordsRes['success'] != true) {
      setState(() => _isLoading = false);
      return;
    }

    final records = (recordsRes['records'] as List)
        .map((r) => RecordModel.fromJson(r))
        .toList();

    // Compute which records are shared
    final sharedIds = <String>{};
    if (permRes['success'] == true) {
      final perms = permRes['permissions'] as List? ?? [];
      final hasFullAccess = perms.any((p) => p['scope_type'] == 'all');
      if (hasFullAccess) {
        sharedIds.addAll(records.map((r) => r.id));
      } else {
        final sharedCats = perms
            .where((p) => p['scope_type'] == 'category')
            .map((p) => p['shared_category'] as String?)
            .whereType<String>()
            .toSet();
        for (final r in records) {
          if (sharedCats.contains(r.category)) sharedIds.add(r.id);
        }
      }
    }

    setState(() {
      _records         = records;
      _sharedRecordIds = sharedIds;
      _isLoading       = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    var list = List<RecordModel>.from(_records);

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) =>
          r.title.toLowerCase().contains(q) ||
          r.categoryDisplay.toLowerCase().contains(q)).toList();
    }

    // Category
    if (_selectedCategory != 'all') {
      list = list.where((r) => r.category == _selectedCategory).toList();
    }

    // Shared filter
    if (_sharedFilter == _SharedFilter.shared) {
      list = list.where((r) => _sharedRecordIds.contains(r.id)).toList();
    } else if (_sharedFilter == _SharedFilter.private) {
      list = list.where((r) => !_sharedRecordIds.contains(r.id)).toList();
    }

    // Date range
    if (_dateFrom != null) {
      list = list.where((r) => !r.uploadDate.isBefore(_dateFrom!)).toList();
    }
    if (_dateTo != null) {
      final endOfDay = DateTime(_dateTo!.year, _dateTo!.month, _dateTo!.day, 23, 59, 59);
      list = list.where((r) => !r.uploadDate.isAfter(endOfDay)).toList();
    }

    // Sort
    switch (_sortOption) {
      case _SortOption.dateDesc:
        list.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
        break;
      case _SortOption.dateAsc:
        list.sort((a, b) => a.uploadDate.compareTo(b.uploadDate));
        break;
      case _SortOption.titleAZ:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case _SortOption.titleZA:
        list.sort((a, b) => b.title.compareTo(a.title));
        break;
    }

    // Favourites always on top
    list.sort((a, b) {
      final af = _favouriteIds.contains(a.id) ? 0 : 1;
      final bf = _favouriteIds.contains(b.id) ? 0 : 1;
      return af.compareTo(bf);
    });

    setState(() => _filtered = list);
  }

  Future<void> _toggleFavourite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = Set<String>.from(_favouriteIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    await prefs.setStringList('favourite_records', updated.toList());
    setState(() => _favouriteIds = updated);
    _applyFilters();
  }

  Future<void> _deleteRecord(RecordModel record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Delete Record',
        content:
            'Are you sure you want to delete "${record.title}"? This action cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: Colors.redAccent,
        icon: Icons.delete_outline,
      ),
    );
    if (confirmed != true) return;

    final response =
        await ApiService.delete('${Constants.records}/${record.id}');
    if (!mounted) return;
    if (response['success'] == true) {
      _showSnackBar('Record deleted successfully', isError: false);
      _loadRecords();
    } else {
      _showSnackBar(response['message'] ?? 'Failed to delete record',
          isError: true);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
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
                child:
                    Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.bgSurface,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Sharing status',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            ...{
              _SharedFilter.all:     'All records',
              _SharedFilter.shared:  'Shared with doctors',
              _SharedFilter.private: 'Private only',
            }.entries.map((e) => RadioListTile<_SharedFilter>(
                  value: e.key,
                  groupValue: _sharedFilter,
                  activeColor: AppColors.accentBlue,
                  title: Text(e.value,
                      style: const TextStyle(color: Colors.white)),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    if (v != null) setState(() => _sharedFilter = v);
                    _applyFilters();
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sortChipsRow() {
    const options = {
      _SortOption.dateDesc: 'Newest',
      _SortOption.dateAsc:  'Oldest',
      _SortOption.titleAZ:  'A → Z',
      _SortOption.titleZA:  'Z → A',
    };
    return Row(
      children: [
        const Text('Sort:',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.entries.map((e) {
                final selected = _sortOption == e.key;
                return GestureDetector(
                  onTap: () {
                    setState(() => _sortOption = e.key);
                    _applyFilters();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accentBlue
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppColors.accentBlue
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
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
    final activeFilters = (_sharedFilter != _SharedFilter.all ? 1 : 0) +
        (_dateFrom != null ? 1 : 0) +
        (_dateTo != null ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: darkGlassAppBar(
        title: 'Records',
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_outlined),
                tooltip: 'Sort & filter',
                onPressed: _showSortSheet,
              ),
              if (activeFilters > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: darkInputDecoration('Search by title or category…',
                      prefixIcon: Icons.search),
                  onChanged: (v) {
                    _searchQuery = v;
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final selected =
                          _selectedCategory == cat['value'];
                      return GestureDetector(
                        onTap: () {
                          setState(
                              () => _selectedCategory = cat['value']!);
                          _applyFilters();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.only(right: 8),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accentBlue
                                : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accentBlue
                                  : Colors.white
                                      .withValues(alpha: 0.12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat['label']!,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _datePicker(
                        'From', _dateFrom, () => _pickDate(true),
                        onClear: () {
                          setState(() => _dateFrom = null);
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _datePicker(
                        'To', _dateTo, () => _pickDate(false),
                        onClear: () {
                          setState(() => _dateTo = null);
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _sortChipsRow(),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent))
                : _filtered.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AppColors.accent,
                        backgroundColor: AppColors.bgCard,
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _recordCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _recordCard(RecordModel record) {
    final color   = _categoryColor(record.category);
    final isFav   = _favouriteIds.contains(record.id);
    final isShared= _sharedRecordIds.contains(record.id);
    final isImage = record.fileType.contains('image') ||
        record.fileType == 'jpg' ||
        record.fileType == 'jpeg' ||
        record.fileType == 'png';
    final fileLabel = isImage ? 'IMG' : 'PDF';
    final fileColor = isImage
        ? const Color(0xFF534AB7)
        : Colors.redAccent;

    return DarkListCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => RecordDetailScreen(record: record)),
        );
        _loadRecords();
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Category icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_categoryIcon(record.category),
                  color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isFav)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14),
                        ),
                      Expanded(
                        child: Text(
                          record.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // File type badge
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
                      // Category badge
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
                      // Shared/private badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isShared
                              ? AppColors.ecgGreen
                                  .withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isShared
                                  ? Icons.lock_open_outlined
                                  : Icons.lock_outline,
                              size: 9,
                              color: isShared
                                  ? AppColors.ecgGreen
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isShared ? 'Shared' : 'Private',
                              style: TextStyle(
                                color: isShared
                                    ? AppColors.ecgGreen
                                    : AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(record.uploadDate),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                GestureDetector(
                  onTap: () => _toggleFavourite(record.id),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isFav
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isFav
                          ? Colors.amber
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _deleteRecord(record),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
      _applyFilters();
    }
  }

  Widget _datePicker(String hint, DateTime? date, VoidCallback onTap,
      {VoidCallback? onClear}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null
                ? AppColors.accentBlue
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                size: 12,
                color: date != null ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                date != null ? DateFormat('dd/MM/yy').format(date) : hint,
                style: TextStyle(
                  fontSize: 12,
                  color: date != null ? Colors.white : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (date != null && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    final hasSearch = _searchQuery.isNotEmpty ||
        _selectedCategory != 'all' ||
        _sharedFilter != _SharedFilter.all ||
        _dateFrom != null ||
        _dateTo != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.folder_open_outlined,
              size: 72,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch
                  ? 'No records match your filters'
                  : 'No records yet',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try adjusting your search or filters.'
                  : 'Upload your first medical record using the + button.',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
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

// ── Confirm Delete / Revoke dialog ────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final Color confirmColor;
  final IconData icon;

  const _ConfirmDialog({
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.confirmColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(icon, color: confirmColor, size: 22),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(content,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
