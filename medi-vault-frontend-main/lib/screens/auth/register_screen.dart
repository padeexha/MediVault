import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/marquee_text.dart';

const _appLogo = 'assets/images/MediVault Logo.png';
const _blue = Color(0xFF3B82F6);
const _green = Color(0xFF10B981);
const _bg = Color(0xFFF8FAFC);
const _white = Color(0xFFFFFFFF);
const _border = Color(0xFFE2E8F0);
const _muted = Color(0xFF64748B);
const _dark = Color(0xFF0F172A);
const _errClr = Color(0xFFEF4444);
const _inputFill = Color(0xFFF1F5F9);

const _hospitals = [
  'Apollo Hospital Colombo',
  'Asiri Central Hospital',
  'Asiri Surgical Hospital',
  'Base Hospital Kurunegala',
  'Chest Hospital Welisara',
  'De Soysa Hospital for Women',
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
  'National Institute of Mental Health',
  'Ninewells Hospital',
  "Sirimavo Bandaranaike Children's Hospital",
  'Sri Jayewardenepura General Hospital',
  'Teaching Hospital Jaffna',
  'Teaching Hospital Kandy',
  'Teaching Hospital Karapitiya',
  'Teaching Hospital Kurunegala',
  'Teaching Hospital Ratnapura',
];

const _specializations = [
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _customHospital = TextEditingController();
  final _customSpecialization = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String _role = 'patient';
  String? _hospital;
  String? _specialization;
  String? _hospitalError;
  String? _specializationError;

  String get _finalHospital =>
      _hospital == 'Other' ? _customHospital.text.trim() : (_hospital ?? '');

  String get _finalSpecialization => _specialization == 'Other'
      ? _customSpecialization.text.trim()
      : (_specialization ?? '');

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _customHospital.dispose();
    _customSpecialization.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_role == 'doctor') {
      bool doctorValid = true;
      if (_hospital == null) {
        setState(() => _hospitalError = 'Please select a hospital');
        doctorValid = false;
      } else if (_hospital == 'Other' && _customHospital.text.trim().isEmpty) {
        setState(() => _hospitalError = 'Please enter your hospital name');
        doctorValid = false;
      }
      if (_specialization == null) {
        setState(() => _specializationError = 'Please select a specialization');
        doctorValid = false;
      } else if (_specialization == 'Other' &&
          _customSpecialization.text.trim().isEmpty) {
        setState(
          () => _specializationError = 'Please enter your specialization',
        );
        doctorValid = false;
      }
      if (!doctorValid) return;
    }

    setState(() => _loading = true);

    final body = {
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'phone_number': _phone.text.trim(),
      if (_role == 'doctor') ...{
        'specialization': _finalSpecialization,
        'organisation_name': _finalHospital,
      },
    };

    final url =
        _role == 'patient' ? Constants.registerPatient : Constants.registerDoctor;
    final response = await ApiService.post(url, body);
    setState(() => _loading = false);
    if (!mounted) return;

    if (response['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Check your email'),
          content: const Text(
            'We sent a verification link to your email. Please verify before logging in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: _dark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(_appLogo, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'MediVault',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  'Create account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fill in your details to get started.',
                  style: TextStyle(fontSize: 14, color: _muted),
                ),

                const SizedBox(height: 24),

                // Role selector
                _SectionLabel('I am a'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RoleTile(
                        label: 'Patient',
                        icon: Icons.person_outline_rounded,
                        selected: _role == 'patient',
                        onTap: () => setState(() => _role = 'patient'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleTile(
                        label: 'Doctor',
                        icon: Icons.medical_services_outlined,
                        selected: _role == 'doctor',
                        onTap: () => setState(() => _role = 'doctor'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Personal info card
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Personal information'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              controller: _firstName,
                              label: 'First name',
                              icon: Icons.person_outline_rounded,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(
                              controller: _lastName,
                              label: 'Last name',
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _email,
                        label: 'Email address',
                        icon: Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 8) return 'At least 8 characters';
                          if (!RegExp(r'[a-z]').hasMatch(v)) {
                            return 'Add a lowercase letter';
                          }
                          if (!RegExp(r'[A-Z]').hasMatch(v)) {
                            return 'Add an uppercase letter';
                          }
                          if (!RegExp(r'[0-9]').hasMatch(v)) {
                            return 'Add a number';
                          }
                          if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
                            return 'Add a special character';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _phone,
                        label: 'Phone number (optional)',
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                      ),
                    ],
                  ),
                ),

                // Doctor-only fields
                if (_role == 'doctor') ...[
                  const SizedBox(height: 16),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Professional details'),
                        const SizedBox(height: 14),

                        _PickerField(
                          label: 'Hospital',
                          icon: Icons.local_hospital_outlined,
                          value: _hospital,
                          error: _hospitalError,
                          options: _hospitals,
                          onChanged: (v) => setState(() {
                            _hospital = v;
                            _hospitalError = null;
                            if (v != 'Other') _customHospital.clear();
                          }),
                        ),
                        if (_hospital == 'Other') ...[
                          const SizedBox(height: 12),
                          _Field(
                            controller: _customHospital,
                            label: 'Enter hospital name',
                            icon: Icons.edit_outlined,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Please enter your hospital name'
                                    : null,
                          ),
                        ],

                        const SizedBox(height: 12),

                        _PickerField(
                          label: 'Specialization',
                          icon: Icons.work_outline_rounded,
                          value: _specialization,
                          error: _specializationError,
                          options: _specializations,
                          onChanged: (v) => setState(() {
                            _specialization = v;
                            _specializationError = null;
                            if (v != 'Other') _customSpecialization.clear();
                          }),
                        ),
                        if (_specialization == 'Other') ...[
                          const SizedBox(height: 12),
                          _Field(
                            controller: _customSpecialization,
                            label: 'Enter specialization',
                            icon: Icons.edit_outlined,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Please enter your specialization'
                                    : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Account'),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(color: _muted, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _muted,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.icon,
    this.keyboard,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      ),
      validator: validator,
    );
  }
}

// ── Picker field — opens a bottom-sheet list, MarqueeText in a constrained box
class _PickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final String? error;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _PickerField({
    required this.label,
    required this.icon,
    required this.options,
    required this.onChanged,
    this.value,
    this.error,
  });

  String get _display =>
      value == null ? '' : (value == 'Other' ? 'Other — type below' : value!);

  Future<void> _open(BuildContext context) async {
    final allOptions = [...options, 'Other — type below'];
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        label: label,
        options: allOptions,
        selected: value == 'Other' ? 'Other — type below' : value,
      ),
    );
    if (result != null) {
      onChanged(result == 'Other — type below' ? 'Other' : result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _open(context),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: error != null ? _errClr : _border,
                width: error != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: hasValue ? _blue : _muted),
                const SizedBox(width: 12),
                Expanded(
                  child: hasValue
                      ? MarqueeText(
                          text: _display,
                          style: const TextStyle(color: _dark, fontSize: 14),
                        )
                      : Text(
                          label,
                          style: const TextStyle(color: _muted, fontSize: 14),
                        ),
                ),
                const Icon(Icons.expand_more_rounded, color: _muted, size: 20),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 14),
            child: Text(
              error!,
              style: const TextStyle(color: _errClr, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _PickerSheet extends StatefulWidget {
  final String label;
  final List<String> options;
  final String? selected;

  const _PickerSheet({
    required this.label,
    required this.options,
    this.selected,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
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
                    'Select ${widget.label}',
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
                maxHeight: MediaQuery.of(context).size.height * 0.42,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final opt = _filtered[i];
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

class _RoleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? _blue : _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _blue : _border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? _white : _green, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? _white : _dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
