import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/config/app_colors.dart';

class SnackbarUtils {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String? undo,
    dynamic deletedItem,
    void Function(dynamic)? onDelete,
    void Function(dynamic)? onRestore,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isDeleteSnackbar =
        deletedItem != null && onDelete != null && onRestore != null;

    if (isDeleteSnackbar) {
      onDelete(deletedItem);
    }

    final Color backgroundColor =
        isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color textColor = AppColors.textDark;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(12.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        // ✅ Niente action — TextButton dentro il content non blocca il timer
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    message,
                    style: TextStyle(fontSize: 12.sp, color: textColor),
                  ),
                ],
              ),
            ),
            if (isDeleteSnackbar)
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onRestore(deletedItem);
                },
                child: Text(
                  undo!,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}