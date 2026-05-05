import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

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

  // Patient-specific
  final _addressCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;

  // Doctor-specific
  final _specializationCtrl = TextEditingController();
  final _organisationCtrl = TextEditingController();

  String _role = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  static const _primaryColor = Color(0xFF0F6E56);

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
    _specializationCtrl.dispose();
    _organisationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
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
        _gender = (p['gender'] as String?)?.isNotEmpty == true ? p['gender'] : null;
        if (p['date_of_birth'] != null) {
          _dateOfBirth = DateTime.tryParse(p['date_of_birth'].toString());
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
      // Refresh cached name
      final user = await ApiService.getUser();
      if (user != null) {
        user['name'] = '${body['first_name']} ${body['last_name']}';
        await ApiService.saveUser(user);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: _primaryColor,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          icon: Icons.person_outline,
                          title: 'Personal Information',
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _firstNameCtrl,
                          label: 'First Name',
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'First name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _lastNameCtrl,
                          label: 'Last Name',
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Last name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _phoneCtrl,
                          label: 'Phone Number',
                          keyboardType: TextInputType.phone,
                        ),
                        if (_role == 'patient') ..._patientFields(),
                        if (_role == 'doctor') ..._doctorFields(),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  List<Widget> _patientFields() {
    return [
      const SizedBox(height: 24),
      _SectionHeader(icon: Icons.medical_information_outlined, title: 'Health Information'),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _pickDate,
        child: AbsorbPointer(
          child: _buildField(
            controller: TextEditingController(
              text: _dateOfBirth == null
                  ? ''
                  : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
            ),
            label: 'Date of Birth',
            suffixIcon: Icons.calendar_today_outlined,
          ),
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _gender,
        decoration: _inputDecoration('Gender'),
        items: _genders
            .map((g) => DropdownMenuItem(
                  value: g,
                  child: Text(_capitalize(g)),
                ))
            .toList(),
        onChanged: (v) => setState(() => _gender = v),
      ),
      const SizedBox(height: 12),
      _buildField(
        controller: _addressCtrl,
        label: 'Address',
        maxLines: 2,
      ),
    ];
  }

  List<Widget> _doctorFields() {
    return [
      const SizedBox(height: 24),
      _SectionHeader(icon: Icons.badge_outlined, title: 'Professional Credentials'),
      const SizedBox(height: 12),
      _buildField(
        controller: _specializationCtrl,
        label: 'Specialization',
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Specialization is required' : null,
      ),
      const SizedBox(height: 12),
      _buildField(
        controller: _organisationCtrl,
        label: 'Organisation / Hospital',
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Organisation name is required' : null,
      ),
    ];
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    IconData? suffixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(label, suffixIcon: suffixIcon),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F6E56)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F6E56),
          ),
        ),
      ],
    );
  }
}
