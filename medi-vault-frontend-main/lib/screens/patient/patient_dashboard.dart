import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../../models/record_model.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'upload_record_screen.dart';
import 'record_list_screen.dart';
import 'permissions_screen.dart';
import 'audit_log_screen.dart';
import 'search_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  String _userName = '';
  Map<String, int> _categoryCounts = {};
  int _totalRecords = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await ApiService.getUser();
    if (user != null) setState(() => _userName = user['name'] ?? '');

    final response = await ApiService.get(Constants.records);
    if (response['success'] == true) {
      final records = (response['records'] as List)
          .map((r) => RecordModel.fromJson(r))
          .toList();
      final counts = <String, int>{};
      for (final r in records) {
        counts[r.category] = (counts[r.category] ?? 0) + 1;
      }
      setState(() {
        _categoryCounts = counts;
        _totalRecords = records.length;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.post(Constants.logout, {});
    await ApiService.clearSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      appBar: darkGlassAppBar(
        title: 'MediVault',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              if (updated == true) _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.bgCard,
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _welcomeCard(),
                        const SizedBox(height: 24),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _actionsGrid(),
                        if (_categoryCounts.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Records by Category',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ..._categoryCounts.entries.map((e) {
                            final rec = RecordModel(
                              id: '', patientId: '', title: '',
                              category: e.key, fileName: '',
                              fileType: '', fileSize: 0, filePath: '',
                              uploadDate: DateTime.now(), isDeleted: false,
                            );
                            return DarkListCard(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rec.categoryDisplay,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentBlue
                                            .withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${e.value}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.accentBlue, AppColors.accent],
          ),
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadRecordScreen()),
            );
            _loadData();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_totalRecords medical record${_totalRecords == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: AppColors.accent.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.folder_open,
                  color: AppColors.accent, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionsGrid() {
    final actions = [
      _ActionItem(Icons.upload_file, 'Upload Record', AppColors.accentBlue, () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UploadRecordScreen()));
        _loadData();
      }),
      _ActionItem(Icons.folder_open, 'My Records', const Color(0xFF1D9E75), () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RecordListScreen()));
      }),
      _ActionItem(Icons.search, 'Search', const Color(0xFF534AB7), () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SearchScreen()));
      }),
      _ActionItem(Icons.people, 'Manage Access', const Color(0xFF854F0B), () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PermissionsScreen()));
      }),
      _ActionItem(Icons.history, 'Audit Log', const Color(0xFF993C1D), () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AuditLogScreen()));
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) => _ActionCard(item: actions[i]),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem(this.icon, this.label, this.color, this.onTap);
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;
  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: DarkListCard(
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
