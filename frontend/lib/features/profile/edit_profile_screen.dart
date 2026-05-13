import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';

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
  String? _profilePicture;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPic = false;
  String? _error;

  static const _genders = [
    'male',
    'female',
    'other',
    'prefer_not_to_say',
  ];

  static const _genderLabels = {
    'male': 'Male',
    'female': 'Female',
    'other': 'Other',
    'prefer_not_to_say': 'Prefer not to say',
  };

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
      _profilePicture = p['profile_picture'] as String?;

      final rawGender = p['gender'] as String? ?? '';
      _gender = rawGender.isNotEmpty ? rawGender : null;

      if (_role == 'patient') {
        _addressCtrl.text = p['address'] ?? '';
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

  Future<void> _pickAndUploadPicture() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingPic = true);
    final file = File(picked.path);
    final response = await ApiService.uploadFile(
      Constants.updateProfilePicture,
      file,
      {},
    );
    if (!mounted) return;
    setState(() => _isUploadingPic = false);

    if (response['success'] == true) {
      setState(() => _profilePicture = response['profile_picture'] as String?);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(response['message'] ?? 'Failed to upload picture')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final body = <String, dynamic>{
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
      if (_gender != null) 'gender': _gender,
    };

    if (_role == 'patient') {
      if (_dateOfBirth != null) {
        body['date_of_birth'] = _dateOfBirth!.toIso8601String();
      }
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
        user['name'] = '${body['first_name']} ${body['last_name']}';
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
            content:
                Text(response['message'] ?? 'Failed to update profile')),
      );
    }
  }

  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> submit() async {
            final current = currentCtrl.text;
            final newPass = newCtrl.text;
            final confirm = confirmCtrl.text;
            if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Please fill in all fields')),
              );
              return;
            }
            if (newPass != confirm) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Passwords do not match')),
              );
              return;
            }
            if (newPass.length < 8) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Password must be at least 8 characters')),
              );
              return;
            }
            setSheet(() => isSaving = true);
            final response = await ApiService.put(
              Constants.changePassword,
              {'current_password': current, 'new_password': newPass},
            );
            if (!ctx.mounted) return;
            setSheet(() => isSaving = false);
            if (response['success'] == true) {
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed successfully')),
                );
              }
            } else {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(response['message'] ?? 'Failed to change password')),
              );
            }
          }

          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: currentCtrl,
                  obscureText: obscureCurrent,
                  style: const TextStyle(color: Colors.white),
                  decoration: darkInputDecoration(
                    'Current Password',
                    suffix: IconButton(
                      icon: Icon(
                        obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.55),
                        size: 20,
                      ),
                      onPressed: () => setSheet(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  style: const TextStyle(color: Colors.white),
                  decoration: darkInputDecoration(
                    'New Password',
                    suffix: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.55),
                        size: 20,
                      ),
                      onPressed: () => setSheet(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  style: const TextStyle(color: Colors.white),
                  decoration: darkInputDecoration(
                    'Confirm New Password',
                    suffix: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.55),
                        size: 20,
                      ),
                      onPressed: () => setSheet(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                DarkButton(
                  label: 'Change Password',
                  onPressed: submit,
                  isLoading: isSaving,
                ),
              ],
            ),
          );
        },
      ),
    );
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
                        // ── Profile picture ──
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  ProfileAvatar(
                                    profilePicture: _profilePicture,
                                    gender: _gender,
                                    role: _role,
                                    radius: 52,
                                  ),
                                  GestureDetector(
                                    onTap: _isUploadingPic
                                        ? null
                                        : _pickAndUploadPicture,
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.bg, width: 2),
                                      ),
                                      child: _isUploadingPic
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2),
                                            )
                                          : const Icon(Icons.camera_alt,
                                              size: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap camera to change photo',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Personal information ──
                        _sectionHeader(
                            Icons.person_outline, 'Personal Information'),
                        const SizedBox(height: 12),
                        _field(_firstNameCtrl, 'First Name',
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'First name is required'
                                    : null),
                        const SizedBox(height: 12),
                        _field(_lastNameCtrl, 'Last Name',
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Last name is required'
                                    : null),
                        const SizedBox(height: 12),
                        _field(_phoneCtrl, 'Phone Number',
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        // Gender — fully controlled, drives profile picture default
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF1E2D40)),
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButton<String>(
                            value: _gender,
                            isExpanded: true,
                            dropdownColor: AppColors.bgCard,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: AppColors.textSecondary),
                            hint: const Text('Select gender',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                            items: _genders.map((g) {
                              return DropdownMenuItem<String>(
                                value: g,
                                child: Text(_genderLabels[g] ?? g),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _gender = v),
                          ),
                        ),

                        if (_role == 'patient') ...[
                          const SizedBox(height: 24),
                          _sectionHeader(
                              Icons.medical_information_outlined,
                              'Health Information'),
                          const SizedBox(height: 12),
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
                          _field(_organisationCtrl,
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
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: _showChangePasswordSheet,
                            icon: const Icon(Icons.lock_outline,
                                size: 20, color: AppColors.accent),
                            label: const Text(
                              'Change Password',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.accent, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

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
}
