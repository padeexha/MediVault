import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({super.key});

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<dynamic> _doctors = [];
  List<String> _hospitals = [];
  List<String> _specializations = [];
  String? _selectedHospital;
  String? _selectedSpec;
  bool _isLoading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController
      ..removeListener(_onTabChange)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedHospital = null;
      _selectedSpec = null;
    });
    _loadDoctors();
  }

  void _debounceSearch(String value) {
    setState(() => _searchText = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _loadDoctors);
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    final params = <String>[];
    if (_selectedHospital != null) {
      params.add('organisation_name=${Uri.encodeComponent(_selectedHospital!)}');
    }
    if (_selectedSpec != null) {
      params.add('specialization=${Uri.encodeComponent(_selectedSpec!)}');
    }
    if (_searchText.trim().isNotEmpty) {
      params.add('search=${Uri.encodeComponent(_searchText.trim())}');
    }
    final url = params.isEmpty
        ? Constants.doctors
        : '${Constants.doctors}?${params.join('&')}';

    final res = await ApiService.get(url);
    if (!mounted) return;
    if (res['success'] == true) {
      final filters = (res['filters'] as Map<String, dynamic>?) ?? {};
      setState(() {
        _doctors = (res['doctors'] as List?) ?? [];
        _hospitals = List<String>.from(filters['hospitals'] ?? []);
        _specializations = List<String>.from(filters['specializations'] ?? []);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // ── Doctor avatar ───────────────────────────────────────────────────────────

  static Widget _doctorAvatar(Map<String, dynamic> doctor, double size) {
    return ProfileAvatar(
      profilePicture: doctor['profile_picture'] as String?,
      gender: doctor['gender'] as String?,
      role: 'doctor',
      radius: size / 2,
    );
  }

  // ── Grant access sheet ──────────────────────────────────────────────────────

  Future<void> _showGrantSheet(Map<String, dynamic> doctor) async {
    String scope = 'all';
    String category = 'lab_report';
    const cats = [
      {'value': 'lab_report', 'label': 'Lab Report'},
      {'value': 'prescription', 'label': 'Prescription'},
      {'value': 'radiology', 'label': 'Radiology'},
      {'value': 'discharge_summary', 'label': 'Discharge Summary'},
      {'value': 'other', 'label': 'Other'},
    ];

    await showModalBottomSheet<void>(
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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      _doctorAvatar(doctor, 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor['name'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            if ((doctor['specialization'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(doctor['specialization'],
                                  style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 12)),
                            ],
                            if ((doctor['organisation_name'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(doctor['organisation_name'],
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Access Scope',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: RadioGroup<String>(
                    groupValue: scope,
                    onChanged: (v) => setSheet(() => scope = v!),
                    child: Column(
                      children: [
                        const RadioListTile<String>(
                          value: 'all',
                          activeColor: AppColors.accentBlue,
                          title: Text('All records',
                              style: TextStyle(color: Colors.white)),
                          subtitle: Text('Doctor can see all records',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ),
                        Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.08)),
                        const RadioListTile<String>(
                          value: 'category',
                          activeColor: AppColors.accentBlue,
                          title: Text('By category',
                              style: TextStyle(color: Colors.white)),
                          subtitle: Text(
                              'Doctor sees only a specific category',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (scope == 'category') ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF1E2D40)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButton<String>(
                      value: category,
                      isExpanded: true,
                      dropdownColor: AppColors.bgCard,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary),
                      items: cats
                          .map((c) => DropdownMenuItem<String>(
                                value: c['value'],
                                child: Text(c['label']!),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheet(() => category = v);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                DarkButton(
                  label: 'Grant Access',
                  onPressed: () async {
                    final body = <String, dynamic>{
                      'provider_user_id': doctor['user_id'],
                      'scope_type': scope,
                      if (scope == 'category')
                        'shared_category': category,
                    };
                    final res = await ApiService.post(
                        Constants.grantPermission, body);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['success'] == true
                          ? 'Access granted to ${doctor['name']}'
                          : res['message'] ?? 'Failed to grant access'),
                    ));
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: darkGlassAppBar(title: 'Find a Doctor'),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: darkInputDecoration(
                'Search by name or email',
                prefixIcon: Icons.search,
                suffix: _searchText.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _debounceSearch('');
                        },
                        child: const Icon(Icons.clear,
                            size: 18,
                            color: AppColors.textSecondary),
                      )
                    : null,
              ),
              onChanged: _debounceSearch,
            ),
          ),

          // Tabs: By Hospital / By Specialization
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TabBar(
                  controller: _tabController,
                  indicator: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accentBlue, AppColors.accent],
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.local_hospital_outlined, size: 16),
                      text: 'By Hospital',
                    ),
                    Tab(
                      icon: Icon(Icons.medical_services_outlined, size: 16),
                      text: 'By Specialization',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Filter dropdown (switches with tab)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context2, child) => _tabController.index == 0
                  ? _filterDropdown(
                      value: _selectedHospital,
                      items: _hospitals,
                      hint: 'All Hospitals',
                      icon: Icons.local_hospital_outlined,
                      onChanged: (v) {
                        setState(() => _selectedHospital = v);
                        _loadDoctors();
                      },
                    )
                  : _filterDropdown(
                      value: _selectedSpec,
                      items: _specializations,
                      hint: 'All Specializations',
                      icon: Icons.medical_services_outlined,
                      onChanged: (v) {
                        setState(() => _selectedSpec = v);
                        _loadDoctors();
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // Doctor list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent))
                : _doctors.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AppColors.accent,
                        backgroundColor: AppColors.bgCard,
                        onRefresh: _loadDoctors,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _doctors.length,
                          itemBuilder: (_, i) =>
                              _doctorCard(_doctors[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2D40)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButton<String?>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.bgCard,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down,
            color: AppColors.textSecondary),
        hint: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(hint,
                style: const TextStyle(
                    color: AppColors.textSecondary)),
          ],
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Row(
              children: [
                Icon(icon,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(hint,
                    style: const TextStyle(
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          ...items.map(
            (item) => DropdownMenuItem<String?>(
              value: item,
              child: Text(item,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _doctorCard(Map<String, dynamic> doctor) {
    final name = (doctor['name'] as String?) ?? 'Unknown';
    final spec = (doctor['specialization'] as String?) ?? '';
    final hosp = (doctor['organisation_name'] as String?) ?? '';

    return DarkListCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _doctorAvatar(doctor, 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  if (spec.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined,
                            size: 12, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(spec,
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  if (hosp.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_outlined,
                            size: 12,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(hosp,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showGrantSheet(doctor),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      AppColors.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accentBlue
                          .withValues(alpha: 0.4)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: AppColors.accentBlue, size: 18),
                    SizedBox(height: 3),
                    Text(
                      'Grant\nAccess',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No doctors found',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Try a different filter or search term',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
