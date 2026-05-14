import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/health_profile_model.dart';

class DoctorHealthProfileScreen extends StatefulWidget {
  const DoctorHealthProfileScreen({super.key});

  @override
  State<DoctorHealthProfileScreen> createState() =>
      _DoctorHealthProfileScreenState();
}

class _DoctorHealthProfileScreenState extends State<DoctorHealthProfileScreen> {
  List<Map<String, dynamic>> _accessList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get(Constants.healthProfileMyAccess);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _accessList = List<Map<String, dynamic>>.from(res['data'] ?? []);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewProfile(
      String patientId, String patientName) async {
    setState(() => _isLoading = true);
    final res = await ApiService.get(Constants.healthProfileView(patientId));
    setState(() => _isLoading = false);
    if (!mounted) return;

    if (res['success'] == true && res['profile'] != null) {
      final profile = HealthProfileModel.fromJson(
          res['profile'] as Map<String, dynamic>);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ProfileViewScreen(
              profile: profile, patientName: patientName),
        ),
      );
    } else {
      _showSnackBar(res['message'] ?? 'Could not load profile', isError: true);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.redAccent : AppColors.ecgGreen,
                size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg, style: TextStyle(color: AppThemeColors.of(context).textPrimary))),
          ],
        ),
        backgroundColor: AppThemeColors.of(context).bgSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':  return Colors.orange;
      case 'approved': return AppColors.ecgGreen;
      case 'rejected': return Colors.redAccent;
      case 'revoked':  return AppThemeColors.of(context).textSecondary;
      default:         return AppThemeColors.of(context).textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':  return Icons.hourglass_empty;
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'revoked':  return Icons.block;
      default:         return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.of(context).bg,
      appBar: darkGlassAppBar(context: context, title: 'Patient Health Profiles'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _accessList.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.health_and_safety_outlined,
                            size: 72,
                            color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.15)),
                        const SizedBox(height: 20),
                        Text('No Health Profiles Shared',
                            style: TextStyle(
                                color: AppThemeColors.of(context).textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          'No patients have shared their health profile with you yet. Patients control access to their own health profiles.',
                          style: TextStyle(
                              color: AppThemeColors.of(context).textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppThemeColors.of(context).bgCard,
                  onRefresh: _loadAccess,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _accessList.length,
                    itemBuilder: (_, i) {
                      final item    = _accessList[i];
                      final status  = item['status'] as String? ?? 'pending';
                      final name    = item['patient_name'] as String? ?? 'Unknown Patient';
                      final email   = item['patient_email'] as String? ?? '';
                      final patId   = item['patient_id']?.toString() ?? '';
                      final picture = item['patient_picture'] as String?;
                      final gender  = item['patient_gender'] as String?;
                      final color   = _statusColor(status);

                      return DarkListCard(
                        onTap: status == 'approved'
                            ? () => _viewProfile(patId, name)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [
                                    color.withValues(alpha: 0.6),
                                    color.withValues(alpha: 0.3),
                                  ]),
                                ),
                                child: ProfileAvatar(
                                  profilePicture: picture,
                                  gender: gender,
                                  role: 'patient',
                                  radius: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: TextStyle(
                                            color: AppThemeColors.of(context).textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    if (email.isNotEmpty)
                                      Text(email,
                                          style: TextStyle(
                                              color: AppThemeColors.of(context).textSecondary,
                                              fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_statusIcon(status),
                                                  color: color, size: 11),
                                              const SizedBox(width: 4),
                                              Text(
                                                status[0].toUpperCase() +
                                                    status.substring(1),
                                                style: TextStyle(
                                                    color: color,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (status == 'approved')
                                Icon(Icons.arrow_forward_ios,
                                    size: 14,
                                    color: AppThemeColors.of(context).textSecondary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Read-only profile view for doctors ────────────────────────────────────────
class _ProfileViewScreen extends StatelessWidget {
  final HealthProfileModel profile;
  final String patientName;

  const _ProfileViewScreen(
      {required this.profile, required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.of(context).bg,
      appBar: darkGlassAppBar(context: context, title: '$patientName\'s Health Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.ecgGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.ecgGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.verified_user_outlined,
                      color: AppColors.ecgGreen, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'You have approved access to this profile',
                    style: TextStyle(
                        color: AppColors.ecgGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _infoCard(context, 'Basic Information', Icons.person_outline, [
              _row(context, 'Full Name', profile.fullName),
              _row(context, 'Age', profile.age?.toString() ?? '—'),
              _row(context, 'Gender', profile.gender.isEmpty ? '—' : profile.gender),
            ]),
            const SizedBox(height: 12),
            _infoCard(context, 'Physical Stats', Icons.monitor_heart_outlined, [
              _row(context, 'Height', profile.height.isEmpty ? '—' : profile.height),
              _row(context, 'Weight', profile.weight.isEmpty ? '—' : profile.weight),
              _row(context, 'Blood Group',
                  profile.bloodGroup.isEmpty ? '—' : profile.bloodGroup),
            ]),
            if (profile.allergies.isNotEmpty ||
                profile.currentMedications.isNotEmpty ||
                profile.chronicConditions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _medCard(context, profile),
            ],
            const SizedBox(height: 12),
            _infoCard(context, 'Emergency Contact', Icons.emergency_outlined, [
              _row(context, 'Name',
                  profile.emergencyContactName.isEmpty
                      ? '—'
                      : profile.emergencyContactName),
              _row(context, 'Number',
                  profile.emergencyContactNumber.isEmpty
                      ? '—'
                      : profile.emergencyContactNumber),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, String title, IconData icon, List<Widget> rows) {
    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 15, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ]),
            const SizedBox(height: 14),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final c = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _medCard(BuildContext context, HealthProfileModel p) {
    final c = AppThemeColors.of(context);
    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.medical_information_outlined,
                  size: 15, color: AppColors.accent),
              SizedBox(width: 8),
              Text('Medical Information',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ]),
            if (p.allergies.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Allergies',
                  style: TextStyle(color: c.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _chips(p.allergies, Colors.redAccent),
            ],
            if (p.currentMedications.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Medications',
                  style: TextStyle(color: c.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _chips(p.currentMedications, AppColors.accentBlue),
            ],
            if (p.chronicConditions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Chronic Conditions',
                  style: TextStyle(color: c.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _chips(p.chronicConditions, const Color(0xFF854F0B)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chips(List<String> items, Color color) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map((item) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Text(item,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );
  }
}
