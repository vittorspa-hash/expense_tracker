import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/config/app_colors.dart';

/// FILE: snackbar_utils.dart
/// DESCRIZIONE: Utility centralizzata per la creazione e la visualizzazione delle
/// snackbar dell'app. Espone due punti di ingresso (uno legato al `BuildContext`
/// di pagina, uno globale tramite `messengerKey`) che convergono in un unico
/// metodo di rendering, così da mantenere lo stile visivo coerente e gestire
/// correttamente il margine inferiore quando la `FloatingNavBar` è presente.

class SnackbarUtils {
  // --- METODO CLASSICO (Usalo ovunque l'app non subisca logout/rebuild radicali) ---
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String? undo,
    dynamic deletedItem,
    void Function(dynamic)? onDelete,
    void Function(dynamic)? onRestore,
    Duration duration = const Duration(seconds: 4),
    required bool navBar,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    _buildAndShow(
      messenger: messenger,
      isDark: isDark,
      title: title,
      message: message,
      navBar: navBar,
      duration: duration,
      undo: undo,
      deletedItem: deletedItem,
      onDelete: onDelete,
      onRestore: onRestore,
    );
  }

  // --- NUOVO METODO GLOBALE (Per cambio Email, Password e Logout) ---
  static void showGlobal({
    required GlobalKey<ScaffoldMessengerState> messengerKey,
    required bool isDark, // Passiamo il tema esplicitamente dato che non abbiamo il context della pagina
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    required bool navBar,
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    _buildAndShow(
      messenger: messenger,
      isDark: isDark,
      title: title,
      message: message,
      navBar: navBar,
      duration: duration,
    );
  }

  // --- CORE DI RENDERING (Mantiene la tua UI intatta e centralizzata) ---
  static void _buildAndShow({
    required ScaffoldMessengerState messenger,
    required bool isDark,
    required String title,
    required String message,
    required bool navBar,
    required Duration duration,
    String? undo,
    dynamic deletedItem,
    void Function(dynamic)? onDelete,
    void Function(dynamic)? onRestore,
  }) {
    final bool isDeleteSnackbar =
        deletedItem != null && onDelete != null && onRestore != null;

    if (isDeleteSnackbar) {
      onDelete(deletedItem);
    }

    final Color backgroundColor = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;
    final Color textColor = AppColors.textDark;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        // Margine inferiore maggiorato quando `navBar` è true, per evitare che la
        // snackbar venga coperta dalla FloatingNavBar sospesa sopra il contenuto.
        margin: navBar
            ? EdgeInsets.only(left: 12.w, right: 12.w, top: 12.h, bottom: 78.h)
            : EdgeInsets.all(12.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
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