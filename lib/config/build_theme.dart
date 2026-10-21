import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTheme(Brightness brightness) {
  final base = brightness == Brightness.dark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.textLight,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionHandleColor: AppColors.primary,
      selectionColor: AppColors.primary.withValues(alpha: 0.3),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
  );
}