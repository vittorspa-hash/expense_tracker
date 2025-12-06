// dialog_commons.dart
// Contiene utility e metodi comuni per la gestione dei dialoghi e bottom sheet
// adattivi (sia Material che Cupertino). Fornisce informazioni sul platform,
// sul tema e metodi per costruire elementi UI di base come pulsanti e bordi.

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DialogCommons {
  // Proprietà statica per verificare se l'applicazione è in esecuzione su iOS.
  static bool get isIOS => Platform.isIOS;

  // Metodo per determinare se il tema corrente del contesto è scuro (Dark Mode).
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Metodo per ottenere il colore del testo appropriato in base al tema (chiaro/scuro).
  static Color textColor(BuildContext context) =>
      isDark(context) ? AppColors.textLight : AppColors.textDark;

  // Metodo per determinare se un testo di azione suggerisce un'azione distruttiva (es. eliminazione).
  static bool isDestructiveAction(String text) =>
      // Controlla se il testo (minuscolo) contiene "elimina" o "logout".
      text.toLowerCase().contains("elimina") ||
      text.toLowerCase().contains("logout");

  // Metodo per ottenere un bordo arrotondato standard (RoundedRectangleBorder).
  static RoundedRectangleBorder roundedRectangleBorder() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r));

  // Metodo per costruire un pulsante di azione adattivo (CupertinoDialogAction o TextButton).
  static Widget buildActionButton(
    BuildContext context,
    String text,
    Color color, [
    bool? returnValue, // Valore da restituire quando il dialogo viene chiuso.
  ]) {
    // Se è iOS, usa CupertinoDialogAction.
    if (isIOS) {
      return CupertinoDialogAction(
        // Imposta l'azione di default (se non è Annulla/false).
        isDefaultAction: returnValue != false,
        // Imposta l'azione come distruttiva solo se returnValue è true e il testo lo suggerisce.
        isDestructiveAction: returnValue == true && isDestructiveAction(text),
        // Chiude il dialogo restituendo returnValue.
        onPressed: () => Navigator.pop(context, returnValue),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 14.sp),
        ),
      );
    }
    // Altrimenti (Material), usa TextButton.
    return TextButton(
      // Chiude il dialogo restituendo returnValue.
      onPressed: () => Navigator.pop(context, returnValue),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 14.sp),
      ),
    );
  }

  // Metodo per costruire un titolo standard per i bottom sheet.
  static Widget buildSheetTitle(String title) => Text(
    title,
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
  );

  // Metodo per costruire un pulsante "Chiudi" a tutta larghezza (tipico di Material bottom sheets).
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
}
