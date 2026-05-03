import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../models/record_model.dart';
import '../auth/login_screen.dart';
import 'upload_record_screen.dart';
import 'record_list_screen.dart';
import 'permissions_screen.dart';
import 'audit_log_screen.dart';
import 'search_screen.dart';

const _appLogo = 'assets/images/MediVault Logo.png';
const _heroBlue = Color(0xFF2F80ED);
const _heroBlueDark = Color(0xFF185FA5);
const _heroGreen = Color(0xFF27AE60);
const _heroTextSoft = Color(0xFFDDEBFF);
const _heroGlow = Color(0x3327AE60);

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
    if (user != null) {
      setState(() => _userName = user['name'] ?? '');
    }

    final response = await ApiService.get(Constants.records);
    if (response['success'] == true) {
      final records = (response['records'] as List)
          .map((r) => RecordModel.fromJson(r))
          .toList();

      final counts = <String, int>{};
      for (final record in records) {
        counts[record.category] = (counts[record.category] ?? 0) + 1;
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
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        titleSpacing: 12,
        title: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: Image.asset(
              _appLogo,
              fit: BoxFit.fitHeight,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_heroBlue, _heroBlueDark],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F2F80ED),
                            blurRadius: 28,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -18,
                            right: -10,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _heroGlow,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -34,
                            left: -24,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0x1FFFFFFF),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: const Text(
                                  'Patient Dashboard',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Welcome back,',
                                style: TextStyle(
                                  color: _heroTextSoft,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _userName.isEmpty ? 'Patient' : _userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Everything important is in one secure place and ready when you need it.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: _HeroStatCard(
                                      icon: Icons.description_outlined,
                                      label: 'Records',
                                      value: '$_totalRecords',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _HeroStatCard(
                                      icon: Icons.category_outlined,
                                      label: 'Categories',
                                      value: '${_categoryCounts.length}',
                                      accentColor: _heroGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF8F0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.health_and_safety_outlined,
                              color: _heroGreen,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Your vault is protected and refreshes with the latest record activity each time you open it.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _ActionCard(
                          icon: Icons.upload_file,
                          label: 'Upload Record',
                          color: const Color(0xFF0F6E56),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UploadRecordScreen(),
                              ),
                            );
                            _loadData();
                          },
                        ),
                        _ActionCard(
                          icon: Icons.folder_open,
                          label: 'My Records',
                          color: const Color(0xFF185FA5),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RecordListScreen(),
                            ),
                          ),
                        ),
                        _ActionCard(
                          icon: Icons.search,
                          label: 'Search Records',
                          color: const Color(0xFF534AB7),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(),
                            ),
                          ),
                        ),
                        _ActionCard(
                          icon: Icons.people,
                          label: 'Manage Access',
                          color: const Color(0xFF854F0B),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PermissionsScreen(),
                            ),
                          ),
                        ),
                        _ActionCard(
                          icon: Icons.history,
                          label: 'Audit Log',
                          color: const Color(0xFF993C1D),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AuditLogScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_categoryCounts.isNotEmpty) ...[
                      const Text(
                        'Records by Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._categoryCounts.entries.map((entry) {
                        final record = RecordModel(
                          id: '',
                          patientId: '',
                          title: '',
                          category: entry.key,
                          fileName: '',
                          fileType: '',
                          fileSize: 0,
                          filePath: '',
                          uploadDate: DateTime.now(),
                          isDeleted: false,
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                record.categoryDisplay,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F6E56),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${entry.value}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadRecordScreen()),
          );
          _loadData();
        },
        backgroundColor: const Color(0xFF0F6E56),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _HeroStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: _heroTextSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
