import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/health_profile_model.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen>
    with SingleTickerProviderStateMixin {
  HealthProfileModel? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  late TabController _tabCtrl;

  // Form controllers
  final _fullNameCtrl         = TextEditingController();
  final _ageCtrl              = TextEditingController();
  final _heightCtrl           = TextEditingController();
  final _weightCtrl           = TextEditingController();
  final _bloodGroupCtrl       = TextEditingController();
  final _emergencyNameCtrl    = TextEditingController();
  final _emergencyNumberCtrl  = TextEditingController();
  String _gender = '';
  final List<String> _allergies          = [];
  final List<String> _medications        = [];
  final List<String> _conditions         = [];
  final _allergyCtrl    = TextEditingController();
  final _medicationCtrl = TextEditingController();
  final _conditionCtrl  = TextEditingController();

  final _doctorSearchCtrl       = TextEditingController();
  List<dynamic> _doctorSearchResults = [];
  bool _isDoctorSearchLoading   = false;
  Timer? _doctorSearchDebounce;
  String _doctorSearchQuery     = '';

  static const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const _genders     = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _fullNameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyNumberCtrl.dispose();
    _allergyCtrl.dispose();
    _medicationCtrl.dispose();
    _conditionCtrl.dispose();
    _doctorSearchCtrl.dispose();
    _doctorSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get(Constants.healthProfileMyProfile);
    if (!mounted) return;
    if (res['success'] == true && res['profile'] != null) {
      final p = HealthProfileModel.fromJson(res['profile'] as Map<String, dynamic>);
      setState(() {
        _profile = p;
        _populateForm(p);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _populateForm(HealthProfileModel p) {
    _fullNameCtrl.text        = p.fullName;
    _ageCtrl.text             = p.age?.toString() ?? '';
    _heightCtrl.text          = p.height;
    _weightCtrl.text          = p.weight;
    _bloodGroupCtrl.text      = p.bloodGroup;
    _emergencyNameCtrl.text   = p.emergencyContactName;
    _emergencyNumberCtrl.text = p.emergencyContactNumber;
    _gender = p.gender;
    _allergies
      ..clear()
      ..addAll(p.allergies);
    _medications
      ..clear()
      ..addAll(p.currentMedications);
    _conditions
      ..clear()
      ..addAll(p.chronicConditions);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final body = {
      'full_name':                _fullNameCtrl.text.trim(),
      'age':                      int.tryParse(_ageCtrl.text.trim()),
      'gender':                   _gender,
      'height':                   _heightCtrl.text.trim(),
      'weight':                   _weightCtrl.text.trim(),
      'blood_group':              _bloodGroupCtrl.text.trim(),
      'allergies':                List<String>.from(_allergies),
      'current_medications':      List<String>.from(_medications),
      'chronic_conditions':       List<String>.from(_conditions),
      'emergency_contact_name':   _emergencyNameCtrl.text.trim(),
      'emergency_contact_number': _emergencyNumberCtrl.text.trim(),
    };
    final res = await ApiService.post(Constants.healthProfileSave, body);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (res['success'] == true) {
      _showSnackBar('Health profile saved successfully', isError: false);
      setState(() => _isEditing = false);
      _loadProfile();
    } else {
      _showSnackBar(res['message'] ?? 'Failed to save profile', isError: true);
    }
  }

  void _onDoctorSearch(String value) {
    setState(() => _doctorSearchQuery = value);
    _doctorSearchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _doctorSearchResults = []);
      return;
    }
    // 400ms debounce so searches don't fire on every keystroke
    _doctorSearchDebounce =
        Timer(const Duration(milliseconds: 400), _searchDoctors);
  }

  Future<void> _searchDoctors() async {
    final q = _doctorSearchQuery.trim();
    if (q.isEmpty) return;
    setState(() => _isDoctorSearchLoading = true);
    final res = await ApiService.get(
        '${Constants.doctors}?search=${Uri.encodeComponent(q)}');
    if (!mounted) return;
    setState(() {
      _isDoctorSearchLoading = false;
      _doctorSearchResults =
          res['success'] == true ? (res['doctors'] as List? ?? []) : [];
    });
  }

  Future<void> _grantAccessFromSearch(Map<String, dynamic> doctor) async {
    final email = doctor['email'] as String? ?? '';
    if (email.isEmpty) {
      _showSnackBar('Doctor email not found', isError: true);
      return;
    }
    final res = await ApiService.post(
        Constants.healthProfileGrantAccess, {'doctor_email': email});
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnackBar(
          res['message'] ?? 'Access granted successfully', isError: false);
      setState(() {
        _doctorSearchCtrl.clear();
        _doctorSearchQuery = '';
        _doctorSearchResults = [];
      });
      _loadProfile();
    } else {
      _showSnackBar(res['message'] ?? 'Failed to grant access', isError: true);
    }
  }

  Widget _doctorResultCard(Map<String, dynamic> doctor) {
    final name = doctor['name'] as String? ?? 'Unknown Doctor';
    final spec = doctor['specialization'] as String? ?? '';
    final org  = doctor['organisation_name'] as String? ?? '';
    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            ProfileAvatar(role: 'doctor', radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: AppThemeColors.of(context).textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (spec.isNotEmpty)
                    Text(spec,
                        style: const TextStyle(
                            color: AppColors.accentBlue, fontSize: 12)),
                  if (org.isNotEmpty)
                    Text(org,
                        style: TextStyle(
                            color: AppThemeColors.of(context).textSecondary, fontSize: 11)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _grantAccessFromSearch(doctor),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.15),
                foregroundColor: AppColors.accentBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Give Access',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest(String requestId, String doctorName) async {
    final confirmed = await _showConfirmDialog(
      title: 'Approve Access',
      content: 'Allow $doctorName to view your health profile?',
      confirmLabel: 'Approve',
      confirmColor: AppColors.ecgGreen,
    );
    if (confirmed != true) return;

    final res = await ApiService.put(Constants.healthProfileApprove(requestId), {});
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnackBar('Access approved for $doctorName', isError: false);
      _loadProfile();
    } else {
      _showSnackBar(res['message'] ?? 'Failed to approve', isError: true);
    }
  }

  Future<void> _rejectRequest(String requestId, String doctorName) async {
    final confirmed = await _showConfirmDialog(
      title: 'Reject Access',
      content: 'Deny $doctorName access to your health profile?',
      confirmLabel: 'Reject',
      confirmColor: Colors.redAccent,
    );
    if (confirmed != true) return;

    final res = await ApiService.put(Constants.healthProfileReject(requestId), {});
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnackBar('Access rejected', isError: false);
      _loadProfile();
    } else {
      _showSnackBar(res['message'] ?? 'Failed to reject', isError: true);
    }
  }

  Future<void> _revokeAccess(String requestId, String doctorName) async {
    final confirmed = await _showConfirmDialog(
      title: 'Revoke Access',
      content: 'Remove $doctorName\'s access to your health profile? They will no longer be able to view it.',
      confirmLabel: 'Revoke',
      confirmColor: Colors.redAccent,
    );
    if (confirmed != true) return;

    final res = await ApiService.put(Constants.healthProfileRevoke(requestId), {});
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnackBar('Access revoked from $doctorName', isError: false);
      _loadProfile();
    } else {
      _showSnackBar(res['message'] ?? 'Failed to revoke', isError: true);
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppThemeColors.of(context).bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.1)),
        ),
        title: Text(title,
            style: TextStyle(
                color: AppThemeColors.of(context).textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(content,
            style: TextStyle(color: AppThemeColors.of(context).textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppThemeColors.of(context).textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmLabel,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.redAccent : AppColors.ecgGreen, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: TextStyle(color: AppThemeColors.of(context).textPrimary))),
          ],
        ),
        backgroundColor: AppThemeColors.of(context).bgSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _addChip(List<String> list, String value, TextEditingController ctrl) {
    if (value.trim().isEmpty || list.contains(value.trim())) return;
    setState(() => list.add(value.trim()));
    ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _profile?.pendingRequestCount ?? 0;
    final approvedCount = _profile?.approvedDoctorCount ?? 0;

    return Scaffold(
      backgroundColor: AppThemeColors.of(context).bg,
      appBar: darkGlassAppBar(
        context: context,
        title: 'Health Profile',
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit profile',
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing) ...[
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
                if (_profile != null) _populateForm(_profile!);
              },
              child: Text('Cancel',
                  style: TextStyle(color: AppThemeColors.of(context).textSecondary)),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Column(
              children: [
                TabBar(
                  controller: _tabCtrl,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppThemeColors.of(context).textSecondary,
                  indicatorColor: AppColors.accentBlue,
                  tabs: [
                    const Tab(text: 'Profile'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Access'),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('$pendingCount',
                                  style: TextStyle(
                                      color: AppThemeColors.of(context).textPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildProfileTab(approvedCount),
                      _buildAccessTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isEditing
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              color: AppThemeColors.of(context).bgCard,
              child: DarkButton(
                label: 'Save Health Profile',
                icon: Icons.save_outlined,
                onPressed: _save,
                isLoading: _isSaving,
              ),
            )
          : null,
    );
  }

  Widget _buildProfileTab(int approvedCount) {
    final p = _profile;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditing && p != null) ...[
            _statusBanner(approvedCount),
            const SizedBox(height: 16),
          ],
          if (!_isEditing && p == null)
            _emptyProfileCard(),

          if (_isEditing) ...[
            _sectionHeader(Icons.person_outline, 'Basic Information'),
            const SizedBox(height: 12),
            _field(_fullNameCtrl, 'Full Name'),
            const SizedBox(height: 12),
            _field(_ageCtrl, 'Age', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _dropdownField(
              label: 'Gender',
              value: _gender.isEmpty ? null : _gender,
              items: _genders,
              onChanged: (v) => setState(() => _gender = v ?? ''),
            ),
            const SizedBox(height: 24),
            _sectionHeader(Icons.monitor_heart_outlined, 'Physical Stats'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_heightCtrl, 'Height (e.g. 175 cm)')),
                const SizedBox(width: 12),
                Expanded(child: _field(_weightCtrl, 'Weight (e.g. 70 kg)')),
              ],
            ),
            const SizedBox(height: 12),
            _dropdownField(
              label: 'Blood Group',
              value: _bloodGroupCtrl.text.isEmpty ? null : _bloodGroupCtrl.text,
              items: _bloodGroups,
              onChanged: (v) => setState(() => _bloodGroupCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 24),
            _sectionHeader(Icons.medical_information_outlined, 'Medical Information'),
            const SizedBox(height: 8),
            _chipSection('Allergies', _allergies, 'Add allergy...', _allergyCtrl),
            const SizedBox(height: 12),
            _chipSection('Current Medications', _medications, 'Add medication...', _medicationCtrl),
            const SizedBox(height: 12),
            _chipSection('Chronic Conditions', _conditions, 'Add condition...', _conditionCtrl),
            const SizedBox(height: 24),
            _sectionHeader(Icons.emergency_outlined, 'Emergency Contact'),
            const SizedBox(height: 12),
            _field(_emergencyNameCtrl, 'Contact Name'),
            const SizedBox(height: 12),
            _field(_emergencyNumberCtrl, 'Contact Number',
                keyboardType: TextInputType.phone),
            const SizedBox(height: 100),
          ] else if (p != null) ...[
            _infoSection('Basic Information', Icons.person_outline, [
              _InfoRow('Full Name', p.fullName),
              _InfoRow('Age', p.age?.toString() ?? '—'),
              _InfoRow('Gender', p.gender.isEmpty ? '—' : p.gender),
            ]),
            const SizedBox(height: 16),
            _infoSection('Physical Stats', Icons.monitor_heart_outlined, [
              _InfoRow('Height', p.height.isEmpty ? '—' : p.height),
              _InfoRow('Weight', p.weight.isEmpty ? '—' : p.weight),
              _InfoRow('Blood Group', p.bloodGroup.isEmpty ? '—' : p.bloodGroup),
            ]),
            const SizedBox(height: 16),
            if (p.allergies.isNotEmpty || p.currentMedications.isNotEmpty ||
                p.chronicConditions.isNotEmpty)
              _medicalSection(p),
            const SizedBox(height: 16),
            _infoSection('Emergency Contact', Icons.emergency_outlined, [
              _InfoRow('Contact Name',
                  p.emergencyContactName.isEmpty ? '—' : p.emergencyContactName),
              _InfoRow('Contact Number',
                  p.emergencyContactNumber.isEmpty ? '—' : p.emergencyContactNumber),
            ]),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildAccessTab() {
    final requests = _profile?.accessRequests ?? [];
    final pending  = requests.where((r) => r.isPending).toList();
    final approved = requests.where((r) => r.isApproved).toList();
    final others   = requests.where((r) => r.isRejected || r.isRevoked).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _doctorSearchCtrl,
                style: TextStyle(color: AppThemeColors.of(context).textPrimary),
                decoration: darkInputDecoration('Search doctors by name…', context: context,
                  prefixIcon: Icons.person_search_outlined,
                  suffix: _isDoctorSearchLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.accentBlue))
                      : _doctorSearchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _doctorSearchCtrl.clear();
                                setState(() {
                                  _doctorSearchQuery = '';
                                  _doctorSearchResults = [];
                                });
                              },
                              child: Icon(Icons.close,
                                  size: 16, color: AppThemeColors.of(context).textSecondary))
                          : null,
                ),
                onChanged: _onDoctorSearch,
              ),
              if (_doctorSearchQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
                if (_doctorSearchResults.isEmpty && !_isDoctorSearchLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No doctors found for "$_doctorSearchQuery"',
                      style: TextStyle(
                          color: AppThemeColors.of(context).textSecondary, fontSize: 13),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _doctorSearchResults.length,
                      itemBuilder: (_, i) => _doctorResultCard(
                          _doctorSearchResults[i] as Map<String, dynamic>),
                    ),
                  ),
                const Divider(color: Color(0xFF1E2D40)),
              ],
            ],
          ),
        ),
        Expanded(
          child: requests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 64,
                            color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('No Doctors Have Access',
                            style: TextStyle(
                                color: AppThemeColors.of(context).textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          _doctorSearchQuery.isEmpty
                              ? 'Search for a doctor above to give them access to your health profile.'
                              : 'Use the search results above to give a doctor access.',
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
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      if (pending.isNotEmpty) ...[
                        _requestSectionHeader(
                            'Pending', Colors.orange, pending.length),
                        ...pending.map((r) => _requestCard(r, showActions: true)),
                        const SizedBox(height: 16),
                      ],
                      if (approved.isNotEmpty) ...[
                        _requestSectionHeader(
                            'Approved Doctors', AppColors.ecgGreen, approved.length),
                        ...approved.map((r) => _requestCard(r, showRevoke: true)),
                        const SizedBox(height: 16),
                      ],
                      if (others.isNotEmpty) ...[
                        _requestSectionHeader(
                            'Previous', AppThemeColors.of(context).textSecondary, others.length),
                        ...others.map((r) => _requestCard(r)),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _requestSectionHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3, height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  color: AppThemeColors.of(context).textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(HealthProfileAccessRequest r,
      {bool showActions = false, bool showRevoke = false}) {
    Color statusColor;
    IconData statusIcon;
    switch (r.status) {
      case 'pending':  statusColor = Colors.orange;        statusIcon = Icons.hourglass_empty; break;
      case 'approved': statusColor = AppColors.ecgGreen;   statusIcon = Icons.check_circle;    break;
      case 'rejected': statusColor = Colors.redAccent;     statusIcon = Icons.cancel;          break;
      case 'revoked':  statusColor = AppThemeColors.of(context).textSecondary; statusIcon = Icons.block;        break;
      default:         statusColor = AppThemeColors.of(context).textSecondary; statusIcon = Icons.info;
    }

    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [AppColors.accentBlue, AppColors.accent]),
                  ),
                  child: ProfileAvatar(role: 'doctor', radius: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.doctorName.isNotEmpty ? r.doctorName : 'Unknown Doctor',
                          style: TextStyle(
                              color: AppThemeColors.of(context).textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                      if (r.doctorEmail.isNotEmpty)
                        Text(r.doctorEmail,
                            style: TextStyle(
                                color: AppThemeColors.of(context).textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        r.status[0].toUpperCase() + r.status.substring(1),
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Requested ${_formatDate(r.requestedAt)}',
                style: TextStyle(
                    color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.35), fontSize: 11),
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectRequest(r.id, r.doctorName),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveRequest(r.id, r.doctorName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ecgGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Approve',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
            if (showRevoke) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _revokeAccess(r.id, r.doctorName),
                  icon: const Icon(Icons.remove_circle_outline,
                      size: 16, color: Colors.redAccent),
                  label: const Text('Revoke Access',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBanner(int approvedCount) {
    final isShared = approvedCount > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isShared
              ? [AppColors.ecgGreen.withValues(alpha: 0.15), AppColors.ecgGreen.withValues(alpha: 0.05)]
              : [AppColors.accentBlue.withValues(alpha: 0.15), AppColors.accentBlue.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isShared
              ? AppColors.ecgGreen.withValues(alpha: 0.3)
              : AppColors.accentBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isShared ? Icons.lock_open : Icons.lock_outline,
            color: isShared ? AppColors.ecgGreen : AppColors.accentBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isShared
                  ? 'Profile shared with $approvedCount doctor${approvedCount == 1 ? '' : 's'}'
                  : 'Profile is private — no doctors have access',
              style: TextStyle(
                color: isShared ? AppColors.ecgGreen : AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppThemeColors.of(context).bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Icon(Icons.health_and_safety_outlined,
              size: 56, color: AppColors.accentBlue.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text('No Health Profile Yet',
              style: TextStyle(
                  color: AppThemeColors.of(context).textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Create your health profile to store your medical information. Doctors you approve can view this profile.',
            style: TextStyle(color: AppThemeColors.of(context).textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Health Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection(String title, IconData icon, List<_InfoRow> rows) {
    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 14),
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(row.label,
                            style: TextStyle(
                                color: AppThemeColors.of(context).textSecondary, fontSize: 13)),
                      ),
                      Expanded(
                        child: Text(row.value,
                            style: TextStyle(
                                color: AppThemeColors.of(context).textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _medicalSection(HealthProfileModel p) {
    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.medical_information_outlined,
                    size: 16, color: AppColors.accent),
                SizedBox(width: 8),
                Text('Medical Information',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            if (p.allergies.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Allergies',
                  style: TextStyle(
                      color: AppThemeColors.of(context).textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _chipDisplay(p.allergies, Colors.redAccent),
            ],
            if (p.currentMedications.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Current Medications',
                  style: TextStyle(color: AppThemeColors.of(context).textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _chipDisplay(p.currentMedications, AppColors.accentBlue),
            ],
            if (p.chronicConditions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Chronic Conditions',
                  style: TextStyle(color: AppThemeColors.of(context).textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _chipDisplay(p.chronicConditions, const Color(0xFF854F0B)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chipDisplay(List<String> items, Color color) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Text(item,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );
  }

  Widget _chipSection(String label, List<String> list, String hint,
      TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: AppThemeColors.of(context).textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: list
                  .map((item) => InputChip(
                        label: Text(item,
                            style: TextStyle(
                                color: AppThemeColors.of(context).textPrimary, fontSize: 12)),
                        backgroundColor: AppThemeColors.of(context).bgSurface,
                        side: BorderSide(
                            color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.15)),
                        deleteIconColor: Colors.white54,
                        onDeleted: () =>
                            setState(() => list.remove(item)),
                      ))
                  .toList(),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                style: TextStyle(color: AppThemeColors.of(context).textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                      color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.3),
                      fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.accentBlue, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppThemeColors.of(context).inputFill,
                ),
                onSubmitted: (v) => _addChip(list, v, ctrl),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _addChip(list, ctrl.text, ctrl),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accentBlue.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.add,
                    color: AppColors.accentBlue, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: AppThemeColors.of(context).textPrimary),
      decoration: darkInputDecoration(label, context: context),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemeColors.of(context).bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2D40)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: AppThemeColors.of(context).bgCard,
        style: TextStyle(color: AppThemeColors.of(context).textPrimary, fontSize: 15),
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.keyboard_arrow_down,
            color: AppThemeColors.of(context).textSecondary),
        hint: Text(label,
            style: TextStyle(color: AppThemeColors.of(context).textSecondary)),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}
