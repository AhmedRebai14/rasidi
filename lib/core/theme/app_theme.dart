import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Main theme configuration for Rasidi — Modern Fintech Design System
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFE8E6FF),
          onPrimaryContainer: Color(0xFF2D20A0),
          secondary: AppColors.incomeGreen,
          onSecondary: Colors.white,
          tertiary: AppColors.expenseRed,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          onSurfaceVariant: AppColors.lightTextSecondary,
          outline: AppColors.lightBorder,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: AppColors.lightSurface,
        textTheme: _textTheme(AppColors.lightTextPrimary, AppColors.lightTextSecondary),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightBackground,
          foregroundColor: AppColors.lightTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          titleTextStyle: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: AppColors.lightTextPrimary, letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightSurface, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.lightSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          showDragHandle: true,
          dragHandleColor: Color(0xFFD0D5E8),
          dragHandleSize: Size(40, 4),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.lightSurface,
          indicatorColor: Color(0x1A6C63FF),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary, size: 24);
            }
            return const IconThemeData(color: AppColors.lightTextSecondary, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary);
            }
            return const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary);
          }),
          elevation: 0, height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            minimumSize: const Size.fromHeight(54), elevation: 0,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            minimumSize: const Size.fromHeight(54),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: AppColors.lightSurface2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightBorder, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          backgroundColor: AppColors.lightSurface2,
          selectedColor: const Color(0x1A6C63FF),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          side: BorderSide.none,
        ),
        dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 1, space: 0),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          elevation: 8, shape: CircleBorder(),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.lightTextPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: TextStyle(fontSize: 14),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryLight,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF2D2860),
          onPrimaryContainer: Color(0xFFCFC8FF),
          secondary: AppColors.incomeGreen,
          onSecondary: Colors.black,
          tertiary: AppColors.expenseRed,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkBorder,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkSurface,
        textTheme: _textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light,
          ),
          titleTextStyle: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: AppColors.darkTextPrimary, letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          showDragHandle: true,
          dragHandleColor: Color(0xFF3A4060),
          dragHandleSize: Size(40, 4),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          indicatorColor: const Color(0x249C94FF),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primaryLight, size: 24);
            }
            return const IconThemeData(color: AppColors.darkTextSecondary, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryLight);
            }
            return const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary);
          }),
          elevation: 0, height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            minimumSize: const Size.fromHeight(54), elevation: 0,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            minimumSize: const Size.fromHeight(54),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: AppColors.darkSurface2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.darkBorder, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryLight, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          backgroundColor: AppColors.darkSurface2,
          selectedColor: const Color(0x289C94FF),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          side: BorderSide.none,
        ),
        dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1, space: 0),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryLight, foregroundColor: Colors.white,
          elevation: 8, shape: CircleBorder(),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating, backgroundColor: AppColors.darkSurface3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.darkTextSecondary,
          indicatorColor: AppColors.primaryLight,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: TextStyle(fontSize: 14),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
        ),
      );

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: primary, letterSpacing: -2),
        displayMedium: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: primary, letterSpacing: -1.5),
        headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: primary, letterSpacing: -1),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.3),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: primary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: primary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: secondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primary, letterSpacing: 0.3),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 0.5),
      );
}
