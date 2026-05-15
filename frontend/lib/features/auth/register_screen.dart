import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _organisationController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'patient';
  String? _selectedGender;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _organisationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final url = _selectedRole == 'patient'
        ? Constants.registerPatient
        : Constants.registerDoctor;

    // Doctor-specific fields are only included when the doctor role is selected.
    final body = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'phone_number': _phoneController.text.trim(),
      if (_selectedGender != null) 'gender': _selectedGender!,
      if (_selectedRole == 'doctor') ...{
        'specialization': _specializationController.text.trim(),
        'organisation_name': _organisationController.text.trim(),
      },
    };

    final response = await ApiService.post(url, body);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success'] == true) {
      if (response['requiresVerification'] == true) {
        final email = response['email'] ?? _emailController.text.trim();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(email: email, role: _selectedRole),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(response['message'] ?? 'Registration successful')),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response['message'] ?? 'Registration failed')),
      );
    }
  }

  Widget _roleButton(String role, String label, IconData icon) {
    final selected = _selectedRole == role;
    final c = AppThemeColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentBlue.withValues(alpha: 0.3)
                : c.textPrimary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.accentBlue
                  : c.textPrimary.withValues(alpha: 0.15),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? c.textPrimary : c.textSecondary,
                  size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? c.textPrimary : c.textSecondary,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderButton(String gender, String label, IconData icon) {
    final selected = _selectedGender == gender;
    final c = AppThemeColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentBlue.withValues(alpha: 0.3)
                : c.textPrimary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.accentBlue
                  : c.textPrimary.withValues(alpha: 0.15),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: selected ? c.textPrimary : c.textSecondary,
                  size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? c.textPrimary : c.textSecondary,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Scaffold(
      body: ColorfulBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: GlassCard(
                        borderRadius: 12,
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.arrow_back,
                            color: c.textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'I am a',
                          style: TextStyle(
                            color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.8),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _roleButton(
                                'patient', 'Patient', Icons.person),
                            const SizedBox(width: 12),
                            _roleButton('doctor', 'Doctor',
                                Icons.medical_services_outlined),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: GlassTextField(
                                controller: _firstNameController,
                                hintText: 'First name',
                                prefixIcon: Icons.person_outlined,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) { return 'Required'; }
                                  if (!RegExp(r"^[a-zA-Z][a-zA-Z\s'\-]*$").hasMatch(v.trim())) {
                                    return 'Letters, spaces, hyphens and apostrophes only';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassTextField(
                                controller: _lastNameController,
                                hintText: 'Last name',
                                prefixIcon: Icons.person_outlined,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) { return 'Required'; }
                                  if (!RegExp(r"^[a-zA-Z][a-zA-Z\s'\-]*$").hasMatch(v.trim())) {
                                    return 'Letters, spaces, hyphens and apostrophes only';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        GlassTextField(
                          controller: _emailController,
                          hintText: 'Email address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        GlassTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outlined,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.55),
                              size: 20,
                            ),
                            onPressed: () => setState(() =>
                                _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length < 8) return 'Minimum 8 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        GlassTextField(
                          controller: _phoneController,
                          hintText: 'Phone number (optional)',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) { return null; }
                            if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(v.trim())) {
                              return 'Digits, spaces, +, -, and () only';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Gender',
                          style: TextStyle(
                            color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.8),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _genderButton('male', 'Male', Icons.male),
                            const SizedBox(width: 12),
                            _genderButton('female', 'Female', Icons.female),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _genderButton('other', 'Other', Icons.person_outline),
                            const SizedBox(width: 12),
                            _genderButton('prefer_not_to_say', 'Prefer not to say', Icons.shield_outlined),
                          ],
                        ),
                        if (_selectedRole == 'doctor') ...[
                          const SizedBox(height: 14),
                          GlassTextField(
                            controller: _specializationController,
                            hintText: 'Specialization',
                            prefixIcon: Icons.work_outlined,
                          ),
                          const SizedBox(height: 14),
                          GlassTextField(
                            controller: _organisationController,
                            hintText: 'Organisation / Hospital',
                            prefixIcon: Icons.local_hospital_outlined,
                          ),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: GradientButton(
                            label: 'Create Account',
                            onPressed: _register,
                            isLoading: _isLoading,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: AppThemeColors.of(context).textPrimary.withValues(alpha: 0.65),
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppThemeColors.of(context).textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
