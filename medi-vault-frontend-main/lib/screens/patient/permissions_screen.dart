import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/marquee_text.dart';

const _primaryGreen = Color(0xFF10B981);
const _surfaceGreen = Color(0xFFECFDF5);
const _blue = Color(0xFF3B82F6);
const _dark = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _inputFill = Color(0xFFF1F5F9);
const _white = Color(0xFFFFFFFF);

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
    if (!mounted) return;
    setState(() {
      _permissions = response['success'] == true
          ? (response['permissions'] ?? [])
          : [];
      _isLoading = false;
    });
  }

  Future<void> _revokeAccess(String permissionId, String doctorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text(
          'Are you sure you want to revoke access for $doctorName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final response = await ApiService.put(
      '${Constants.permissions}/revoke/$permissionId',
      {},
    );

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access revoked successfully')),
      );
      _loadPermissions();
    }
  }

  Future<void> _showGrantDialog() async {
    final granted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _GrantAccessSheet(),
    );

    if (granted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access granted successfully')),
      );
      _loadPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Access')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _permissions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.manage_accounts_outlined,
                    size: 64,
                    color: Colors.grey[350],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No doctors have access yet',
                    style: TextStyle(
                      color: _dark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the + button to grant access to a doctor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPermissions,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _permissions.length,
                itemBuilder: (context, index) {
                  final permission = _permissions[index];
                  final provider = permission['provider_id'];
                  final user = provider?['user_id'];
                  final doctorName = user != null
                      ? '${user['first_name']} ${user['last_name']}'
                      : 'Unknown Doctor';
                  final email = user?['email'] ?? '';
                  final specialization = provider?['specialization'] ?? '';
                  final organisationName =
                      provider?['organisation_name'] ?? '';
                  final scope = permission['scope_type'] ?? 'all';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _surfaceGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          color: _primaryGreen,
                        ),
                      ),
                      title: Text(
                        doctorName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(email),
                          if (specialization.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              specialization,
                              style: const TextStyle(color: _muted),
                            ),
                          ],
                          if (organisationName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              organisationName,
                              style: const TextStyle(color: _muted),
                            ),
                          ],
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _surfaceGreen,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              scope == 'all'
                                  ? 'Full access'
                                  : 'Category: ${permission['shared_category'] ?? ''}',
                              style: const TextStyle(
                                color: _primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () =>
                            _revokeAccess(permission['_id'], doctorName),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGrantDialog,
        backgroundColor: _primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Grant access bottom sheet ─────────────────────────────────────────────────

class _GrantAccessSheet extends StatefulWidget {
  const _GrantAccessSheet();

  @override
  State<_GrantAccessSheet> createState() => _GrantAccessSheetState();
}

class _GrantAccessSheetState extends State<_GrantAccessSheet> {
  static const _defaultHospitals = [
    'Apollo Hospital Colombo',
    'Asiri Central Hospital',
    'Asiri Surgical Hospital',
    'Base Hospital Kurunegala',
    'District General Hospital Batticaloa',
    'District General Hospital Galle',
    'District General Hospital Matara',
    'District General Hospital Ratnapura',
    'Durdans Hospital',
    'Hemas Hospital Colombo',
    'Hemas Hospital Wattala',
    'Lady Ridgeway Hospital',
    'Lanka Hospital',
    'Nawaloka Hospital',
    'National Hospital of Sri Lanka',
    'Ninewells Hospital',
    "Sirimavo Bandaranaike Children's Hospital",
    'Sri Jayewardenepura General Hospital',
    'Teaching Hospital Jaffna',
    'Teaching Hospital Kandy',
    'Teaching Hospital Karapitiya',
    'Teaching Hospital Kurunegala',
    'Teaching Hospital Ratnapura',
  ];

  static const _defaultSpecializations = [
    'Anesthesiology',
    'Cardiology',
    'Dermatology',
    'Emergency Medicine',
    'Endocrinology',
    'ENT (Ear, Nose & Throat)',
    'Family Medicine',
    'Gastroenterology',
    'General Medicine',
    'General Surgery',
    'Gynecology & Obstetrics',
    'Hematology',
    'Infectious Diseases',
    'Nephrology',
    'Neurology',
    'Oncology',
    'Ophthalmology',
    'Orthopedic Surgery',
    'Pediatrics',
    'Plastic Surgery',
    'Psychiatry',
    'Pulmonology',
    'Radiology',
    'Rheumatology',
    'Urology',
  ];

  final _searchController = TextEditingController();
  final List<Map<String, String>> _categories = const [
    {'value': 'lab_report', 'label': 'Lab Report'},
    {'value': 'prescription', 'label': 'Prescription'},
    {'value': 'radiology', 'label': 'Radiology'},
    {'value': 'discharge_summary', 'label': 'Discharge Summary'},
    {'value': 'other', 'label': 'Other'},
  ];

  List<dynamic> _doctors = [];
  List<String> _hospitals = [];
  List<String> _specializations = [];
  bool _isLoadingDoctors = true;
  bool _isGranting = false;
  String _selectedScope = 'all';
  String _selectedCategory = 'lab_report';
  String? _selectedHospital;
  String? _selectedSpecialization;
  Map<String, dynamic>? _selectedDoctor;
  String _searchError = '';

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoadingDoctors = true;
      _searchError = '';
    });

    final queryParameters = <String, String>{};
    if (_selectedHospital != null && _selectedHospital!.isNotEmpty) {
      queryParameters['organisation_name'] = _selectedHospital!;
    }
    if (_selectedSpecialization != null &&
        _selectedSpecialization!.isNotEmpty) {
      queryParameters['specialization'] = _selectedSpecialization!;
    }
    if (_searchController.text.trim().isNotEmpty) {
      queryParameters['search'] = _searchController.text.trim();
    }

    final uri = Uri.parse(Constants.doctors);
    final url = queryParameters.isEmpty
        ? uri.toString()
        : uri.replace(queryParameters: queryParameters).toString();
    final response = await ApiService.get(url);

    if (!mounted) return;

    if (response['success'] == true) {
      final doctors = response['doctors'] ?? [];
      final selectedUserId = _selectedDoctor?['user_id'];
      Map<String, dynamic>? matchingDoctor;
      for (final doctor in doctors) {
        if (doctor is Map<String, dynamic> &&
            doctor['user_id'] == selectedUserId) {
          matchingDoctor = doctor;
          break;
        }
      }

      final apiHospitals = List<String>.from(
        response['filters']?['hospitals'] ?? [],
      );
      final apiSpecializations = List<String>.from(
        response['filters']?['specializations'] ?? [],
      );

      setState(() {
        _doctors = doctors;
        _hospitals =
            apiHospitals.isNotEmpty ? apiHospitals : _defaultHospitals;
        _specializations = apiSpecializations.isNotEmpty
            ? apiSpecializations
            : _defaultSpecializations;
        _selectedDoctor = matchingDoctor;
        _isLoadingDoctors = false;
      });
    } else {
      final statusCode = response['statusCode'] as int?;
      setState(() {
        _doctors = [];
        _hospitals = _defaultHospitals;
        _specializations = _defaultSpecializations;
        _selectedDoctor = null;
        _searchError = statusCode == 404
            ? ''
            : (response['message'] ?? 'Unable to load doctors');
        _isLoadingDoctors = false;
      });
    }
  }

  Future<void> _grantAccess() async {
    if (_selectedDoctor == null) {
      setState(() => _searchError = 'Please select a doctor');
      return;
    }

    setState(() {
      _isGranting = true;
      _searchError = '';
    });

    final response = await ApiService.post(Constants.grantPermission, {
      'provider_user_id': _selectedDoctor!['user_id'],
      'scope_type': _selectedScope,
      if (_selectedScope == 'category') 'shared_category': _selectedCategory,
    });

    if (!mounted) return;

    setState(() => _isGranting = false);

    if (response['success'] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _searchError = response['message'] ?? 'Failed to grant access';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Grant Doctor Access',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a doctor by hospital and specialization, then set the access scope.',
                style: TextStyle(color: _muted, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Hospital + Specialization filter pickers
              Row(
                children: [
                  Expanded(
                    child: _FilterPicker(
                      placeholder: 'All hospitals',
                      icon: Icons.local_hospital_outlined,
                      value: _selectedHospital,
                      options: _hospitals,
                      onChanged: (v) async {
                        setState(() => _selectedHospital = v);
                        await _loadDoctors();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FilterPicker(
                      placeholder: 'All specialties',
                      icon: Icons.badge_outlined,
                      value: _selectedSpecialization,
                      options: _specializations,
                      onChanged: (v) async {
                        setState(() => _selectedSpecialization = v);
                        await _loadDoctors();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search doctor',
                        hintText: 'Name or email',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _loadDoctors(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoadingDoctors ? null : _loadDoctors,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(70, 56),
                    ),
                    child: _isLoadingDoctors
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.tune),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Text(
                'Available Doctors',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: _isLoadingDoctors
                    ? const Center(child: CircularProgressIndicator())
                    : _doctors.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                        ),
                        child: Text(
                          _searchController.text.trim().isNotEmpty ||
                                  _selectedHospital != null ||
                                  _selectedSpecialization != null
                              ? 'No doctors found. Try a different name or adjust the filters.'
                              : 'No doctors found. Search by name or email to find a doctor.',
                          style: const TextStyle(color: _muted),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _doctors.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doctor =
                              _doctors[index] as Map<String, dynamic>;
                          final isSelected =
                              _selectedDoctor?['user_id'] ==
                              doctor['user_id'];
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedDoctor = doctor),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? _surfaceGreen : _white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? _primaryGreen
                                      : _border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _white
                                          : _surfaceGreen,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.medical_information_outlined,
                                      color: _primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doctor['name'] ?? 'Doctor',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: _dark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          doctor['specialization'] ?? '',
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          doctor['organisation_name'] ?? '',
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          doctor['email'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: _primaryGreen,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 18),
              const Text(
                'Access Scope',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'all',
                    label: Text('All records'),
                    icon: Icon(Icons.folder_open_outlined),
                  ),
                  ButtonSegment<String>(
                    value: 'category',
                    label: Text('By category'),
                    icon: Icon(Icons.category_outlined),
                  ),
                ],
                selected: {_selectedScope},
                onSelectionChanged: (selection) {
                  setState(() => _selectedScope = selection.first);
                },
              ),
              if (_selectedScope == 'category') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Select category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category['value'],
                          child: Text(category['label']!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
              ],
              if (_searchError.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _searchError,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isGranting ? null : _grantAccess,
                child: _isGranting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Grant Access'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter picker — constrained tappable field that opens a bottom-sheet list ─

class _FilterPicker extends StatelessWidget {
  final String placeholder;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _FilterPicker({
    required this.placeholder,
    required this.icon,
    required this.options,
    required this.onChanged,
    this.value,
  });

  void _open(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterPickerSheet(
        title: placeholder,
        options: options,
        selected: value,
      ),
    ).then((result) {
      if (result == null) return;
      onChanged(result == '__clear__' ? null : result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFFEFF6FF) : _inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? _blue : _border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: hasValue ? _blue : _muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: hasValue
                  ? MarqueeText(
                      text: value!,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Text(
                      placeholder,
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: hasValue ? _blue : _muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPickerSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String? selected;

  const _FilterPickerSheet({
    required this.title,
    required this.options,
    this.selected,
  });

  @override
  State<_FilterPickerSheet> createState() => _FilterPickerSheetState();
}

class _FilterPickerSheetState extends State<_FilterPickerSheet> {
  late List<String> _filtered;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _filter(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? widget.options
          : widget.options
              .where((o) => o.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: _filter,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final isAll = widget.selected == null;
                    return ListTile(
                      title: Text(
                        'All ${widget.title.toLowerCase()}',
                        style: TextStyle(
                          color: isAll ? _blue : _dark,
                          fontWeight:
                              isAll ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isAll
                          ? const Icon(
                              Icons.check_rounded,
                              color: _blue,
                              size: 20,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, '__clear__'),
                    );
                  }
                  final opt = _filtered[i - 1];
                  final isSelected = opt == widget.selected;
                  return ListTile(
                    title: Text(
                      opt,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? _blue : _dark,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: _blue,
                            size: 20,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, opt),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
