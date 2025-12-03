// dialog_helpers.dart
// Classe "facciata" che raggruppa e re-esporta tutti i metodi dei vari file
// (commons, sheets, profile, inputs, pickers) per mantenere un’unica API centralizzata.
// Ogni metodo qui dentro semplicemente inoltra la chiamata al rispettivo modulo,
// senza aggiungere logica o modificare il comportamento originale.
// Questo mantiene il codice più organizzato e facilita la lettura nel resto dell’app.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dialog_commons.dart';
import 'dialog_sheets.dart';
import 'dialog_profile.dart';
import 'dialog_inputs.dart';
import 'dialog_pickers.dart';

class DialogHelpers {
  // Indica se la piattaforma è iOS (utile per UI adattiva)
  static bool get isIOS => DialogCommons.isIOS;

  // Determina se il tema corrente è scuro
  static bool isDark(BuildContext context) => DialogCommons.isDark(context);

  // Ritorna il colore del testo basato sul tema
  static Color textColor(BuildContext context) =>
      DialogCommons.textColor(context);

  // Riconosce se un’azione è distruttiva (es. “Elimina”)
  static bool isDestructiveAction(String text) =>
      DialogCommons.isDestructiveAction(text);

  // Restituisce il bordo arrotondato standard per i dialog
  static RoundedRectangleBorder roundedRectangleBorder() =>
      DialogCommons.roundedRectangleBorder();

  // Costruisce un pulsante d’azione per dialog/adaptive UI
  static Widget buildActionButton(
    BuildContext context,
    String text,
    Color color, [
    bool? returnValue,
  ]) =>
      DialogCommons.buildActionButton(context, text, color, returnValue);

  // Costruisce il titolo di un bottom sheet
  static Widget buildSheetTitle(String title) =>
      DialogCommons.buildSheetTitle(title);


  // ---------------------------------------------------------------------------
  // 📱 BOTTOM SHEETS (Cupertino / Material)
  // ---------------------------------------------------------------------------

  // Pulsante per Cupertino bottom sheet
  static Widget buildCupertinoSheetButton(
    BuildContext context,
    String text,
    bool isDark,
    String? returnValue,
  ) =>
      DialogSheets.buildCupertinoSheetButton(
          context, text, isDark, returnValue);

  // Pulsante per Material bottom sheet
  static Widget buildMaterialSheetButton(
    BuildContext context,
    String text,
    bool isDark,
    String? returnValue,
  ) =>
      DialogSheets.buildMaterialSheetButton(context, text, isDark, returnValue);

  // Mostra un bottom sheet adattivo (iOS/Android)
  static Future<String?> showAdaptiveSheet({
    required BuildContext context,
    required String title,
    required bool isDark,
    required List<Map<String, String>> options,
  }) =>
      DialogSheets.showAdaptiveSheet(
        context: context,
        title: title,
        isDark: isDark,
        options: options,
      );

  // Mostra un selettore di anni in stile adattivo
  static Future<String?> showAdaptiveYearPicker({
    required BuildContext context,
    required List<String> years,
    required String selectedYear,
    required bool isDark,
  }) =>
      DialogSheets.showAdaptiveYearPicker(
        context: context,
        years: years,
        selectedYear: selectedYear,
        isDark: isDark,
      );


  // ---------------------------------------------------------------------------
  // 👤 PROFILE DIALOG / SETTINGS UI
  // ---------------------------------------------------------------------------

  // Costruisce l’header del profilo con avatar e info utente
  static Widget buildProfileHeader(
    BuildContext context,
    User? user,
    File? localAvatar,
    bool isDark,
  ) =>
      DialogProfile.buildProfileHeader(context, user, localAvatar, isDark);

  // Costruisce solo l’avatar (locale o remoto)
  static Widget buildAvatar(User? user, File? localAvatar) =>
      DialogProfile.buildAvatar(user, localAvatar);

  // Costruisce i pulsanti/azioni del profilo (cambio avatar, reload, ecc.)
  static Widget buildProfileAction(
    BuildContext context,
    User? user,
    File? localAvatar,
    Future<void> Function() reloadAvatar,
    bool isDark,
  ) =>
      DialogProfile.buildProfileAction(
          context, user, localAvatar, reloadAvatar, isDark);

  // Costruisce l’azione per aprire le impostazioni
  static Widget buildSettingsAction(BuildContext context, bool isDark) =>
      DialogProfile.buildSettingsAction(context, isDark);

  // Costruisce l’azione di logout
  static Widget buildLogoutAction(
    BuildContext context,
    bool isDark,
    bool isCupertino,
  ) =>
      DialogProfile.buildLogoutAction(context, isDark, isCupertino);

  // ListTile del profilo all’interno di menu o dialog
  static Widget buildProfileListTile(
    BuildContext context,
    User? user,
    File? localAvatar,
    Future<void> Function() reloadAvatar,
    bool isDark,
  ) =>
      DialogProfile.buildProfileListTile(
          context, user, localAvatar, reloadAvatar, isDark);

  // ListTile dell’accesso alle impostazioni
  static Widget buildSettingsListTile(BuildContext context, bool isDark) =>
      DialogProfile.buildSettingsListTile(context, isDark);

  // ListTile per il logout
  static Widget buildLogoutListTile(BuildContext context, bool isDark) =>
      DialogProfile.buildLogoutListTile(context, isDark);


  // Pulsante di chiusura dei dialog
  static Widget buildCloseButton(BuildContext context) =>
      DialogCommons.buildCloseButton(context);


  // ---------------------------------------------------------------------------
  // 🔤 INPUT FIELDS & FORM COMPONENTS
  // ---------------------------------------------------------------------------

  // Costruisce un TextField configurato per dialog (gestione focus, obscure, ecc.)
  static Widget buildTextField(
    BuildContext dialogCtx,
    Map<String, dynamic> field,
    TextEditingController controller,
    ValueNotifier<bool> obscure,
    List<FocusNode> focusNodes,
    int index,
    int totalFields,
    Color txtColor,
  ) =>
      DialogInputs.buildTextField(dialogCtx, field, controller, obscure,
          focusNodes, index, totalFields, txtColor);

  // Pulsante "Password dimenticata?"
  static Widget buildForgotPasswordButton(
    VoidCallback onPressed,
    Color txtColor,
  ) =>
      DialogInputs.buildForgotPasswordButton(onPressed, txtColor);

  // Azioni standard (Annulla / Conferma) per form nei dialog
  static List<Widget> buildDialogActions(
    BuildContext context,
    String cancelText,
    String confirmText,
    List<TextEditingController> controllers,
    Color txtColor,
    bool isCupertino,
  ) =>
      DialogInputs.buildDialogActions(
          context, cancelText, confirmText, controllers, txtColor, isCupertino);


  // Riga con checkbox + etichetta (es. “Ricorda password”)
  static Widget buildCheckboxRow(
    StateSetter setState,
    bool value,
    String label,
    Function(bool) onChanged,
  ) =>
      DialogInputs.buildCheckboxRow(setState, value, label, onChanged);


  // ---------------------------------------------------------------------------
  // 📅 DATE & TIME PICKERS
  // ---------------------------------------------------------------------------

  // Header del selettore data
  static Widget buildDatePickerHeader(
    BuildContext context,
    Color txtColor,
    DateTime Function() getSelectedDate,
  ) =>
      DialogPickers.buildDatePickerHeader(context, txtColor, getSelectedDate);

  // Mostra un selettore orario adattivo
  static Future<TimeOfDay?> showTimePickerAdaptive({
    required BuildContext context,
    required TimeOfDay initialTime,
    Color? primaryColor,
    Color? onSurfaceColor,
  }) =>
      DialogPickers.showTimePickerAdaptive(
        context: context,
        initialTime: initialTime,
        primaryColor: primaryColor,
        onSurfaceColor: onSurfaceColor,
      );

  // Stile per i pulsanti del DatePicker
  static ButtonStyle datePickerButtonStyle(Color color, bool isConfirm) =>
      DialogPickers.datePickerButtonStyle(color, isConfirm);
}
