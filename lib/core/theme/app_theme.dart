import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'design_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.text, // never white text on primary
      secondary: AppColors.secondary,
      onSecondary: AppColors.text,
      tertiary: AppColors.accent,
      onTertiary: AppColors.text,
      error: AppColors.error,
      onError: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(LsRadius.control),
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: LsText.fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        headlineMedium: LsText.authTitle,
        headlineSmall: LsText.pageTitle,
        titleLarge: LsText.screenTitle,
        titleMedium: LsText.section,
        bodyLarge: LsText.body,
        bodyMedium: LsText.bannerBody,
        bodySmall: LsText.helper,
        labelLarge: LsText.button,
        labelMedium: LsText.label,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: LsText.section,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        hintStyle: LsText.body.copyWith(color: AppColors.textSecondary),
        errorStyle: LsText.helper.copyWith(color: AppColors.error),
        helperStyle: LsText.helper,
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.supportingGreen),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error),
        disabledBorder: border(AppColors.border),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.text,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.supportingGreen,
      ),
      dividerColor: AppColors.border,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: LsText.bannerBody.copyWith(color: AppColors.surface),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
