import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double pageHorizontal = 24;
  static const double pageVertical = 24;
  static const double sectionGap = 24;
  static const double controlHeight = 88;
  static const double controlWidth = 240;
}

class AppRadius {
  const AppRadius._();

  static const double card = 24;
}

class AppPalette {
  const AppPalette._();

  static const Color background = Color(0xFFF6FBFF);
  static const Color primary = Color(0xFF62B7A5);
  static const Color primaryDark = Color(0xFF3A8F7B);
  static const Color onPrimary = Colors.white;
  static const Color textPrimary = Color(0xFF1D2935);
  static const Color textSecondary = Color(0xFF5D6B79);
}

class AppFontFamilies {
  const AppFontFamilies._();

  static const String hsYugi = 'HSYugi';
  static const String yoonChildfundkoreaMinGuk = 'YoonChildfundkoreaMinGuk';
}

class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle title = TextStyle(
    color: AppPalette.textPrimary,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  static const TextStyle subtitle = TextStyle(
    color: AppPalette.textSecondary,
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle actionLabel = TextStyle(
    color: AppPalette.onPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.primary,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.title,
        bodyLarge: AppTextStyles.subtitle,
        labelLarge: AppTextStyles.actionLabel,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: AppPalette.onPrimary,
          minimumSize: const Size(
            AppSpacing.controlWidth,
            AppSpacing.controlHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          textStyle: AppTextStyles.actionLabel,
        ),
      ),
    );
  }
}
