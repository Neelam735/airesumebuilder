import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0B0D12);
  static const card = Color(0xFF161A23);
  static const soft = Color(0xFF11141B);
  static const border = Color(0xFF222836);
  static const ink = Color(0xFFE7E9EE);
  static const inkMuted = Color(0xFF9AA3B2);
  static const inkDim = Color(0xFF6B7280);
  static const brand = Color(0xFF7C5CFF);
  static const accent = Color(0xFF22D3EE);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  static const warn = Color(0xFFF59E0B);
}

ThemeData buildAppTheme() {
  const seed = AppColors.brand;

  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.card,
      background: AppColors.bg,
      primary: AppColors.brand,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    cardColor: AppColors.card,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.soft,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
      hintStyle: const TextStyle(color: AppColors.inkDim),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.inkMuted,
      ),
    ),

    // ✅ FIXED (Material 3)
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    // ✅ FIXED (Material 3)
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.card,
    ),

    dividerColor: AppColors.border,

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.soft,
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}