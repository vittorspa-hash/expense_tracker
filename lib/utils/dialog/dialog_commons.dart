// dialog_commons.dart
// Raccolta di metodi di utilità condivisi tra dialog, bottom sheet e componenti
// adattivi. Qui vengono gestiti aspetti comuni come stile, tema, pulsanti,
// pulsanti di chiusura, piattaforma iOS/Android e riconoscimento di azioni distruttive.
// Tutte le funzioni sono pure e non modificano stato globale.

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DialogCommons {
  // Indica se la piattaforma corrente è iOS (serve per UI adattive)
  static bool get isIOS => Platform.isIOS;

  // Determina se il tema corrente è scuro
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Restituisce il colore del testo in base al tema
  static Color textColor(BuildContext context) =>
      isDark(context) ? AppColors.textLight : AppColors.textDark;

  // Verifica se un testo rappresenta un’azione distruttiva, come “Elimina” o “Logout”
  static bool isDestructiveAction(String text) =>
      text.toLowerCase().contains("elimina") ||
      text.toLowerCase().contains("logout");

  // Ritorna il bordo arrotondato standard utilizzato nei dialog
  static RoundedRectangleBorder roundedRectangleBorder() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r));

  // ---------------------------------------------------------------------------
  // 🔘 PULSANTI DI AZIONE PER DIALOG
  // ---------------------------------------------------------------------------
  // Crea un pulsante adattivo in base alla piattaforma:
  // - CupertinoDialogAction per iOS
  // - TextButton per Android/Material
  // `returnValue` viene restituito tramite Navigator.pop quando il pulsante è premuto.
  static Widget buildActionButton(
    BuildContext context,
    String text,
    Color color, [
    bool? returnValue,
  ]) {
    if (isIOS) {
      return CupertinoDialogAction(
        isDefaultAction: returnValue != false, // evidenziazione azione principale
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

  // Titolo generico per bottom sheet o sezioni di dialog
  static Widget buildSheetTitle(String title) => Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
      );

  // ---------------------------------------------------------------------------
  // ❌ PULSANTE DI CHIUSURA
  // ---------------------------------------------------------------------------
  // Crea un pulsante di chiusura grande e ben visibile, usato spesso in bottom sheet
  static Widget buildCloseButton(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Chiudi",
            style: TextStyle(fontSize: 16.sp, color: AppColors.textLight),
          ),
        ),
      );
}
