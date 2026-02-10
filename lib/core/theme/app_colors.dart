import 'package:flutter/material.dart';

/// SNTF App Colors - Inspired by SNCF Connect
/// A modern railway application color palette
class AppColors {
  AppColors._();

  // ============== PRIMARY COLORS ==============
  /// Primary brand color - Deep Purple/Violet (SNCF signature)
  static const Color primary = Color(0xFF6E1E78);
  static const Color primaryLight = Color(0xFF9C4DAA);
  static const Color primaryDark = Color(0xFF4A0E52);

  // ============== SECONDARY COLORS ==============
  /// Secondary accent color - Vibrant Pink/Magenta
  static const Color secondary = Color(0xFFE4003A);
  static const Color secondaryLight = Color(0xFFFF5A6E);
  static const Color secondaryDark = Color(0xFFB0002E);

  // ============== ACCENT COLORS ==============
  /// Teal accent for highlights
  static const Color accent = Color(0xFF00B5AD);
  static const Color accentLight = Color(0xFF4DD0E1);
  static const Color accentDark = Color(0xFF00838F);

  // ============== STATUS COLORS ==============
  /// Success - Green
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF4CAF50);
  static const Color successBackground = Color(0xFFE8F5E9);

  /// Warning - Orange/Amber
  static const Color warning = Color(0xFFFF8F00);
  static const Color warningLight = Color(0xFFFFB300);
  static const Color warningBackground = Color(0xFFFFF3E0);

  /// Error - Red
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorBackground = Color(0xFFFFEBEE);

  /// Info - Blue
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFF42A5F5);
  static const Color infoBackground = Color(0xFFE3F2FD);

  // ============== NEUTRAL COLORS ==============
  /// Grays for text and backgrounds
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ============== LIGHT THEME COLORS ==============
  static const Color lightBackground = Color(0xFFF8F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F0F5);
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightOnSurface = Color(0xFF1A1A1A);
  static const Color lightOnSurfaceVariant = Color(0xFF5C5C5C);

  // ============== DARK THEME COLORS ==============
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);
  static const Color darkOnBackground = Color(0xFFE8E8E8);
  static const Color darkOnSurface = Color(0xFFE8E8E8);
  static const Color darkOnSurfaceVariant = Color(0xFFB0B0B0);

  // ============== TRANSPORT SPECIFIC COLORS ==============
  /// Train types
  static const Color tgv = Color(0xFF6E1E78);
  static const Color intercites = Color(0xFF00A7E1);
  static const Color ter = Color(0xFF003DA5);
  static const Color ouigo = Color(0xFF00B5AD);
  
  /// Train type aliases for railway lines
  static const Color trainTGV = Color(0xFF6E1E78);
  static const Color trainTER = Color(0xFF003DA5);
  static const Color trainIntercite = Color(0xFF00A7E1);

  /// Status indicators
  static const Color onTime = Color(0xFF2E7D32);
  static const Color delayed = Color(0xFFFF8F00);
  static const Color cancelled = Color(0xFFD32F2F);

  // ============== GRADIENT COLORS ==============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
