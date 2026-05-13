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

  Future<void> _requestAccess() async {
    final emailCtrl = TextEditingController();
    bool isRequesting = false;
    String? errorMsg;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              const Text('Request Health Profile Access',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "Enter the patient's email address to request access to their health profile. The patient will need to approve your request.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: darkInputDecoration("Patient's email address",
                    prefixIcon: Icons.email_outlined),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(errorMsg!,
                    style: const TextStyle(
                        color: AppColors.errorRed, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              DarkButton(
                label: 'Send Request',
                icon: Icons.send_outlined,
                isLoading: isRequesting,
                onPressed: () async {
                  final email = emailCtrl.text.trim();
                  if (email.isEmpty) {
                    setSheet(() => errorMsg = 'Please enter an email address');
                    return;
                  }
                  setSheet(() {
                    isRequesting = true;
                    errorMsg = null;
                  });
                  final res = await ApiService.post(
                    Constants.healthProfileRequestAccess,
                    {'patient_email': email},
                  );
                  if (!ctx.mounted) return;
                  if (res['success'] == true) {
                    Navigator.pop(ctx);
                    _showSnackBar(
                        'Access request sent! Waiting for patient approval.',
                        isError: false);
                    _loadAccess();
                  } else {
                    setSheet(() {
                      isRequesting = false;
                      errorMsg = res['message'] ?? 'Failed to send request';
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
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
                child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.bgSurface,
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
      case 'revoked':  return AppColors.textSecondary;
      default:         return AppColors.textSecondary;
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
      backgroundColor: AppColors.bg,
      appBar: darkGlassAppBar(title: 'Patient Health Profiles'),
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              colors: [AppColors.accentBlue, AppColors.accent]),
        ),
        child: FloatingActionButton(
          onPressed: _requestAccess,
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: 'Request access to a patient profile',
          child: const Icon(Icons.person_add_outlined, color: Colors.white),
        ),
      ),
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
                            color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 20),
                        const Text('No Health Profiles Yet',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap the + button to request access to a patient\'s health profile. The patient must approve before you can view it.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.bgCard,
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
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    if (email.isNotEmpty)
                                      Text(email,
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
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
                                const Icon(Icons.arrow_forward_ios,
                                    size: 14,
                                    color: AppColors.textSecondary),
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
      backgroundColor: AppColors.bg,
      appBar: darkGlassAppBar(title: '$patientName\'s Health Profile'),
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
            _infoCard('Basic Information', Icons.person_outline, [
              _row('Full Name', profile.fullName),
              _row('Age', profile.age?.toString() ?? '—'),
              _row('Gender', profile.gender.isEmpty ? '—' : profile.gender),
            ]),
            const SizedBox(height: 12),
            _infoCard('Physical Stats', Icons.monitor_heart_outlined, [
              _row('Height', profile.height.isEmpty ? '—' : profile.height),
              _row('Weight', profile.weight.isEmpty ? '—' : profile.weight),
              _row('Blood Group',
                  profile.bloodGroup.isEmpty ? '—' : profile.bloodGroup),
            ]),
            if (profile.allergies.isNotEmpty ||
                profile.currentMedications.isNotEmpty ||
                profile.chronicConditions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _medCard(profile),
            ],
            const SizedBox(height: 12),
            _infoCard('Emergency Contact', Icons.emergency_outlined, [
              _row('Name',
                  profile.emergencyContactName.isEmpty
                      ? '—'
                      : profile.emergencyContactName),
              _row('Number',
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

  Widget _infoCard(String title, IconData icon, List<Widget> rows) {
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _medCard(HealthProfileModel p) {
    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
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
              const Text('Allergies',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _chips(p.allergies, Colors.redAccent),
            ],
            if (p.currentMedications.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Medications',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _chips(p.currentMedications, AppColors.accentBlue),
            ],
            if (p.chronicConditions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Chronic Conditions',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
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
