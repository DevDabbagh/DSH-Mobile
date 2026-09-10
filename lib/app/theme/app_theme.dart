import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';

part 'app_theme.g.dart';

TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
  // We specify font sizes based on the "Mobile" column from the Figma Typography specs.
  // We use GoogleFonts.inter as the primary base, with GoogleFonts.cairo as the fallback for Arabic.
  final String? fontFamily = GoogleFonts.inter().fontFamily;
  final List<String> fallbackFonts = [GoogleFonts.cairo().fontFamily!];

  return TextTheme(
    displayLarge: TextStyle(
      // Headline 1 (28/36)
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 28.sp,
      height: 36 / 28,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    ),
    displayMedium: TextStyle(
      // Headline 2 (20/28)
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 20.sp,
      height: 28 / 20,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    ),
    displaySmall: TextStyle(
      // Headline 3 (18/24)
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 18.sp,
      height: 24 / 18,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    ),
    headlineMedium: TextStyle(
      // Headline 4 (16/20)
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 16.sp,
      height: 20 / 16,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    ),
    bodyLarge: TextStyle(
      // Body 1 (16/24)
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 16.sp,
      height: 24 / 16,
      fontWeight: FontWeight.normal,
      color: primaryColor,
    ),
    bodyMedium: TextStyle(
      // Body 2 (14/20)
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 14.sp,
      height: 20 / 14,
      fontWeight: FontWeight.normal,
      color: secondaryColor,
    ),
    bodySmall: TextStyle(
      // Body 3 (12/16)
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 12.sp,
      height: 16 / 12,
      fontWeight: FontWeight.normal,
      color: secondaryColor,
    ),
    labelLarge: TextStyle(
      // Button Large (18/24)
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 18.sp,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
    ),
    labelMedium: TextStyle(
      // Button Medium (16/20)
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 16.sp,
      height: 20 / 16,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
    ),
    labelSmall: TextStyle(
      // Button Small (14/16)
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 14.sp,
      height: 16 / 14,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
    ),
  );
}

@riverpod
ThemeData lightTheme(Ref ref) {
  final textTheme =
      _buildTextTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.textPrimaryLight,
    ),
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle:
          textTheme.bodyMedium?.copyWith(color: AppColors.textMutedLight),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      titleTextStyle: textTheme.displayMedium?.copyWith(fontSize: 20.sp),
    ),
  );
}

@riverpod
ThemeData darkTheme(Ref ref) {
  final textTheme =
      _buildTextTheme(AppColors.textPrimary, AppColors.textSecondary);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: textTheme.displayMedium?.copyWith(fontSize: 20.sp),
    ),
  );
}
