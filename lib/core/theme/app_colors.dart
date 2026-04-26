import 'package:flutter/material.dart';

/// Central color palette for Rasidi — Modern Fintech Design System
class AppColors {
  AppColors._();

  // ── Brand / Primary — violet-indigo ────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9C94FF);
  static const Color primaryDark = Color(0xFF4B44CC);
  static const Color secondary = Color(0xFF00C896); // mint accent

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color incomeGreen = Color(0xFF00C896);  // mint
  static const Color expenseRed = Color(0xFFFF5757);   // coral-red
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF5757);
  static const Color success = Color(0xFF00C896);

  // Health colors for projected balance
  static const Color healthGreen = Color(0xFF00C896);
  static const Color healthOrange = Color(0xFFFFB020);
  static const Color healthRed = Color(0xFFFF5757);

  // ── Light theme ────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF4F6FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFEEF1FA);
  static const Color lightTextPrimary = Color(0xFF0F1428);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E9F4);

  // ── Dark theme ─────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF07090F);
  static const Color darkSurface = Color(0xFF0E1120);
  static const Color darkSurface2 = Color(0xFF161B2E);
  static const Color darkSurface3 = Color(0xFF1D2340);
  static const Color darkTextPrimary = Color(0xFFECEEF8);
  static const Color darkTextSecondary = Color(0xFF7B82A0);
  static const Color darkBorder = Color(0xFF232843);

  // ── Backward-compat aliases ────────────────────────────────────────────
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color surfaceVariant = lightSurface2;
  static const Color darkSurfaceVariant = darkSurface2;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textHint = Color(0xFFADB5C4);
  static const Color border = lightBorder;
  static const Color divider = lightSurface2;

  // ── Gradient presets ───────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00A877)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF5757), Color(0xFFFF3D77)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1D2340), Color(0xFF151929)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Category preset colors ─────────────────────────────────────────────
  static const List<Color> categoryPresetColors = [
    Color(0xFFFF5757), // coral
    Color(0xFFFFB020), // amber
    Color(0xFFFFE566), // yellow
    Color(0xFF00C896), // mint
    Color(0xFF00A877), // teal
    Color(0xFF6C63FF), // violet
    Color(0xFF3B82F6), // blue
    Color(0xFF8B5CF6), // purple
    Color(0xFFEC4899), // pink
    Color(0xFFF97316), // orange
    Color(0xFF6B7280), // grey
    Color(0xFF4E342E), // brown
  ];
}
