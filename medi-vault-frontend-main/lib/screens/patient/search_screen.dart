import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../models/record_model.dart';
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
    {'value': 'discharge_summary', 'label': 'Discharge Summary'},
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

    final query = <String, String>{
      if (_searchController.text.trim().isNotEmpty)
        'title': _searchController.text.trim(),
      if (_selectedCategory != 'all') 'category': _selectedCategory,
      if (_dateFrom != null) 'date_from': _dateFrom!.toIso8601String(),
      if (_dateTo != null) 'date_to': _dateTo!.toIso8601String(),
      'sort_by': _selectedSort,
    };
    final url = Uri.parse(Constants.search)
        .replace(queryParameters: query)
        .toString();

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

  Future<void> _pickDateFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0F6E56)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateFrom = picked);
  }

  Future<void> _pickDateTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0F6E56)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateTo = picked);
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

  Color _categoryColor(String category) {
    switch (category) {
      case 'lab_report': return const Color(0xFF185FA5);
      case 'prescription': return const Color(0xFF0F6E56);
      case 'radiology': return const Color(0xFF854F0B);
      case 'discharge_summary': return const Color(0xFF993C1D);
      default: return Colors.grey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
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
      appBar: AppBar(
        title: const Text('Search Records'),
        actions: [
          if (_hasSearched || _dateFrom != null || _dateTo != null)
            TextButton(
              onPressed: _clearFilters,
              child: const Text(
                'Clear',
                style: TextStyle(color: Color(0xFF0F6E56)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by title...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(60, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.search),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Category filter chips
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat['value'];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = cat['value']!);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0F6E56)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF0F6E56)),
                          ),
                          child: Center(
                            child: Text(
                              cat['label']!,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0F6E56),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Date range and sort row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDateFrom,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _dateFrom != null
                                  ? const Color(0xFF0F6E56)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: _dateFrom != null
                                    ? const Color(0xFF0F6E56)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _dateFrom != null
                                    ? DateFormat('dd/MM/yy').format(_dateFrom!)
                                    : 'From date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _dateFrom != null
                                      ? const Color(0xFF0F6E56)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDateTo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _dateTo != null
                                  ? const Color(0xFF0F6E56)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: _dateTo != null
                                    ? const Color(0xFF0F6E56)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _dateTo != null
                                    ? DateFormat('dd/MM/yy').format(_dateTo!)
                                    : 'To date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _dateTo != null
                                      ? const Color(0xFF0F6E56)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSort,
                            isExpanded: true,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            items: _sortOptions.map((opt) {
                              return DropdownMenuItem(
                                value: opt['value'],
                                child: Text(opt['label']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedSort = value);
                              }
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Search your medical records',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Filter by title, category, date or sort order',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.find_in_page_outlined,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No records found',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final record = _results[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _categoryColor(record.category)
                                          .withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _categoryIcon(record.category),
                                      color: _categoryColor(record.category),
                                    ),
                                  ),
                                  title: Text(
                                    record.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(record.categoryDisplay),
                                      Text(
                                        DateFormat('dd/MM/yyyy')
                                            .format(record.uploadDate),
                                        style:
                                            const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecordDetailScreen(
                                        record: record,
                                      ),
                                    ),
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
}
