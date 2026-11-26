import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xff1f4e79);
  static const gold = Color(0xffd4af37);
  static const ink = Color(0xff19446a);
  static const muted = Color(0xff60758b);
  static const cream = Color(0xfffdf8e4);
  static const field = Color(0xfff5f7f8);
  static const line = Color(0xffefe4bd);
  static const paper = Colors.white;
  static const danger = Color(0xffb42332);
  static const green = Color(0xff127c5a);
}

abstract final class AppSpacing {
  static const page = 24.0;
  static const gap = 16.0;
  static const radius = 16.0;
}

abstract final class AppTypography {
  static TextStyle heading([double size = 26]) => TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: size,
    height: 1.16,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation.weight(700)],
    color: AppColors.navy,
  );

  static TextStyle label([Color color = AppColors.navy, double size = 11]) =>
      TextStyle(
        fontFamily: 'Montserrat',
        fontSize: size,
        letterSpacing: 1,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation.weight(700)],
        color: color,
      );
}

abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy).copyWith(
      primary: AppColors.navy,
      secondary: AppColors.gold,
      surface: AppColors.paper,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.paper,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
    ),
  );
}
