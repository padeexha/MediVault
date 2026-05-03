import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/patient/patient_dashboard.dart';
import 'screens/doctor/doctor_dashboard.dart';

const _appLogo = 'assets/images/MediVault Logo.png';
const _primaryBlue = Color(0xFF3B82F6);
const _secondaryGreen = Color(0xFF10B981);
const _backgroundWhite = Color(0xFFFFFFFF);
const _backgroundGrey = Color(0xFFF8FAFC);
const _inputFill = Color(0xFFF1F5F9);
const _surfaceBlue = Color(0xFFEFF6FF);
const _surfaceGreen = Color(0xFFECFDF5);
const _textDark = Color(0xFF0F172A);
const _mutedText = Color(0xFF64748B);
const _alertRed = Color(0xFFEF4444);
const _warningOrange = Color(0xFFF59E0B);
const _borderGrey = Color(0xFFE2E8F0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MediVaultApp());
}

class MediVaultApp extends StatelessWidget {
  const MediVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medi Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: _primaryBlue,
          secondary: _secondaryGreen,
          surface: _backgroundWhite,
          error: _alertRed,
          onPrimary: _backgroundWhite,
          onSecondary: _backgroundWhite,
          onSurface: _textDark,
          onError: _backgroundWhite,
        ),
        scaffoldBackgroundColor: _backgroundGrey,
        textTheme: ThemeData.light().textTheme.copyWith(
          headlineSmall: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
          titleLarge: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(color: _textDark, height: 1.4),
          bodyMedium: const TextStyle(color: _mutedText, height: 1.4),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _backgroundWhite,
          foregroundColor: _primaryBlue,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: _backgroundWhite,
          elevation: 0,
          margin: EdgeInsets.zero,
          shadowColor: const Color(0x142F80ED),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _borderGrey),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBlue,
            foregroundColor: _backgroundWhite,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _secondaryGreen,
            side: const BorderSide(color: _secondaryGreen),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _secondaryGreen,
          foregroundColor: _backgroundWhite,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: _textDark,
          contentTextStyle: TextStyle(color: _backgroundWhite),
          actionTextColor: _warningOrange,
          behavior: SnackBarBehavior.floating,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _borderGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _borderGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _alertRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _alertRed, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          labelStyle: const TextStyle(color: _mutedText, fontSize: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _surfaceBlue,
          selectedColor: _surfaceGreen,
          disabledColor: _borderGrey,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: const TextStyle(
            color: _backgroundWhite,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: _borderGrey),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _primaryBlue,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _primaryBlue,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: _backgroundWhite,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerColor: _borderGrey,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _textSlide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();
    _checkSession();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    final token = await ApiService.getToken();
    final user = await ApiService.getUser();
    if (!mounted) return;
    if (token != null && user != null) {
      final role = user['role'] ?? '';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'doctor'
              ? const DoctorDashboard()
              : role == 'patient'
                  ? const PatientDashboard()
                  : const LoginScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
            colors: [
              Color(0xFF1D4ED8),
              Color(0xFF3B82F6),
              Color(0xFF0284C7),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Opacity(
                        opacity: _fade.value,
                        child: Transform.scale(
                          scale: _scale.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Image.asset(_appLogo, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Text
                      Opacity(
                        opacity: _fade.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Column(
                            children: [
                              const Text(
                                'MediVault',
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your health records, secured.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 72),
                      // Loading dots
                      const _PulsingDots(),
                    ],
                  );
                },
              ),
            ),
            // Version tag
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      );
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, _) {
            final v = _controllers[i].value;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 9,
              height: 9 + v * 10,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5 + v * 0.5),
                borderRadius: BorderRadius.circular(5),
              ),
            );
          },
        );
      }),
    );
  }
}
