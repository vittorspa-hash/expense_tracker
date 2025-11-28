// snackbar_utils.dart
// Utility centralizzata per la gestione delle snackbar nell’app.
// Consente di mostrare sia notifiche standard che snackbar con supporto
// all’operazione di Undo (ripristino), ad esempio durante l’eliminazione di una spesa.
// Utilizza GetX per la visualizzazione rapida e Flutter ScreenUtil per la responsività.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    // Se è una snackbar di eliminazione, esegue subito la callback delete
    if (isDeleteSnackbar) {
      onDelete(deletedItem);
    }

    // --- Visualizzazione dello snackbar tramite GetX ---
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isDark
          ? AppColors.snackBarEditPageDark
          : AppColors.snackBarEditPageLight,
      margin: EdgeInsets.all(12.w),
      borderRadius: 12.r,

      // Testo del titolo
      titleText: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textLight : AppColors.textDark,
        ),
      ),

      // Testo del messaggio
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: 12.sp,
          color: isDark ? AppColors.textLight : AppColors.textDark,
        ),
      ),

      duration: duration,

      // --- Pulsante Undo ---
      // Se è una delete snackbar → mostra pulsante "Annulla"
      mainButton: isDeleteSnackbar
          ? TextButton(
              onPressed: () {
                onRestore(deletedItem);
                if (Get.isSnackbarOpen) Get.back();
              },
              child: Text(
                "Annulla",
                style: TextStyle(
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            )
          : null,
    );
  }
}
