import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

/// FILE: snackbar_utils.dart
/// DESCRIZIONE: Utility centralizzata per mostrare notifiche temporanee (Snackbar).
/// Supporta due modalità:
/// 1. Informativa semplice (Titolo + Messaggio).
/// 2. Azione con Undo (Eliminazione immediata con possibilità di annullare).
/// Implementa un'animazione personalizzata di ingresso e si adatta al tema corrente.

class SnackbarUtils {
  /// Funzione unica per mostrare snackbar.
  /// Gestisce automaticamente la logica di eliminazione/ripristino se i callback sono forniti.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- LOGICA UNDO (ELIMINAZIONE OTTIMISTICA) ---
    // Determina se è una snackbar di cancellazione.
    // Se sì, esegue *subito* l'eliminazione (feedback immediato per l'utente)
    // e prepara il callback di ripristino nel bottone della snackbar.
    // 
    final bool isDeleteSnackbar =
        deletedItem != null && onDelete != null && onRestore != null;

    if (isDeleteSnackbar) {
      onDelete(deletedItem);
    }

    // --- CONFIGURAZIONE VISIVA ---
    // Colori adattivi e pulizia della coda (rimuove snackbar precedenti per evitare code lunghe).
    final Color backgroundColor = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;
    final Color textColor = AppColors.textDark;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // --- COSTRUZIONE WIDGET ---
    // Utilizza SnackBarBehavior.floating per staccarla dal bordo inferiore.
    // 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating, 
        margin: EdgeInsets.all(12.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        
        // --- ANIMAZIONE PERSONALIZZATA ---
        // TweenAnimationBuilder crea un effetto di scorrimento e dissolvenza (Slide + Fade)
        // per un ingresso più morbido rispetto all'animazione standard di Material.
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

        // --- AZIONE (BOTTONE) ---
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