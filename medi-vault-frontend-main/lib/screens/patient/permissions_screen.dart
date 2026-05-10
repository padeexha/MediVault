import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  List<dynamic> _permissions = [];
  bool _isLoading = true;

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
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text('Revoke access for $doctorName?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Revoke'),
          ),
        ],
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

  Future<void> _showGrantDialog() async {
    final emailController = TextEditingController();
    String selectedScope = 'all';
    String selectedCategory = 'lab_report';
    Map<String, dynamic>? foundDoctor;
    bool isSearching = false;
    String searchError = '';

    final categories = [
      {'value': 'lab_report', 'label': 'Lab Report'},
      {'value': 'prescription', 'label': 'Prescription'},
      {'value': 'radiology', 'label': 'Radiology'},
      {'value': 'discharge_summary', 'label': 'Discharge Summary'},
      {'value': 'other', 'label': 'Other'},
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
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
                                    searchError = res['message'] ?? 'Doctor not found';
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
                                width: 18, height: 18,
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
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
                      items: categories.map((cat) {
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
                          ? '${user['first_name']} ${user['last_name']}'
                          : 'Unknown Doctor';
                      final email = user?['email'] ?? '';
                      final scope = perm['scope_type'] ?? 'all';
                      return DarkListCard(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.medical_services,
                                color: AppColors.accentBlue),
                          ),
                          title: Text(doctorName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(email,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.12),
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
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent),
                            onPressed: () =>
                                _revokeAccess(perm['_id'], doctorName),
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
