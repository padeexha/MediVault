import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/record_model.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'upload_record_screen.dart';
import 'record_list_screen.dart';
import 'record_detail_screen.dart';
import 'permissions_screen.dart';
import 'audit_log_screen.dart';
import 'doctor_selection_screen.dart';
import 'health_profile_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  String _userName = '';
  String? _gender;
  String? _profilePicture;
  Map<String, int> _categoryCounts = {};
  int _totalRecords = 0;
  int _sharedWithDoctors = 0;
  int _profileCompletionPct = 0;
  List<RecordModel> _recentRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      ApiService.get(Constants.records),
      ApiService.get(Constants.getProfile),
      ApiService.get(Constants.myDoctors),
    ]);

    if (!mounted) return;

    final recordsRes  = results[0];
    final profileRes  = results[1];
    final permRes     = results[2];

    // Records
    List<RecordModel> records = [];
    if (recordsRes['success'] == true) {
      records = (recordsRes['records'] as List)
          .map((r) => RecordModel.fromJson(r))
          .toList();
    }
    records.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));

    // Category counts
    final counts = <String, int>{};
    for (final r in records) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }

    // Shared-with-doctors count
    int shared = 0;
    if (permRes['success'] == true) {
      final perms = permRes['permissions'] as List? ?? [];
      final hasFullAccess = perms.any((p) => p['scope_type'] == 'all');
      if (hasFullAccess) {
        shared = records.length;
      } else {
        final sharedCategories = perms
            .where((p) => p['scope_type'] == 'category')
            .map((p) => p['shared_category'] as String?)
            .whereType<String>()
            .toSet();
        shared = records
            .where((r) => sharedCategories.contains(r.category))
            .length;
      }
    }

    // Profile completion
    int completionPct = 0;
    String name = '';
    if (profileRes['success'] == true) {
      final p = profileRes['profile'] as Map<String, dynamic>;
      name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();

      final fields = [
        (p['first_name'] as String? ?? '').isNotEmpty,
        (p['last_name'] as String? ?? '').isNotEmpty,
        (p['phone_number'] as String? ?? '').isNotEmpty,
        (p['gender'] as String? ?? '').isNotEmpty,
        p['date_of_birth'] != null,
        (p['address'] as String? ?? '').isNotEmpty,
      ];
      completionPct =
          ((fields.where((f) => f).length / fields.length) * 100).round();

      setState(() {
        _gender         = p['gender'] as String?;
        _profilePicture = p['profile_picture'] as String?;
      });
    }

    final user = await ApiService.getUser();
    if (user != null && name.isEmpty) name = user['name'] ?? '';

    setState(() {
      _userName            = name;
      _categoryCounts      = counts;
      _totalRecords        = records.length;
      _sharedWithDoctors   = shared;
      _profileCompletionPct = completionPct;
      _recentRecords       = records.take(5).toList();
      _isLoading           = false;
    });
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
                        _summaryCards(),
                        if (_profileCompletionPct < 100) ...[
                          const SizedBox(height: 16),
                          _profileCompletionCard(),
                        ],
                        const SizedBox(height: 24),
                        const Text('Quick Actions',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 14),
                        _actionsGrid(),
                        if (_recentRecords.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Recently Added',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RecordListScreen()),
                                ),
                                child: const Text('See all',
                                    style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._recentRecords.map((r) => _recentRecordCard(r)),
                        ],
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              colors: [AppColors.accentBlue, AppColors.accent]),
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
          tooltip: 'Upload record',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // ── Welcome Card ──────────────────────────────────────────────────────────
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
                    'Welcome back,',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName.isNotEmpty ? _userName : 'Patient',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_totalRecords medical record${_totalRecords == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: AppColors.accent, fontSize: 13),
                  ),
                ],
              ),
            ),
            ProfileAvatar(
              profilePicture: _profilePicture,
              gender: _gender,
              role: 'patient',
              radius: 30,
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary stat cards ────────────────────────────────────────────────────
  Widget _summaryCards() {
    return Row(
      children: [
        Expanded(child: _statCard(
          icon: Icons.folder_copy_outlined,
          label: 'Total',
          value: '$_totalRecords',
          color: AppColors.accentBlue,
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          icon: Icons.share_outlined,
          label: 'Shared',
          value: '$_sharedWithDoctors',
          color: AppColors.ecgGreen,
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          icon: Icons.category_outlined,
          label: 'Categories',
          value: '${_categoryCounts.length}',
          color: const Color(0xFF534AB7),
        )),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
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

  // ── Profile completion card ───────────────────────────────────────────────
  Widget _profileCompletionCard() {
    return DarkListCard(
      onTap: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
        );
        if (updated == true) _loadData();
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle_outlined,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Complete your profile',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
                Text('$_profileCompletionPct%',
                    style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _profileCompletionPct / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.orange),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your date of birth, address, and other details',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick actions grid ────────────────────────────────────────────────────
  Widget _actionsGrid() {
    final actions = [
      _ActionItem(Icons.upload_file,     'Upload',       AppColors.accentBlue,       () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UploadRecordScreen()));
        _loadData();
      }),
      _ActionItem(Icons.folder_open,     'Records',      const Color(0xFF1D9E75), () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RecordListScreen()));
      }),
      _ActionItem(Icons.people,          'Manage Access',const Color(0xFF854F0B), () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PermissionsScreen()));
      }),
      _ActionItem(Icons.health_and_safety_outlined, 'Health Profile', const Color(0xFF0A6E78), () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HealthProfileScreen()));
      }),
      _ActionItem(Icons.history,         'Audit Log',    const Color(0xFF993C1D), () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AuditLogScreen()));
      }),
      _ActionItem(Icons.person_search,   'Find Doctor',  const Color(0xFF185FA5), () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DoctorSelectionScreen()));
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) => _ActionCard(item: actions[i]),
    );
  }

  // ── Recent record card ────────────────────────────────────────────────────
  Widget _recentRecordCard(RecordModel record) {
    final color = _categoryColor(record.category);
    return DarkListCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RecordDetailScreen(record: record)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_categoryIcon(record.category), color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _fileTypeBadge(record.fileType),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(record.uploadDate),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _fileTypeBadge(String fileType) {
    final isImage = fileType.contains('image') ||
        fileType == 'jpg' ||
        fileType == 'jpeg' ||
        fileType == 'png';
    final label = isImage ? 'IMG' : 'PDF';
    final color = isImage ? const Color(0xFF534AB7) : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'lab_report':       return const Color(0xFF185FA5);
      case 'prescription':     return const Color(0xFF1D9E75);
      case 'radiology':        return const Color(0xFF854F0B);
      case 'discharge_summary':return const Color(0xFF993C1D);
      default:                 return AppColors.textSecondary;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'lab_report':       return Icons.science;
      case 'prescription':     return Icons.medication;
      case 'radiology':        return Icons.image_search;
      case 'discharge_summary':return Icons.assignment;
      default:                 return Icons.description;
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month]}';
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
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
