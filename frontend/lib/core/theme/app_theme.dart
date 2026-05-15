import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Accent and status colors that are the same in both dark and light themes.
// For surface/background colors that change with the theme, use AppThemeColors.of(context).
class AppColors {
  static const Color accent      = Color(0xFF00C8FF);
  static const Color accentBlue  = Color(0xFF3D72E8);
  static const Color errorRed    = Color(0xFFE53935);
  static const Color ecgGreen    = Color(0xFF1DB954);
  static const Color medRed      = Color(0xFFB71C1C);
  static const Color blobBlue    = Color(0xFF1240A0);
  static const Color blobTeal    = Color(0xFF0A6E78);
  static const Color blobRed     = Color(0xFF8B1020);
  static const Color blobGreen   = Color(0xFF0B6E3E);

  // Dark-mode fallbacks kept for const contexts (e.g. static decorations).
  // Prefer AppThemeColors.of(context) in widgets so light mode works correctly.
  static const Color bg           = Color(0xFF050C18);
  static const Color bgCard       = Color(0xFF0A1628);
  static const Color bgSurface    = Color(0xFF0F1A2E);
  static const Color textPrimary  = Colors.white;
  static const Color textSecondary= Color(0xFF8FA8C8);
  static const Color glass        = Color(0x12FFFFFF);
  static const Color glassBorder  = Color(0x22FFFFFF);
  static const Color btnDark      = Color(0xFF15202E);
}

// Theme-aware color palette. Use AppThemeColors.of(context) in widgets.
class AppThemeColors {
  final Color bg;
  final Color bgCard;
  final Color bgSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color glass;
  final Color glassBorder;
  final Color inputBorder;
  final Color inputFill;
  final Color cardBorder;
  final Color divider;
  final Color btnSurface;
  final Color dropdownColor;

  const AppThemeColors({
    required this.bg,
    required this.bgCard,
    required this.bgSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.glass,
    required this.glassBorder,
    required this.inputBorder,
    required this.inputFill,
    required this.cardBorder,
    required this.divider,
    required this.btnSurface,
    required this.dropdownColor,
  });

  static const AppThemeColors dark = AppThemeColors(
    bg:            Color(0xFF050C18),
    bgCard:        Color(0xFF0A1628),
    bgSurface:     Color(0xFF0F1A2E),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8FA8C8),
    glass:         Color(0x12FFFFFF),
    glassBorder:   Color(0x22FFFFFF),
    inputBorder:   Color(0xFF1E2D40),
    inputFill:     Color(0xFF0F1A2E),
    cardBorder:    Color(0x12FFFFFF),
    divider:       Color(0x18FFFFFF),
    btnSurface:    Color(0xFF15202E),
    dropdownColor: Color(0xFF0A1628),
  );

  static const AppThemeColors light = AppThemeColors(
    bg:            Color(0xFFF0F4FF),
    bgCard:        Color(0xFFE4EAF8),
    bgSurface:     Color(0xFFD8E1F2),
    textPrimary:   Color(0xFF0D1B2A),
    textSecondary: Color(0xFF5A7090),
    glass:         Color(0xCCFFFFFF),
    glassBorder:   Color(0x609BB8D4),
    inputBorder:   Color(0xFFB8C8DC),
    inputFill:     Color(0xFFDCE5F5),
    cardBorder:    Color(0x30000000),
    divider:       Color(0x22000000),
    btnSurface:    Color(0xFFD8E1F2),
    dropdownColor: Color(0xFFE4EAF8),
  );

  static AppThemeColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}

// Radial gradient blob background used on login and register screens.
class ColorfulBackground extends StatelessWidget {
  final Widget child;
  const ColorfulBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: c.bg,
      child: Stack(
        children: [
          Positioned(
            left: -100,
            top: size.height * 0.05,
            child: _blob(260, AppColors.blobBlue, isDark),
          ),
          Positioned(
            left: size.width * 0.15,
            top: -60,
            child: _blob(220, AppColors.blobGreen, isDark),
          ),
          Positioned(
            right: -80,
            top: size.height * 0.15,
            child: _blob(240, AppColors.blobRed, isDark),
          ),
          Positioned(
            left: size.width * 0.1,
            bottom: size.height * 0.0,
            child: _blob(180, AppColors.blobTeal, isDark),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(double size, Color color, bool isDark) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: isDark ? 0.65 : 0.35),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      );
}

// Gradient + mesh background used on inner screens (dashboard, records, etc.).
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF050C18), Color(0xFF091520), Color(0xFF060E1A)]
              : [c.bg, c.bgCard, c.bg],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -60,
            top: size.height * 0.2,
            child: _blob(200, AppColors.blobTeal, isDark),
          ),
          Positioned(
            right: -50,
            top: size.height * 0.3,
            child: _blob(180, AppColors.blobRed, isDark),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _MeshPainter(isDark: isDark)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(double size, Color color, bool isDark) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: isDark ? 0.38 : 0.18),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      );
}

// Alias kept so splash screen and any other callers don't need updating
typedef DarkBackground = AppBackground;

// Draws a dot-grid mesh on the left and right edges of the screen.
// Random(42) seeds the jitter so the pattern stays stable across repaints.
class _MeshPainter extends CustomPainter {
  final bool isDark;
  const _MeshPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final lineAlpha = isDark ? 0.04 : 0.06;
    final dotAlpha  = isDark ? 0.09 : 0.12;
    final baseColor = isDark ? Colors.white : const Color(0xFF3D72E8);

    final linePaint = Paint()
      ..color = baseColor.withValues(alpha: lineAlpha)
      ..strokeWidth = 0.6;
    final dotPaint = Paint()
      ..color = baseColor.withValues(alpha: dotAlpha)
      ..style = PaintingStyle.fill;

    // Only paint the side columns so the center content area stays clean
    _drawRegion(canvas, linePaint, dotPaint, 0, 0, size.width * 0.22, size.height);
    _drawRegion(canvas, linePaint, dotPaint, size.width * 0.78, 0, size.width, size.height);
  }

  void _drawRegion(Canvas canvas, Paint line, Paint dot,
      double x1, double y1, double x2, double y2) {
    const step = 36.0;
    final cols = ((x2 - x1) / step).ceil() + 1;
    final rows = ((y2 - y1) / step).ceil() + 1;
    final rng  = Random(42);
    final pts  = <Offset>[];

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        // Small random jitter makes the grid look organic rather than rigid
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
  bool shouldRepaint(_MeshPainter old) => old.isDark != isDark;
}

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
    final c = AppThemeColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? c.glass,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? c.glassBorder,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Blurred glass text field used on auth screens
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
    final c = AppThemeColors.of(context);
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
          style: TextStyle(color: c.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: c.textPrimary.withValues(alpha: 0.45)),
            prefixIcon: Icon(prefixIcon,
                color: c.textPrimary.withValues(alpha: 0.55), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: c.textPrimary.withValues(alpha: 0.10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.textPrimary.withValues(alpha: 0.18)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.textPrimary.withValues(alpha: 0.18)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: c.textPrimary.withValues(alpha: 0.5), width: 1.2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.errorRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.errorRed),
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

// Gradient-border button used on auth screens.
// The gradient lives on the outer Container; the interior is a solid surface color.
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
    final c = AppThemeColors.of(context);
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
          color: c.btnSurface,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: c.textPrimary, strokeWidth: 2),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: c.textPrimary,
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

// Solid blue action button for inner screens
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

// Frosted-glass app bar for inner screens.
// The blur effect requires BackdropFilter inside flexibleSpace.
AppBar darkGlassAppBar({
  required String title,
  List<Widget>? actions,
  bool implyLeading = true,
  bool showLogo = false,
  BuildContext? context,
}) {
  final isDark = context != null
      ? Theme.of(context).brightness == Brightness.dark
      : true;
  final textColor = isDark ? Colors.white : const Color(0xFF0D1B2A);
  final bgColor   = isDark
      ? Colors.white.withValues(alpha: 0.05)
      : Colors.white.withValues(alpha: 0.70);
  final borderColor = isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.08);

  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    title: showLogo
        ? Image.asset('assets/images/logo.png', height: 36, fit: BoxFit.contain)
        : Text(title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
    iconTheme: IconThemeData(color: textColor),
    actionsIconTheme: IconThemeData(color: textColor),
    actions: actions,
    automaticallyImplyLeading: implyLeading,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
        ),
      ),
    ),
  );
}

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
    final c = AppThemeColors.of(context);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
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

// Displays a user's profile picture with a gender/role-based fallback asset
class ProfileAvatar extends StatelessWidget {
  final String? profilePicture;
  final String? gender;
  final String role;
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
    final url  = profilePicture;

    Widget inner;
    if (url != null && url.isNotEmpty) {
      inner = CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Image.asset(_fallbackAsset, fit: BoxFit.cover),
        errorWidget: (_, __, ___) =>
            Image.asset(_fallbackAsset, fit: BoxFit.cover),
      );
    } else {
      inner = Image.asset(_fallbackAsset, fit: BoxFit.cover);
    }

    return ClipOval(child: SizedBox(width: size, height: size, child: inner));
  }
}

// Shared InputDecoration factory for form fields on inner screens.
// Pass context so light/dark colors are resolved correctly.
InputDecoration darkInputDecoration(
  String label, {
  IconData? prefixIcon,
  Widget? suffix,
  BuildContext? context,
}) {
  final isDark = context != null
      ? Theme.of(context).brightness == Brightness.dark
      : true;
  final c = isDark ? AppThemeColors.dark : AppThemeColors.light;

  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: c.textSecondary),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: c.textSecondary, size: 20)
        : null,
    suffixIcon: suffix,
    filled: true,
    fillColor: c.inputFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c.inputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c.inputBorder),
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
