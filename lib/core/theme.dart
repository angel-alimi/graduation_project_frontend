import 'package:flutter/material.dart';

/// LifeShare colours (same tokens as the web prototype).
class AppColors {
  AppColors._();
  static const bg = Color(0xFFF9F7F6);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1F2430);
  static const muted = Color(0xFF5F6672);
  static const muted2 = Color(0xFF6B7280);
  static const hint = Color(0xFF9096A0);
  static const red = Color(0xFFA71930);
  static const redDark = Color(0xFF8B1428);
  static const soft = Color(0xFFF7E8EB);
  static const line = Color(0xFFECE6E6);
  static const field = Color(0xFFE3DBDC);
  static const navBg = Color(0xFFF3ECED);
  static const chip = Color(0xFFF2EFEF);
  static const amberBg = Color(0xFFFDEEDF);
  static const amber = Color(0xFF8A3B0A);
  static const greenBg = Color(0xFFEAF4EC);
  static const green = Color(0xFF2F6B3A);
  static const indigoBg = Color(0xFFEEF0F6);
  static const indigo = Color(0xFF3F4A7A);
  static const scrim = Color(0x5C1F2430);
}

class AppFonts {
  AppFonts._();
  static const arabic = 'OoredooArabic';
  static const latin = 'Ooredoo';
}

/// Latin text style (numbers, blood types, the wordmark).
const TextStyle latin = TextStyle(fontFamily: AppFonts.latin);

ThemeData buildTheme(String lang) {
  final primaryFont = lang == 'ar' ? AppFonts.arabic : AppFonts.latin;
  final fallback = [lang == 'ar' ? AppFonts.latin : AppFonts.arabic];
  final radius10 = BorderRadius.circular(10);

  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: radius10, borderSide: BorderSide(color: c, width: w));

  final base = ThemeData(
    useMaterial3: true,
    fontFamily: primaryFont,
    fontFamilyFallback: fallback,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.red,
      primary: AppColors.red,
      surface: AppColors.bg,
      onSurface: AppColors.ink,
    ),
    splashFactory: InkRipple.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink).copyWith(
          headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3, color: AppColors.ink, fontFamily: primaryFont, fontFamilyFallback: fallback),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3, color: AppColors.ink, fontFamily: primaryFont, fontFamilyFallback: fallback),
          titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink, fontFamily: primaryFont, fontFamilyFallback: fallback),
          bodyMedium: TextStyle(fontSize: 14, height: 1.55, color: AppColors.ink, fontFamily: primaryFont, fontFamilyFallback: fallback),
          bodySmall: TextStyle(fontSize: 12, height: 1.45, color: AppColors.muted, fontFamily: primaryFont, fontFamilyFallback: fallback),
          labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: primaryFont, fontFamilyFallback: fallback),
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0x66A71930),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: primaryFont, fontFamilyFallback: fallback),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.surface,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.field),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: primaryFont, fontFamilyFallback: fallback),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.red,
        textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, fontFamily: primaryFont, fontFamilyFallback: fallback),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.hint, fontSize: 14),
      border: border(AppColors.field),
      enabledBorder: border(AppColors.field),
      focusedBorder: border(AppColors.red, 1.4),
      errorBorder: border(const Color(0xFFC2410C)),
      focusedErrorBorder: border(const Color(0xFFC2410C), 1.4),
      errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFB23A0B)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: TextStyle(fontSize: 13, color: Colors.white, fontFamily: primaryFont, fontFamilyFallback: fallback),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    }),
  );
}
