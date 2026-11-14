import 'package:flutter/material.dart';

/// LifeShare colours. Light and dark palettes share the same names, so
/// widgets just read `AppColors.ink`, `AppColors.surface`, etc.
/// [setDark] switches palette; the app root then rebuilds every widget.
class AppColors {
  AppColors._();

  static bool _dark = false;
  static bool get isDark => _dark;
  static void setDark(bool v) => _dark = v;

  static Color _p(int light, int dark) => Color(_dark ? dark : light);

  static Color get bg => _p(0xFFF6F6F8, 0xFF18191A);
  static Color get surface => _p(0xFFFFFFFF, 0xFF242526);
  static Color get ink => _p(0xFF1F2430, 0xFFE4E6EB);
  static Color get muted => _p(0xFF5F6672, 0xFFB0B3B8);
  static Color get muted2 => _p(0xFF6B7280, 0xFFB0B3B8);
  static Color get hint => _p(0xFF9096A0, 0xFF8A8D91);

  /// Brand red, the same in both themes.
  static Color get red => _p(0xFFA71930, 0xFFA71930);
  static Color get redDark => _p(0xFF8B1428, 0xFF8B1428);

  /// Brand red for text, icons and thin lines drawn on the page or a card.
  /// Lighter in dark mode so it stays readable on dark surfaces; filled
  /// buttons keep [red] with white text.
  static Color get redText => _p(0xFFA71930, 0xFFF0637A);

  static Color get soft => _p(0xFFF1F1F4, 0xFF3A3B3C); // neutral tint (avatars, empty states)
  static Color get line => _p(0xFFEDEDF0, 0xFF3A3B3C);
  static Color get field => _p(0xFFE2E2E7, 0xFF3E4042);
  static Color get navBg => _p(0xFFFFFFFF, 0xFF242526);
  static Color get chip => _p(0xFFF1F1F4, 0xFF3A3B3C);
  static Color get amberBg => _p(0xFFFDEEDF, 0xFF33240F);
  static Color get amber => _p(0xFF8A3B0A, 0xFFF2AE6B);
  static Color get greenBg => _p(0xFFEAF4EC, 0xFF14291A);
  static Color get green => _p(0xFF2F6B3A, 0xFF7FCB8E);
  static Color get indigoBg => _p(0xFFEEF0F6, 0xFF1D2033);
  static Color get indigo => _p(0xFF3F4A7A, 0xFFA9B2E6);
  static Color get scrim => _p(0x5C1F2430, 0xB3000000);
  static Color get error => _p(0xFFB23A0B, 0xFFF08A5D);
  static Color get errorBorder => _p(0xFFC2410C, 0xFFE0703F);
  static Color get shadow => _p(0x1F1F2430, 0x40000000);
}

class AppFonts {
  AppFonts._();
  /// One family for the whole app. IBM Plex Sans Arabic has both the Arabic
  /// and the Latin letters, so mixed lines (names, numbers, blood types) share
  /// the same size and baseline.
  static const text = 'IBMPlexSansArabic';
  static const arabic = text;
  static const latin = text;

  /// Only for the "LifeShare" wordmark.
  static const brand = 'Ooredoo';
}

/// Latin text style (numbers, blood types, the wordmark).
const TextStyle latin = TextStyle(fontFamily: AppFonts.latin);

ThemeData buildTheme(String lang, {bool dark = false}) {
  AppColors.setDark(dark);
  const primaryFont = AppFonts.text;
  const fallback = <String>[];
  final radius10 = BorderRadius.circular(10);

  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: radius10, borderSide: BorderSide(color: c, width: w));

  final base = ThemeData(
    useMaterial3: true,
    fontFamily: primaryFont,
    fontFamilyFallback: fallback,
    scaffoldBackgroundColor: AppColors.bg,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.red,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: AppColors.red,
      surface: AppColors.bg,
      onSurface: AppColors.ink,
      onPrimary: Colors.white,
      surfaceContainerHigh: AppColors.surface,
      surfaceContainerHighest: AppColors.chip,
      outline: AppColors.field,
    ),
    canvasColor: AppColors.bg,
    cardColor: AppColors.surface,
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
        disabledBackgroundColor: AppColors.red.withValues(alpha: .4),
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
        side: BorderSide(color: AppColors.field),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: primaryFont, fontFamilyFallback: fallback),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.redText,
        textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, fontFamily: primaryFont, fontFamilyFallback: fallback),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      hintStyle: TextStyle(color: AppColors.hint, fontSize: 14),
      border: border(AppColors.field),
      enabledBorder: border(AppColors.field),
      focusedBorder: border(AppColors.redText, 1.4),
      errorBorder: border(AppColors.errorBorder),
      focusedErrorBorder: border(AppColors.errorBorder, 1.4),
      errorStyle: TextStyle(fontSize: 12, color: AppColors.error),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? AppColors.chip : AppColors.ink,
      contentTextStyle: TextStyle(fontSize: 13, color: dark ? AppColors.ink : Colors.white, fontFamily: primaryFont, fontFamilyFallback: fallback),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerTheme: DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.muted2),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.red : AppColors.chip),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dialogTheme: DialogThemeData(backgroundColor: AppColors.surface, surfaceTintColor: Colors.transparent),
    popupMenuTheme: PopupMenuThemeData(color: AppColors.surface, surfaceTintColor: Colors.transparent),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.redText,
      refreshBackgroundColor: AppColors.surface,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    }),
  );
}
