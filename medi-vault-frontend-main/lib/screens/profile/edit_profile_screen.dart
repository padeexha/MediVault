import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _organisationCtrl = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  String _role = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  static const _genders = ['male', 'female', 'other', 'prefer not to say'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _dobCtrl.dispose();
    _specializationCtrl.dispose();
    _organisationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.get(Constants.getProfile);
    if (!mounted) return;

    if (response['success'] == true) {
      final p = response['profile'] as Map<String, dynamic>;
      _role = p['role'] ?? '';
      _firstNameCtrl.text = p['first_name'] ?? '';
      _lastNameCtrl.text = p['last_name'] ?? '';
      _phoneCtrl.text = p['phone_number'] ?? '';

      if (_role == 'patient') {
        _addressCtrl.text = p['address'] ?? '';
        final rawGender = p['gender'] as String? ?? '';
        _gender = rawGender.isNotEmpty ? rawGender : null;
        if (p['date_of_birth'] != null) {
          final dob = DateTime.tryParse(p['date_of_birth'].toString());
          if (dob != null) {
            _dateOfBirth = dob;
            _dobCtrl.text =
                '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
          }
        }
      } else if (_role == 'doctor') {
        _specializationCtrl.text = p['specialization'] ?? '';
        _organisationCtrl.text = p['organisation_name'] ?? '';
      }

      setState(() => _isLoading = false);
    } else {
      setState(() {
        _error = response['message'] ?? 'Failed to load profile';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final body = <String, dynamic>{
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
    };

    if (_role == 'patient') {
      if (_dateOfBirth != null) {
        body['date_of_birth'] = _dateOfBirth!.toIso8601String();
      }
      if (_gender != null) body['gender'] = _gender;
      body['address'] = _addressCtrl.text.trim();
    } else if (_role == 'doctor') {
      body['specialization'] = _specializationCtrl.text.trim();
      body['organisation_name'] = _organisationCtrl.text.trim();
    }

    final response = await ApiService.put(Constants.updateProfile, body);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (response['success'] == true) {
      final user = await ApiService.getUser();
      if (user != null) {
        user['name'] =
            '${body['first_name']} ${body['last_name']}';
        await ApiService.saveUser(user);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                response['message'] ?? 'Failed to update profile')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobCtrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: darkGlassAppBar(title: 'Edit Profile'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.errorRed, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(color: AppColors.errorRed),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _loadProfile,
                        child: const Text('Try again',
                            style: TextStyle(color: AppColors.accent)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(
                            Icons.person_outline, 'Personal Information'),
                        const SizedBox(height: 12),
                        _field(_firstNameCtrl, 'First Name',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'First name is required'
                                : null),
                        const SizedBox(height: 12),
                        _field(_lastNameCtrl, 'Last Name',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Last name is required'
                                : null),
                        const SizedBox(height: 12),
                        _field(_phoneCtrl, 'Phone Number',
                            keyboardType: TextInputType.phone),
                        if (_role == 'patient') ...[
                          const SizedBox(height: 24),
                          _sectionHeader(
                              Icons.medical_information_outlined,
                              'Health Information'),
                          const SizedBox(height: 12),
                          // Date of Birth with stored controller
                          GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: _field(
                                _dobCtrl,
                                'Date of Birth',
                                suffix: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _gender,
                            dropdownColor: AppColors.bgCard,
                            style: const TextStyle(color: Colors.white),
                            decoration: darkInputDecoration('Gender'),
                            items: _genders.map((g) {
                              return DropdownMenuItem(
                                value: g,
                                child: Text(_capitalize(g)),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _gender = v),
                          ),
                          const SizedBox(height: 12),
                          _field(_addressCtrl, 'Address', maxLines: 2),
                        ],
                        if (_role == 'doctor') ...[
                          const SizedBox(height: 24),
                          _sectionHeader(Icons.badge_outlined,
                              'Professional Credentials'),
                          const SizedBox(height: 12),
                          _field(_specializationCtrl, 'Specialization',
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Specialization is required'
                                      : null),
                          const SizedBox(height: 12),
                          _field(_organizationCtrl,
                              'Organisation / Hospital',
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Organisation name is required'
                                      : null),
                        ],
                        const SizedBox(height: 32),
                        DarkButton(
                          label: 'Save Changes',
                          onPressed: _save,
                          isLoading: _isSaving,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  // alias so the reference in the doctor block compiles
  TextEditingController get _organizationCtrl => _organisationCtrl;

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: darkInputDecoration(label, suffix: suffix),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
