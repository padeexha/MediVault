import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppColors {
  static const Color bg = Color(0xFF050C18);
  static const Color bgCard = Color(0xFF0A1628);
  static const Color bgSurface = Color(0xFF0F1A2E);
  static const Color blobBlue = Color(0xFF1240A0);
  static const Color blobTeal = Color(0xFF0A6E78);
  static const Color blobRed = Color(0xFF8B1020);
  static const Color blobGreen = Color(0xFF0B6E3E);
  static const Color accent = Color(0xFF00C8FF);
  static const Color accentBlue = Color(0xFF3D72E8);
  static const Color btnDark = Color(0xFF15202E);
  static const Color glass = Color(0x12FFFFFF);
  static const Color glassBorder = Color(0x22FFFFFF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8FA8C8);
  static const Color errorRed = Color(0xFFE53935);
  static const Color ecgGreen = Color(0xFF1DB954);
  static const Color medRed = Color(0xFFB71C1C);
}

// Colorful blob background for auth screens
class ColorfulBackground extends StatelessWidget {
  final Widget child;
  const ColorfulBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          Positioned(
            left: -100,
            top: size.height * 0.05,
            child: _blob(260, AppColors.blobBlue),
          ),
          Positioned(
            left: size.width * 0.15,
            top: -60,
            child: _blob(220, AppColors.blobGreen),
          ),
          Positioned(
            right: -80,
            top: size.height * 0.15,
            child: _blob(240, AppColors.blobRed),
          ),
          Positioned(
            left: size.width * 0.1,
            bottom: size.height * 0.0,
            child: _blob(180, AppColors.blobTeal),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.65), color.withValues(alpha: 0.0)],
          ),
        ),
      );
}

// Dark background with mesh for splash/inner screens
class DarkBackground extends StatelessWidget {
  final Widget child;
  const DarkBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050C18), Color(0xFF091520), Color(0xFF060E1A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -60,
            top: size.height * 0.2,
            child: _blob(200, AppColors.blobTeal),
          ),
          Positioned(
            right: -50,
            top: size.height * 0.3,
            child: _blob(180, AppColors.blobRed),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _MeshPainter()),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.38), color.withValues(alpha: 0.0)],
          ),
        ),
      );
}

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha:0.04)
      ..strokeWidth = 0.6;
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha:0.09)
      ..style = PaintingStyle.fill;

    _drawRegion(canvas, linePaint, dotPaint, 0, 0, size.width * 0.22, size.height);
    _drawRegion(canvas, linePaint, dotPaint, size.width * 0.78, 0, size.width, size.height);
  }

  void _drawRegion(Canvas canvas, Paint line, Paint dot,
      double x1, double y1, double x2, double y2) {
    const step = 36.0;
    final cols = ((x2 - x1) / step).ceil() + 1;
    final rows = ((y2 - y1) / step).ceil() + 1;
    final rng = Random(42);
    final pts = <Offset>[];

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final jx = (rng.nextDouble() - 0.5) * 10;
        final jy = (rng.nextDouble() - 0.5) * 10;
        pts.add(Offset(x1 + c * step + jx, y1 + r * step + jy));
      }
    }

    for (var i = 0; i < pts.length; i++) {
      for (var j = i + 1; j < pts.length; j++) {
        if ((pts[i] - pts[j]).distance < step * 1.6) {
          canvas.drawLine(pts[i], pts[j], line);
        }
      }
    }
    for (final p in pts) {
      canvas.drawCircle(p, 1.4, dot);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// Glass card
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final Color? color;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.blur = 20,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppColors.glass,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.glassBorder,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Glass-styled text field
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: obscureText ? 1 : maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.45)),
            prefixIcon: Icon(prefixIcon,
                color: Colors.white.withValues(alpha:0.55), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha:0.10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha:0.18)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha:0.18)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha:0.5), width: 1.2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.errorRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.errorRed),
            ),
            errorStyle: const TextStyle(color: AppColors.errorRed),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }
}

// Gradient border dark button (Sign In style)
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppColors.accentBlue, AppColors.blobRed],
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Material(
          color: AppColors.btnDark,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Solid dark button for inner screens
class DarkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const DarkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// MediVault logo widget
class MediVaultLogo extends StatelessWidget {
  final double scale;
  const MediVaultLogo({super.key, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: 70 * scale,
      fit: BoxFit.contain,
    );
  }
}

// Glass AppBar for inner screens
AppBar darkGlassAppBar({
  required String title,
  List<Widget>? actions,
  bool implyLeading = true,
  bool showLogo = false,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    title: showLogo
        ? Image.asset(
            'assets/images/logo.png',
            height: 36,
            fit: BoxFit.contain,
          )
        : Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
    iconTheme: const IconThemeData(color: Colors.white),
    actionsIconTheme: const IconThemeData(color: Colors.white),
    actions: actions,
    automaticallyImplyLeading: implyLeading,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.05),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha:0.08)),
            ),
          ),
        ),
      ),
    ),
  );
}

// Dark-styled list card
class DarkListCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const DarkListCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha:0.07)),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: child,
            )
          : child,
    );
  }
}

// Profile avatar: shows network image or gender-based local asset fallback
class ProfileAvatar extends StatelessWidget {
  final String? profilePicture;
  final String? gender;
  final String role; // 'patient' | 'doctor'
  final double radius;

  const ProfileAvatar({
    super.key,
    this.profilePicture,
    this.gender,
    required this.role,
    this.radius = 24,
  });

  String get _fallbackAsset {
    final isFemale = gender?.toLowerCase() == 'female';
    if (role == 'doctor') {
      return isFemale
          ? 'assets/images/female_doctor.png'
          : 'assets/images/male_doctor.png';
    }
    return isFemale
        ? 'assets/images/female_user.png'
        : 'assets/images/male_user.png';
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final url = profilePicture;

    Widget inner;
    if (url != null && url.isNotEmpty) {
      inner = CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, url2) =>
            Image.asset(_fallbackAsset, fit: BoxFit.cover),
        errorWidget: (_, url2, err) =>
            Image.asset(_fallbackAsset, fit: BoxFit.cover),
      );
    } else {
      inner = Image.asset(_fallbackAsset, fit: BoxFit.cover);
    }

    return ClipOval(child: SizedBox(width: size, height: size, child: inner));
  }
}

// Dark input decoration for inner screens
InputDecoration darkInputDecoration(String label, {IconData? prefixIcon, Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
        : null,
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.bgSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF1E2D40)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF1E2D40)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.errorRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.errorRed),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
