import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette - Deep Luxury Emerald Forest Green
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF0C3810);
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color primarySurface = Color(0xFFF1F8F1);
  static const Color primaryMedium = Color(0xFF2E7D32);

  // Accent Colors
  static const Color accentGold = Color(0xFFC9A227);
  static const Color accentGoldLight = Color(0xFFFFF9E6);
  static const Color accentOrange = Color(0xFFE65100);
  static const Color accentOrangeLight = Color(0xFFFFF3E0);
  static const Color accentBlue = Color(0xFF1976D2);
  static const Color accentBlueLight = Color(0xFFE3F2FD);

  // OLX Signature Palette
  static const Color olxNavy = Color(0xFF002F34);
  static const Color olxYellow = Color(0xFFFFCE32);
  static const Color olxTeal = Color(0xFF23E5DB);
  static const Color olxBackground = Color(0xFFF2F4F5);
  static const Color olxBorder = Color(0xFFD8DFE0);
  static const Color olxTextSecondary = Color(0xFF406367);
  static const Color olxTextMuted = Color(0xFF7F9799);

  // Background & Surfaces (Premium Light UI - Never Dark)
  static const Color background = Color(0xFFF2F4F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF3F6F3);

  // Borders & Dividers
  static const Color border = Color(0xFFE4E9E4);
  static const Color borderLight = Color(0xFFEFF3EF);
  static const Color divider = Color(0xFFEBF0EB);

  // Typography Colors
  static const Color textPrimary = Color(0xFF172018);
  static const Color textSecondary = Color(0xFF576357);
  static const Color textMuted = Color(0xFF8B988C);
  static const Color textLight = Color(0xFFB0BCB1);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFED6C02);
  static const Color warningLight = Color(0xFFFFF4E5);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF1B5E20).withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 10),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> bottomNavShadow = [
    BoxShadow(
      color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, -4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, -1),
      spreadRadius: 0,
    ),
  ];
}
