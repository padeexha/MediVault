import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/record_model.dart';
import 'record_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<RecordModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _selectedCategory = 'all';
  String _selectedSort = 'date_desc';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'All'},
    {'value': 'lab_report', 'label': 'Lab Report'},
    {'value': 'prescription', 'label': 'Prescription'},
    {'value': 'radiology', 'label': 'Radiology'},
    {'value': 'discharge_summary', 'label': 'Discharge'},
    {'value': 'other', 'label': 'Other'},
  ];

  final List<Map<String, String>> _sortOptions = [
    {'value': 'date_desc', 'label': 'Newest first'},
    {'value': 'date_asc', 'label': 'Oldest first'},
    {'value': 'title_asc', 'label': 'A to Z'},
    {'value': 'title_desc', 'label': 'Z to A'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    String url = '${Constants.search}?';
    if (_searchController.text.trim().isNotEmpty) {
      url += 'title=${_searchController.text.trim()}&';
    }
    if (_selectedCategory != 'all') url += 'category=$_selectedCategory&';
    if (_dateFrom != null) url += 'date_from=${_dateFrom!.toIso8601String()}&';
    if (_dateTo != null) {
      // Extend to end of selected day so records from that date are included.
      final endOfDay = DateTime(_dateTo!.year, _dateTo!.month, _dateTo!.day, 23, 59, 59, 999);
      url += 'date_to=${endOfDay.toIso8601String()}&';
    }
    url += 'sort_by=$_selectedSort';

    final response = await ApiService.get(url);
    if (response['success'] == true) {
      final records = (response['records'] as List)
          .map((r) => RecordModel.fromJson(r))
          .toList();
      setState(() {
        _results = records;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
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
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'all';
      _selectedSort = 'date_desc';
      _dateFrom = null;
      _dateTo = null;
      _results = [];
      _hasSearched = false;
    });
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'lab_report': return const Color(0xFF185FA5);
      case 'prescription': return const Color(0xFF1D9E75);
      case 'radiology': return const Color(0xFF854F0B);
      case 'discharge_summary': return const Color(0xFF993C1D);
      default: return AppThemeColors.of(context).textSecondary;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.of(context).bg,
      appBar: darkGlassAppBar(
        context: context,
        title: 'Search Records',
        actions: [
          if (_hasSearched || _dateFrom != null || _dateTo != null)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear',
                  style: TextStyle(color: AppColors.accent)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: AppThemeColors.of(context).textPrimary),
                        decoration: darkInputDecoration('Search by title...', context: context,
                            prefixIcon: Icons.search),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _search,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Icon(Icons.search, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final selected = _selectedCategory == cat['value'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat['value']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accentBlue
                                : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accentBlue
                                  : Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat['label']!,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppThemeColors.of(context).textSecondary,
                                fontSize: 13,
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _datePicker('From', _dateFrom, () => _pickDate(true))),
                    const SizedBox(width: 8),
                    Expanded(child: _datePicker('To', _dateTo, () => _pickDate(false))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 44,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppThemeColors.of(context).bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSort,
                            isExpanded: true,
                            dropdownColor: AppThemeColors.of(context).bgCard,
                            style: TextStyle(
                                color: AppThemeColors.of(context).textPrimary, fontSize: 12),
                            items: _sortOptions.map((opt) {
                              return DropdownMenuItem(
                                value: opt['value'],
                                child: Text(opt['label']!),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedSort = v);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accent))
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search,
                                size: 64,
                                color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.15)),
                            const SizedBox(height: 16),
                            Text('Search your medical records',
                                style: TextStyle(
                                    color: AppThemeColors.of(context).textSecondary,
                                    fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(
                                'Filter by title, category, or date',
                                style: TextStyle(
                                    color: AppThemeColors.of(context).textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.find_in_page_outlined,
                                    size: 64,
                                    color:
                                        Colors.white.withValues(alpha: 0.15)),
                                const SizedBox(height: 16),
                                Text('No records found',
                                    style: TextStyle(
                                        color: AppThemeColors.of(context).textSecondary,
                                        fontSize: 16)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _results.length,
                            itemBuilder: (_, i) {
                              final record = _results[i];
                              final color = _categoryColor(record.category);
                              return DarkListCard(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RecordDetailScreen(record: record),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(14),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.18),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                        _categoryIcon(record.category),
                                        color: color),
                                  ),
                                  title: Text(record.title,
                                      style: TextStyle(
                                          color: AppThemeColors.of(context).textPrimary,
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(record.categoryDisplay,
                                          style: TextStyle(
                                              color: AppThemeColors.of(context).textSecondary,
                                              fontSize: 12)),
                                      Text(
                                        DateFormat('dd/MM/yyyy')
                                            .format(record.uploadDate),
                                        style: TextStyle(
                                            color: AppThemeColors.of(context).textSecondary,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _datePicker(String hint, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppThemeColors.of(context).bgSurface,
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
                size: 13,
                color: date != null
                    ? AppColors.accent
                    : AppThemeColors.of(context).textSecondary),
            const SizedBox(width: 6),
            Text(
              date != null ? DateFormat('dd/MM/yy').format(date) : hint,
              style: TextStyle(
                fontSize: 12,
                color: date != null ? Colors.white : AppThemeColors.of(context).textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
