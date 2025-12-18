// snackbar_utils.dart
// Utility centralizzata per la gestione delle snackbar nell’app.
// Utilizza lo standard ScaffoldMessenger di Flutter per la massima compatibilità.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

class SnackbarUtils {
  /// Funzione unica per mostrare snackbar normali oppure con supporto al ripristino (Undo)
  static void show({
    required BuildContext context,
    required String title,
    required String message,

    // Parametri opzionali per lo scenario "delete + undo"
    dynamic deletedItem,
    void Function(dynamic)? onDelete,
    void Function(dynamic)? onRestore,

    Duration duration = const Duration(seconds: 4),
  }) {
    // Verifica tema corrente (per colori chiari/scuri)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determina se la snackbar deve mostrare Undo
    final bool isDeleteSnackbar =
        deletedItem != null && onDelete != null && onRestore != null;

    // --- Esecuzione immediata della delete ---
    if (isDeleteSnackbar) {
      onDelete(deletedItem);
    }

    // --- Configurazione colori ---
    final Color backgroundColor = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;
    final Color textColor = AppColors.textDark;

    // --- Visualizzazione tramite ScaffoldMessenger ---
    // Rimuove eventuali snackbar pendenti prima di mostrarne una nuova
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: backgroundColor,
        behavior:
            SnackBarBehavior.floating, // Rende la snackbar sollevata come GetX
        margin: EdgeInsets.all(12.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        content: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 12),
                child: child,
              ),
            );
          },
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

        // --- Pulsante Undo ---
        action: isDeleteSnackbar
            ? SnackBarAction(
                label: "Annulla",
                textColor: textColor,
                onPressed: () {
                  onRestore(deletedItem);
                },
              )
            : null,
      ),
    );
  }
}
