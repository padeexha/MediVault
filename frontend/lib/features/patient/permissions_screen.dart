import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  List<dynamic> _permissions = [];
  bool _isLoading = true;

  static const _categories = [
    {'value': 'lab_report', 'label': 'Lab Report'},
    {'value': 'prescription', 'label': 'Prescription'},
    {'value': 'radiology', 'label': 'Radiology'},
    {'value': 'discharge_summary', 'label': 'Discharge Summary'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    final response = await ApiService.get(Constants.myDoctors);
    if (response['success'] == true) {
      setState(() {
        _permissions = response['permissions'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeAccess(String permissionId, String doctorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _GlassDialog(
        title: 'Revoke Access',
        content: 'Remove $doctorName\'s access to your records?',
        confirmLabel: 'Revoke',
        confirmColor: Colors.redAccent,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
    if (confirmed == true) {
      final response = await ApiService.put(
          '${Constants.permissions}/revoke/$permissionId', {});
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access revoked successfully')),
        );
        _loadPermissions();
      }
    }
  }

  Future<void> _updatePermission(
      String permissionId, String scopeType, String? category) async {
    final body = <String, dynamic>{
      'scope_type': scopeType,
      if (scopeType == 'category' && category != null)
        'shared_category': category,
    };
    final response =
        await ApiService.put('${Constants.permissions}/$permissionId', body);
    if (!mounted) return;
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions updated successfully')),
      );
      _loadPermissions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(response['message'] ?? 'Failed to update permissions')),
      );
    }
  }

  void _showDoctorDetailSheet(Map<String, dynamic> perm) {
    final provider = perm['provider_id'];
    final user = provider?['user_id'];
    final doctorName = user != null
        ? '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim()
        : 'Unknown Doctor';
    final email = user?['email'] as String? ?? '';
    final specialization = provider?['specialization'] as String? ?? '';
    final organisation = provider?['organisation_name'] as String? ?? '';
    final profilePicture = user?['profile_picture'] as String?;
    final gender = user?['gender'] as String?;
    final permissionId = perm['_id'] as String;

    String selectedScope = perm['scope_type'] ?? 'all';
    String selectedCategory = perm['shared_category'] ?? 'lab_report';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _DoctorDetailSheet(
          doctorName: doctorName,
          email: email,
          specialization: specialization,
          organisation: organisation,
          profilePicture: profilePicture,
          gender: gender,
          selectedScope: selectedScope,
          selectedCategory: selectedCategory,
          isSaving: isSaving,
          categories: _categories,
          onScopeChanged: (v) => setSheet(() => selectedScope = v),
          onCategoryChanged: (v) => setSheet(() => selectedCategory = v),
          onSave: () async {
            setSheet(() => isSaving = true);
            await _updatePermission(permissionId, selectedScope,
                selectedScope == 'category' ? selectedCategory : null);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          onRevoke: () async {
            Navigator.pop(ctx);
            await _revokeAccess(permissionId, doctorName);
          },
        ),
      ),
    );
  }

  Future<void> _showGrantDialog() async {
    final emailController = TextEditingController();
    String selectedScope = 'all';
    String selectedCategory = 'lab_report';
    Map<String, dynamic>? foundDoctor;
    bool isSearching = false;
    String searchError = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grant Doctor Access',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: darkInputDecoration("Doctor's email",
                            prefixIcon: Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSearching
                            ? null
                            : () async {
                                if (emailController.text.trim().isEmpty) return;
                                setModal(() {
                                  isSearching = true;
                                  searchError = '';
                                  foundDoctor = null;
                                });
                                final res = await ApiService.get(
                                  '${Constants.searchDoctor}?email=${emailController.text.trim()}',
                                );
                                setModal(() {
                                  isSearching = false;
                                  if (res['success'] == true) {
                                    foundDoctor = res['doctor'];
                                  } else {
                                    searchError =
                                        res['message'] ?? 'Doctor not found';
                                  }
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.search, size: 20),
                      ),
                    ),
                  ],
                ),
                if (searchError.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(searchError,
                      style: const TextStyle(
                          color: AppColors.errorRed, fontSize: 13)),
                ],
                if (foundDoctor != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.accent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                foundDoctor!['name'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              if ((foundDoctor!['specialization'] ?? '')
                                  .isNotEmpty)
                                Text(foundDoctor!['specialization'],
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Access Scope',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: RadioGroup<String>(
                      groupValue: selectedScope,
                      onChanged: (v) => setModal(() => selectedScope = v!),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'all',
                            activeColor: AppColors.accentBlue,
                            title: const Text('All records',
                                style: TextStyle(color: Colors.white)),
                            subtitle: const Text('Doctor can see all records',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ),
                          Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08)),
                          RadioListTile<String>(
                            value: 'category',
                            activeColor: AppColors.accentBlue,
                            title: const Text('By category',
                                style: TextStyle(color: Colors.white)),
                            subtitle: const Text(
                                'Doctor sees only a specific category',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedScope == 'category') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: AppColors.bgCard,
                      style: const TextStyle(color: Colors.white),
                      decoration: darkInputDecoration('Select category',
                          prefixIcon: Icons.category),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat['value'],
                          child: Text(cat['label']!),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setModal(() => selectedCategory = v);
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  DarkButton(
                    label: 'Grant Access',
                    onPressed: () async {
                      final body = {
                        'provider_user_id': foundDoctor!['user_id'],
                        'scope_type': selectedScope,
                        if (selectedScope == 'category')
                          'shared_category': selectedCategory,
                      };
                      final response =
                          await ApiService.post(Constants.grantPermission, body);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (response['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Access granted successfully')),
                        );
                        _loadPermissions();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(response['message'] ??
                                  'Failed to grant access')),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: darkGlassAppBar(title: 'Manage Access'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _permissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      const Text('No doctors have access yet',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Tap + to grant a doctor access',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: _loadPermissions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _permissions.length,
                    itemBuilder: (_, i) {
                      final perm = _permissions[i];
                      final provider = perm['provider_id'];
                      final user = provider?['user_id'];
                      final doctorName = user != null
                          ? '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
                              .trim()
                          : 'Unknown Doctor';
                      final email = user?['email'] as String? ?? '';
                      final scope = perm['scope_type'] ?? 'all';
                      final profilePicture =
                          user?['profile_picture'] as String?;
                      final gender = user?['gender'] as String?;
                      final specialization =
                          provider?['specialization'] as String? ?? '';

                      return DarkListCard(
                        onTap: () => _showDoctorDetailSheet(perm),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Profile picture
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(colors: [
                                    AppColors.accentBlue,
                                    AppColors.accent,
                                  ]),
                                ),
                                child: ProfileAvatar(
                                  profilePicture: profilePicture,
                                  gender: gender,
                                  role: 'doctor',
                                  radius: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctorName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    if (specialization.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.medical_services_outlined,
                                              size: 11,
                                              color: AppColors.accent),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              specialization,
                                              style: const TextStyle(
                                                  color: AppColors.accent,
                                                  fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 3),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        scope == 'all'
                                            ? 'Full access'
                                            : scope == 'category'
                                                ? 'Category: ${perm['shared_category'] ?? ''}'
                                                : 'Specific record',
                                        style: const TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.textSecondary, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              colors: [AppColors.accentBlue, AppColors.accent]),
        ),
        child: FloatingActionButton(
          onPressed: _showGrantDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Doctor detail bottom sheet ─────────────────────────────────────────────

class _DoctorDetailSheet extends StatelessWidget {
  final String doctorName;
  final String email;
  final String specialization;
  final String organisation;
  final String? profilePicture;
  final String? gender;
  final String selectedScope;
  final String selectedCategory;
  final bool isSaving;
  final List<Map<String, String>> categories;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSave;
  final VoidCallback onRevoke;

  const _DoctorDetailSheet({
    required this.doctorName,
    required this.email,
    required this.specialization,
    required this.organisation,
    required this.profilePicture,
    required this.gender,
    required this.selectedScope,
    required this.selectedCategory,
    required this.isSaving,
    required this.categories,
    required this.onScopeChanged,
    required this.onCategoryChanged,
    required this.onSave,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.95),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Doctor profile header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentBlue.withValues(alpha: 0.15),
                        AppColors.accent.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accentBlue.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      // Avatar with gradient ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.accentBlue, AppColors.accent],
                          ),
                        ),
                        child: ProfileAvatar(
                          profilePicture: profilePicture,
                          gender: gender,
                          role: 'doctor',
                          radius: 34,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctorName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (specialization.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.medical_services_outlined,
                                      size: 12, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      specialization,
                                      style: const TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (organisation.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.local_hospital_outlined,
                                      size: 12,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      organisation,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.email_outlined,
                                      size: 12,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section title
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accentBlue, AppColors.accent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Access Permissions',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Scope radio buttons
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: RadioGroup<String>(
                    groupValue: selectedScope,
                    onChanged: (v) => onScopeChanged(v!),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'all',
                          activeColor: AppColors.accentBlue,
                          title: const Text('All records',
                              style: TextStyle(color: Colors.white)),
                          subtitle: const Text('Doctor can see all records',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ),
                        Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.08)),
                        RadioListTile<String>(
                          value: 'category',
                          activeColor: AppColors.accentBlue,
                          title: const Text('By category',
                              style: TextStyle(color: Colors.white)),
                          subtitle: const Text(
                              'Doctor sees only a specific category',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),

                if (selectedScope == 'category') ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF1E2D40)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: AppColors.bgCard,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary),
                      items: categories
                          .map((c) => DropdownMenuItem<String>(
                                value: c['value'],
                                child: Text(c['label']!),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) onCategoryChanged(v);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: isSaving
                            ? null
                            : const LinearGradient(
                                colors: [
                                  AppColors.accentBlue,
                                  AppColors.accent,
                                ],
                              ),
                        color: isSaving
                            ? AppColors.bgSurface
                            : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Revoke access button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: onRevoke,
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent, size: 18),
                    label: const Text(
                      'Revoke Access',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass alert dialog ─────────────────────────────────────────────────────

class _GlassDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _GlassDialog({
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(content,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onConfirm,
                      style: TextButton.styleFrom(foregroundColor: confirmColor),
                      child: Text(confirmLabel,
                          style: TextStyle(
                              color: confirmColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
