import 'dart:io';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: dialog_styles.dart
/// DESCRIZIONE: Classe di utilità per lo styling centralizzato dei dialoghi.
/// Fornisce metodi helper per determinare il tema e la piattaforma, e builder
/// per creare componenti UI atomici (titoli, bottoni) che si adattano
/// automaticamente allo stile Cupertino (iOS) o Material (Android).

class DialogStyles {
  // --- HELPER AMBIENTE & TEMA ---
  // Metodi statici per rilevare la piattaforma e il tema corrente (Dark/Light).
  //
  static bool get isIOS => Platform.isIOS;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textColor(BuildContext context) =>
      isDark(context) ? AppColors.textLight : AppColors.textDark;

  // Euristica per determinare se un'azione è distruttiva (Rosso) basandosi sul testo.
  // Aggiornato per supportare sia Italiano che Inglese.
  static bool isDestructiveAction(String text) {
    final t = text.toLowerCase();
    return
    // Cancellazione (Delete)
        t.contains("elimina") || // IT, ES (Eliminar contiene elimina)
        t.contains("delete") || // EN
        t.contains("supprimer") || // FR
        // Logout / Uscita
        t.contains("logout") || // IT, EN
        t.contains("log out") || // EN variation
        t.contains("déconnexion") || // FR
        t.contains("cerrar sesión"); // ES (Specifico per non confondere con "Cerrar/Chiudi")
  }

  // --- STILI BASE ---
  // Definizioni di forme e bordi comuni.
  static RoundedRectangleBorder roundedRectangleBorder() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r));

  // --- BUILDER COMPONENTI UI ---
  // Metodi per costruire parti specifiche dei dialoghi (Titoli, Bottoni Chiudi).

  /// Titolo standard per i bottom sheet (ActionSheet).
  static Widget buildSheetTitle(String title) => Text(
    title,
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
  );

  /// Pulsante "Chiudi" a larghezza intera (Stile Material).
  /// Solitamente usato in fondo ai BottomSheet Android.
  static Widget buildCloseButton(BuildContext context) {
    final isDarkMode = isDark(context);
    final loc = AppLocalizations.of(context)!;

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
        child: Text(loc.close, style: TextStyle(fontSize: 16.sp)),
      ),
    );
  }

  // --- BUILDER ADATTIVI (PLATFORM AWARE) ---
  // Questi metodi restituiscono il widget nativo corretto in base a `isIOS`.
  //

  /// Pulsante d'azione per i Dialoghi (Alert).
  /// - iOS: CupertinoDialogAction (senza sfondo, stile testo nativo).
  /// - Android: TextButton (Ripple effect, Material Design).
  static Widget buildActionButton(
    BuildContext context,
    String text,
    Color color, [
    bool? returnValue,
  ]) {
    if (isIOS) {
      return CupertinoDialogAction(
        isDefaultAction: returnValue != false, // Grassetto se non è "Annulla"
        isDestructiveAction:
            returnValue == true &&
            isDestructiveAction(text), // Rosso se distruttivo
        onPressed: () => Navigator.pop(context, returnValue),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 14.sp),
        ),
      );
    }
    // Android
    return TextButton(
      onPressed: () => Navigator.pop(context, returnValue),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 14.sp),
      ),
    );
  }

  /// Pulsante d'azione per i Bottom Sheet.
  /// - iOS: CupertinoActionSheetAction.
  /// - Android: TextButton (o simile).
  static Widget buildSheetAction(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    required bool isDark,
    bool isDestructive = false,
    bool isCancel = false,
  }) {
    // Stile iOS (Action Sheet nativo)
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

    // Stile Material (Generico)
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
