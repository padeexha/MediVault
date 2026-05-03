import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../models/record_model.dart';
import 'record_detail_screen.dart';

class RecordListScreen extends StatefulWidget {
  const RecordListScreen({super.key});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  List<RecordModel> _records = [];
  List<RecordModel> _filteredRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'All'},
    {'value': 'lab_report', 'label': 'Lab Report'},
    {'value': 'prescription', 'label': 'Prescription'},
    {'value': 'radiology', 'label': 'Radiology'},
    {'value': 'discharge_summary', 'label': 'Discharge Summary'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final response = await ApiService.get(Constants.records);
    if (response['success'] == true) {
      final records = (response['records'] as List)
          .map((r) => RecordModel.fromJson(r))
          .toList();
      setState(() {
        _records = records;
        _filteredRecords = records;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _filterRecords() {
    setState(() {
      _filteredRecords = _records.where((record) {
        final matchesSearch = record.title
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        final matchesCategory =
            _selectedCategory == 'all' || record.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _deleteRecord(RecordModel record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete "${record.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response =
          await ApiService.delete('${Constants.records}/${record.id}');
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record deleted'),
            backgroundColor: Color(0xFF0F6E56),
          ),
        );
        _loadRecords();
      }
    }
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
        title: const Text('My Records'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search records...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterRecords();
                  },
                ),
                const SizedBox(height: 12),
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
                          _filterRecords();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0F6E56)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF0F6E56),
                            ),
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
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _records.isEmpty
                                  ? 'No records yet'
                                  : 'No records found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _categoryColor(record.category)
                                        .withOpacity(0.1),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(record.categoryDisplay),
                                    Text(
                                      '${record.uploadDate.day}/${record.uploadDate.month}/${record.uploadDate.year}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteRecord(record),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RecordDetailScreen(record: record),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}