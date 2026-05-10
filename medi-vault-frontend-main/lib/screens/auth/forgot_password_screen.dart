import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final response = await ApiService.post(
      Constants.forgotPassword,
      {'email': _emailController.text.trim()},
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (response['success'] == true) {
      setState(() => _emailSent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response['message'] ?? 'Something went wrong')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColorfulBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: GlassCard(
                        borderRadius: 12,
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: _emailSent ? _successView() : _formView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formView() {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: const Icon(Icons.lock_reset,
                  size: 48, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Forgot your password?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Enter your email and we\'ll send you a reset link.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          GlassTextField(
            controller: _emailController,
            hintText: 'Email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: 'Send Reset Link',
              onPressed: _sendResetEmail,
              isLoading: _isLoading,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Back to Login',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successView() {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(24),
            child: const Icon(Icons.mark_email_read_outlined,
                size: 60, color: AppColors.accent),
          ),
          const SizedBox(height: 28),
          const Text(
            'Email sent!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We sent a reset link to ${_emailController.text.trim()}. Check your inbox.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: 'Back to Login',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
