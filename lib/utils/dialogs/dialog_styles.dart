import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DialogStyles {
  // --- Platform & Theme Helpers ---
  static bool get isIOS => Platform.isIOS;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textColor(BuildContext context) =>
      isDark(context) ? AppColors.textLight : AppColors.textDark;

  static bool isDestructiveAction(String text) =>
      text.toLowerCase().contains("elimina") ||
      text.toLowerCase().contains("logout");

  static RoundedRectangleBorder roundedRectangleBorder() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r));

  // --- UI Components Builders ---

  /// Titolo standard per i bottom sheet
  static Widget buildSheetTitle(String title) => Text(
    title,
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
  );

  /// Pulsante Chiudi a larghezza intera (Material style)
  static Widget buildCloseButton(BuildContext context) {
    final isDarkMode = isDark(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: isDarkMode
              ? AppColors.textDark
              : AppColors.textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        onPressed: () => Navigator.pop(context),
        child: Text("Chiudi", style: TextStyle(fontSize: 16.sp)),
      ),
    );
  }

  /// Pulsante d'azione per i Dialoghi (Adattivo)
  static Widget buildActionButton(
    BuildContext context,
    String text,
    Color color, [
    bool? returnValue,
  ]) {
    if (isIOS) {
      return CupertinoDialogAction(
        isDefaultAction: returnValue != false,
        isDestructiveAction: returnValue == true && isDestructiveAction(text),
        onPressed: () => Navigator.pop(context, returnValue),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 14.sp),
        ),
      );
    }
    return TextButton(
      onPressed: () => Navigator.pop(context, returnValue),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 14.sp),
      ),
    );
  }

  /// Pulsante d'azione per i Sheet (Adattivo: CupertinoActionSheetAction o TextButton)
  static Widget buildSheetAction(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    required bool isDark,
    bool isDestructive = false,
    bool isCancel = false,
  }) {
    // Stile iOS
    if (isIOS) {
      return CupertinoActionSheetAction(
        isDefaultAction: isCancel,
        isDestructiveAction: isDestructive,
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: isDestructive
                ? AppColors.delete
                : (isDark ? AppColors.textLight : AppColors.textDark),
            fontSize: 17.sp,
          ),
        ),
      );
    }

    // Stile Material (usato dentro Column/ListTile di solito, ma qui forniamo un builder generico se serve)
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: isDestructive
              ? AppColors.delete
              : (isDark ? AppColors.textLight : AppColors.textDark),
          fontSize: 17.sp,
        ),
      ),
    );
  }
}
