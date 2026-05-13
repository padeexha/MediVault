import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'shared_records_screen.dart';
import 'doctor_health_profile_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  String _doctorName  = '';
  String _specialization = '';
  String _organisation   = '';
  String? _gender;
  String? _profilePicture;
  int  _totalPatients    = 0;
  int  _totalRecords     = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await ApiService.getUser();
    if (user != null) setState(() => _doctorName = user['name'] ?? '');

    final results = await Future.wait([
      ApiService.get(Constants.getProfile),
      ApiService.get(Constants.sharedWithMe),
    ]);

    if (!mounted) return;

    final profile = results[0];
    if (profile['success'] == true) {
      final p = profile['profile'] as Map<String, dynamic>;
      final fn = (p['first_name'] as String? ?? '').trim();
      final ln = (p['last_name']  as String? ?? '').trim();
      setState(() {
        if (fn.isNotEmpty || ln.isNotEmpty) _doctorName = '$fn $ln'.trim();
        _specialization = (p['specialization']   as String? ?? '').trim();
        _organisation   = (p['organisation_name'] as String? ?? '').trim();
        _gender         = p['gender'] as String?;
        _profilePicture = p['profile_picture'] as String?;
      });
    }

    final shared = results[1];
    if (shared['success'] == true) {
      final data = shared['data'] as List;
      int total = 0;
      for (final item in data) {
        total += (item['records'] as List).length;
      }
      setState(() {
        _totalPatients = data.length;
        _totalRecords  = total;
      });
    }

    setState(() => _isLoading = false);
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
        showLogo: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
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
            tooltip: 'Logout',
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
                        const SizedBox(height: 16),
                        _statsRow(),
                        const SizedBox(height: 24),
                        const Text('Patient Records',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 14),
                        _sharedRecordsCard(),
                        const SizedBox(height: 12),
                        _healthProfilesCard(),
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
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Dr.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _doctorName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  if (_specialization.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined,
                            size: 13, color: AppColors.accent),
                        const SizedBox(width: 5),
                        Text(_specialization,
                            style: const TextStyle(
                                color: AppColors.accent, fontSize: 13)),
                      ],
                    ),
                  ],
                  if (_organisation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _organisation,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            ProfileAvatar(
              profilePicture: _profilePicture,
              gender: _gender,
              role: 'doctor',
              radius: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(child: _statCard(
          '$_totalPatients', 'Patients',
          Icons.people_outline, AppColors.accentBlue,
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          '$_totalRecords', 'Records',
          Icons.folder_shared_outlined, const Color(0xFF1D9E75),
        )),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_shared,
                  color: AppColors.accentBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shared Records',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                    '$_totalRecords record${_totalRecords == 1 ? '' : 's'} from $_totalPatients patient${_totalPatients == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _healthProfilesCard() {
    return DarkListCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DoctorHealthProfileScreen()),
        );
        _loadData();
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A6E78).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.health_and_safety_outlined,
                  color: Color(0xFF0A6E78), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Patient Health Profiles',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  const Text(
                    'Request & view patient health profiles',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.accentBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: AppColors.accent, size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You can only view records and health profiles that patients have explicitly shared with you.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
