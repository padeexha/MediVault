import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'shared_records_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  String _doctorName = '';
  int _totalPatients = 0;
  int _totalRecords = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await ApiService.getUser();
    if (user != null) setState(() => _doctorName = user['name'] ?? '');

    final response = await ApiService.get(Constants.sharedWithMe);
    if (response['success'] == true) {
      final data = response['data'] as List;
      int total = 0;
      for (final item in data) {
        total += (item['records'] as List).length;
      }
      setState(() {
        _totalPatients = data.length;
        _totalRecords = total;
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
                          'Patient Records',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _sharedRecordsCard(),
                        const SizedBox(height: 16),
                        _infoCard(),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
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
                    'Welcome, Dr.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _doctorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _statChip('$_totalPatients', 'Patients'),
                      const SizedBox(width: 10),
                      _statChip('$_totalRecords', 'Records'),
                    ],
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
              child: const Icon(Icons.medical_services_outlined,
                  color: AppColors.accent, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sharedRecordsCard() {
    return DarkListCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SharedRecordsScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_shared,
                  color: AppColors.accentBlue, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shared Records',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalRecords records from $_totalPatients patients',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 15, color: Colors.white.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You can only view records that patients have explicitly shared with you.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
