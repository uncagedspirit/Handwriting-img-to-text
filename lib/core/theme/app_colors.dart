import 'package:flutter/material.dart';

/// Restrained color palette: soft neutral backgrounds, high-contrast text,
/// one primary accent, and a small set of status colors.
class AppColors {
  AppColors._();

  // Brand accent.
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFFE8E7FC);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Status colors.
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFE3F6E9);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFCF1DE);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFBE7E7);
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFE7EEFC);

  // Light theme neutrals.
  static const Color lightBackground = Color(0xFFF7F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF0F0F6);
  static const Color lightBorder = Color(0xFFE5E5EE);
  static const Color lightTextPrimary = Color(0xFF1B1B24);
  static const Color lightTextSecondary = Color(0xFF6B6B7B);
  static const Color lightTextMuted = Color(0xFF9A9AAC);

  // Dark theme neutrals.
  static const Color darkBackground = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1C1C25);
  static const Color darkSurfaceMuted = Color(0xFF25252F);
  static const Color darkBorder = Color(0xFF32323E);
  static const Color darkTextPrimary = Color(0xFFF3F3F8);
  static const Color darkTextSecondary = Color(0xFFB0B0C0);
  static const Color darkTextMuted = Color(0xFF7C7C8C);
}
