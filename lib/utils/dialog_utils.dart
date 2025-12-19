// dialog_utils.dart
// Classe centralizzata che gestisce tutti i dialog e i popup dell’app adattivi (Material/Cupertino).
// Contiene metodi statici per mostrare alert, conferme, sheet di ordinamento,
// sheet profilo, dialoghi di input, istruzioni e picker di data/ora/anno.

import 'package:expense_tracker/providers/profile_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dialogs/dialog_commons.dart';
import 'dialogs/dialog_sheets.dart';
import 'dialogs/dialog_profile.dart';
import 'dialogs/dialog_inputs.dart';
import 'dialogs/dialog_pickers.dart';

class DialogUtils {
  // Mostra un dialogo informativo semplice (InfoDialog) con un solo pulsante "OK".
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    // Verifica se il widget è montato prima di mostrare il dialogo.
    if (!context.mounted) return;

    await _showDialog(
      context: context,
      title: title,
      content: content,
      // Definisce l'azione: un pulsante "OK".
      actions: (context, textColor) => [
        DialogCommons.buildActionButton(context, "OK", textColor),
      ],
    );
  }

  // Mostra un dialogo di conferma (ConfirmDialog) con pulsanti "Conferma" e "Annulla".
  // Restituisce true se l'utente conferma, false se annulla o null se il dialogo viene chiuso.
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = "Conferma",
    String cancelText = "Annulla",
  }) async {
    // Verifica se il widget è montato.
    if (!context.mounted) return false;

    final textColor = DialogCommons.textColor(context);
    // Controlla se l'azione di conferma è considerata "distruttiva" (es. "Elimina").
    final isDestructive = DialogCommons.isDestructiveAction(confirmText);
    // Imposta il colore del testo per l'azione di conferma: rosso per distruttiva, altrimenti normale.
    final confirmColor = isDestructive ? AppColors.delete : textColor;

    return await _showDialog<bool>(
      context: context,
      title: title,
      content: content,
      // Definisce le azioni: pulsante Annulla (false) e pulsante Conferma (true).
      actions: (context, _) => [
        DialogCommons.buildActionButton(context, cancelText, textColor, false),
        DialogCommons.buildActionButton(
          context,
          confirmText,
          confirmColor,
          true,
        ),
      ],
    );
  }

  // Mostra un bottom sheet adattivo per la selezione di opzioni di ordinamento.
  // Restituisce la chiave dell'opzione selezionata.
  static Future<String?> showSortSheet(
    BuildContext context, {
    required bool isDark,
    required List<Map<String, String>> options,
  }) async {
    // Verifica se il widget è montato.
    if (!context.mounted) return null;

    return await DialogSheets.showAdaptiveSheet(
      context: context,
      title: 'Ordina spese',
      isDark: isDark,
      options: options,
    );
  }

  // Mostra un bottom sheet adattivo con le opzioni del profilo utente.
  static Future<void> showProfileSheet(BuildContext context) async {
    if (!context.mounted) return;

    final isDark = DialogCommons.isDark(context);

    // Gestione iOS (CupertinoActionSheet)
    if (DialogCommons.isIOS) {
      if (!context.mounted) return;

      await showCupertinoModalPopup(
        context: context,
        // Usiamo Consumer per leggere i dati aggiornati dal Provider
        builder: (ctx) => Consumer<ProfileProvider>(
          builder: (context, provider, _) {
            // Mappiamo i dati del provider ai parametri richiesti da DialogProfile
            final user = provider.user;
            final localAvatar = provider.localImage;

            // Il reloadAvatar ora è semplicemente la funzione di ricaricamento del provider
            Future<void> reloadAvatar() async => await provider.loadLocalData();

            return CupertinoActionSheet(
              title: DialogProfile.buildProfileHeader(
                context,
                user,
                localAvatar,
                isDark,
              ),
              actions: [
                DialogProfile.buildProfileAction(
                  context,
                  user,
                  localAvatar,
                  reloadAvatar,
                  isDark,
                ),
                DialogProfile.buildSettingsAction(context, isDark),
                DialogProfile.buildLogoutAction(context, isDark),
              ],
              cancelButton: DialogSheets.buildCupertinoSheetButton(
                context,
                "Chiudi",
                isDark,
                null,
              ),
            );
          },
        ),
      );
    } else {
      // Gestione Android/Material (ModalBottomSheet)
      if (!context.mounted) return;

      await showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        builder: (ctx) => Consumer<ProfileProvider>(
          builder: (context, provider, _) {
            final user = provider.user;
            final localAvatar = provider.localImage;
            Future<void> reloadAvatar() async => await provider.loadLocalData();

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DialogProfile.buildProfileHeader(
                      context,
                      user,
                      localAvatar,
                      isDark,
                    ),
                    SizedBox(height: 20.h),

                    DialogProfile.buildProfileListTile(
                      context,
                      user,
                      localAvatar,
                      reloadAvatar,
                      isDark,
                    ),

                    DialogProfile.buildSettingsListTile(context, isDark),
                    DialogProfile.buildLogoutListTile(context, isDark),

                    SizedBox(height: 12.h),
                    DialogCommons.buildCloseButton(context),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }

  // Mostra un dialogo adattivo per l'inserimento di dati (Input Dialog).
  // Restituisce una lista di stringhe con i valori inseriti, o null.
  static Future<List<String>?> showInputDialogAdaptive(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> fields,
    String confirmText = "Salva",
    String cancelText = "Annulla",
    VoidCallback? onForgotPassword,
  }) async {
    // Verifica se il widget è montato.
    if (!context.mounted) return null;

    final isCupertino = DialogCommons.isIOS;

    // Mostra un CupertinoDialog su iOS.
    if (isCupertino) {
      if (!context.mounted) return null;

      return await showCupertinoDialog<List<String>>(
        context: context,
        builder: (ctx) => InputDialogWidget(
          title: title,
          fields: fields,
          confirmText: confirmText,
          cancelText: cancelText,
          onForgotPassword: onForgotPassword,
        ),
      );
    }

    // Mostra un AlertDialog standard su Android/Material.
    if (!context.mounted) return null;

    return await showDialog<List<String>>(
      context: context,
      builder: (ctx) => InputDialogWidget(
        title: title,
        fields: fields,
        confirmText: confirmText,
        cancelText: cancelText,
        onForgotPassword: onForgotPassword,
      ),
    );
  }

  // Mostra un dialogo di istruzioni con un'opzione "Non mostrare più" (checkbox).
  // Restituisce true se l'utente ha selezionato la checkbox.
  static Future<bool> showInstructionDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = "OK",
    String checkboxLabel = "Non mostrare più",
  }) async {
    // Verifica se il widget è montato.
    if (!context.mounted) return false;

    final textColor = DialogCommons.textColor(context);
    bool dontShowAgain = false; // Stato iniziale della checkbox.

    // Funzione per costruire il contenuto (messaggio e checkbox).
    Widget buildContent(StateSetter setState) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Messaggio del dialogo.
        Text(
          message,
          style: TextStyle(fontSize: DialogCommons.isIOS ? 13.sp : 14.sp),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        // Riga con la checkbox.
        DialogInputs.buildCheckboxRow(
          setState,
          dontShowAgain,
          checkboxLabel,
          // Callback per aggiornare lo stato interno quando la checkbox cambia.
          (value) => dontShowAgain = value,
        ),
      ],
    );

    // Gestione specifica per iOS (CupertinoAlertDialog).
    if (DialogCommons.isIOS) {
      if (!context.mounted) return false;

      await showCupertinoDialog(
        context: context,
        // Usa StatefulBuilder per gestire lo stato della checkbox.
        builder: (_) => StatefulBuilder(
          builder: (context, setState) => CupertinoAlertDialog(
            title: Text(title, style: TextStyle(fontSize: 15.sp)),
            content: Padding(
              padding: EdgeInsets.only(top: 8.h),
              // Inserisce Material per permettere al testo di buildContent di avere uno stile corretto.
              child: Material(
                color: Colors.transparent,
                child: buildContent(setState),
              ),
            ),
            actions: [
              // Pulsante di conferma.
              DialogCommons.buildActionButton(context, confirmText, textColor),
            ],
          ),
        ),
      );
    } else {
      // Gestione specifica per Android/Material (AlertDialog).
      if (!context.mounted) return false;

      await showDialog(
        context: context,
        // Usa StatefulBuilder per gestire lo stato della checkbox.
        builder: (_) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: DialogCommons.roundedRectangleBorder(),
            title: Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            content: buildContent(setState),
            actions: [
              // Pulsante di conferma.
              DialogCommons.buildActionButton(context, confirmText, textColor),
            ],
          ),
        ),
      );
    }
    // Restituisce lo stato finale della checkbox.
    return dontShowAgain;
  }

  // Mostra un picker di data adattivo.
  // Restituisce la data selezionata o null.
  static Future<DateTime?> showDatePickerAdaptive(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    // Verifica se il widget è montato.
    if (!context.mounted) return null;

    final isDark = DialogCommons.isDark(context);
    final textColor = DialogCommons.textColor(context);
    // Imposta le date minime e massime di default.
    final minDate = firstDate ?? DateTime(2000);
    final maxDate = lastDate ?? DateTime.now();

    // Gestione specifica per iOS (CupertinoDatePicker in un ModalPopup).
    if (DialogCommons.isIOS) {
      if (!context.mounted) return null;

      DateTime tempPicked =
          initialDate; // Variabile temporanea per la data selezionata.

      return await showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (_) => Container(
          height: 300.h,
          // Stile del container per il picker.
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              // Header con i pulsanti di azione (es. "Fatto").
              DialogPickers.buildDatePickerHeader(
                context,
                textColor,
                () => tempPicked, // Funzione per ottenere il valore corrente.
              ),
              Divider(height: 0, thickness: 1.h),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date, // Modalità solo data.
                  initialDateTime: initialDate,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  // Aggiorna la variabile temporanea al cambio di data.
                  onDateTimeChanged: (newDate) => tempPicked = newDate,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Gestione specifica per Android/Material (showDatePicker).
    if (!context.mounted) return null;
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,
      // Personalizzazione del tema del DatePicker di Material.
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            shape: DialogCommons.roundedRectangleBorder(),
            // Stile personalizzato per i pulsanti Annulla e Conferma.
            cancelButtonStyle: DialogPickers.datePickerButtonStyle(
              textColor,
              false,
            ),
            confirmButtonStyle: DialogPickers.datePickerButtonStyle(
              textColor,
              true,
            ),
          ),
        ),
        child: child!,
      ),
    );
  }

  // Mostra un picker di anno adattivo (usando un sheet).
  // Restituisce l'anno selezionato (String) o null.
  static Future<String?> showYearPickerAdaptive(
    BuildContext context, {
    required List<String> years,
    required String selectedYear,
  }) async {
    // Verifica se il widget è montato.
    if (!context.mounted) return null;

    return await DialogSheets.showAdaptiveYearPicker(
      context: context,
      years: years,
      selectedYear: selectedYear,
      isDark: DialogCommons.isDark(context),
    );
  }

  // Mostra un picker di ora adattivo.
  // Restituisce l'ora selezionata (TimeOfDay) o null.
  static Future<TimeOfDay?> showTimePickerAdaptive(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) async {
    // Verifica se il widget è montato.
    if (!context.mounted) return null;

    // La logica adattiva è delegata a DialogPickers.
    return await DialogPickers.showTimePickerAdaptive(
      context: context,
      initialTime: initialTime,
    );
  }

  // Funzione interna generica per mostrare un dialogo adattivo (Cupertino o Material).
  static Future<T?> _showDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    // La funzione actions definisce i pulsanti del dialogo.
    required List<Widget> Function(BuildContext, Color) actions,
  }) async {
    // Verifica se il widget è montato.
    if (!context.mounted) return null;

    final textColor = DialogCommons.textColor(context);

    // Mostra un CupertinoAlertDialog su iOS.
    if (DialogCommons.isIOS) {
      if (!context.mounted) return null;
      return await showCupertinoDialog<T>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title, style: TextStyle(fontSize: 15.sp)),
          content: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(content, style: TextStyle(fontSize: 14.sp)),
          ),
          actions: actions(
            context,
            textColor,
          ), // Inietta le azioni personalizzate.
        ),
      );
    }

    // Mostra un AlertDialog standard su Android/Material.
    if (!context.mounted) return null;
    return await showDialog<T>(
      context: context,
      builder: (_) => AlertDialog(
        shape: DialogCommons.roundedRectangleBorder(),
        title: Text(title, style: TextStyle(fontSize: 15.sp)),
        content: Text(content, style: TextStyle(fontSize: 14.sp)),
        actions: actions(
          context,
          textColor,
        ), // Inietta le azioni personalizzate.
      ),
    );
  }
}
