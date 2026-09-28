import 'package:flutter/material.dart';

import 'motion.dart';

/// Soft, rounded "cute but clean" palette.
class AppColors {
  AppColors._();
  static const bg = Color(0xFFFFF8F1);
  static const card = Colors.white;
  static const ink = Color(0xFF3B3340);
  static const inkSoft = Color(0xFF766C7D);
  static const line = Color(0xFFF1E6DC);

  static const peach = Color(0xFFFF8E7F); // primary / kcal
  static const peachSoft = Color(0xFFFFE3DC);
  static const mint = Color(0xFF4CC9A4); // protein
  static const mintSoft = Color(0xFFD9F5EC);
  static const butter = Color(0xFFFFC34D); // carbs
  static const butterSoft = Color(0xFFFFF0CC);
  static const lilac = Color(0xFFA38BFF); // fat
  static const lilacSoft = Color(0xFFECE6FF);
  static const sky = Color(0xFF6EB7FF); // weight
  static const skySoft = Color(0xFFE0F0FF);
}

const headingFont = 'NanumSquareRound';
const bodyFont = 'NanumSquareRound';
const bodyWeight = FontWeight.w700;

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.peach,
    primary: AppColors.peach,
    secondary: AppColors.mint,
    surface: AppColors.bg,
    onSurface: AppColors.ink,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: bodyFont,
  );
  TextStyle h(double size) => TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w800,
    fontSize: size,
    color: AppColors.ink,
    height: 1.25,
    letterSpacing: -0.4,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkRipple.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: SoftPageTransitionsBuilder(),
        TargetPlatform.iOS: SoftPageTransitionsBuilder(),
        TargetPlatform.macOS: SoftPageTransitionsBuilder(),
        TargetPlatform.windows: SoftPageTransitionsBuilder(),
        TargetPlatform.linux: SoftPageTransitionsBuilder(),
        TargetPlatform.fuchsia: SoftPageTransitionsBuilder(),
      },
    ),
    textTheme:
        _bodyWeight(
          base.textTheme.apply(
            bodyColor: AppColors.ink,
            displayColor: AppColors.ink,
          ),
        ).copyWith(
          displayLarge: h(50),
          displayMedium: h(40),
          displaySmall: h(30),
          headlineMedium: h(25),
          headlineSmall: h(22),
          titleLarge: h(19),
          titleMedium: h(17),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: h(24),
      foregroundColor: AppColors.ink,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.peach,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(0, 54),
        side: const BorderSide(color: AppColors.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.peach,
        textStyle: const TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.peach, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.inkSoft),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.peachSoft,
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
          color: s.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.inkSoft,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.peach
              : AppColors.inkSoft,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white,
      selectedColor: AppColors.peachSoft,
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(
        fontFamily: headingFont,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: h(22),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
  );
}

/// NanumSquareRound Regular is quite thin, so body and label text use the
/// Bold cut for better legibility.
TextTheme _bodyWeight(TextTheme t) {
  TextStyle? b(TextStyle? s) => s?.copyWith(fontWeight: bodyWeight);
  return t.copyWith(
    bodyLarge: b(t.bodyLarge),
    bodyMedium: b(t.bodyMedium),
    bodySmall: b(t.bodySmall),
    labelLarge: b(t.labelLarge),
    labelMedium: b(t.labelMedium),
    labelSmall: b(t.labelSmall),
    titleSmall: b(t.titleSmall),
  );
}
