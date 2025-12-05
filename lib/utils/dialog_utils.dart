// dialog_utils.dart
// Gestisce dialog, popup e bottom sheet adattivi (Material / Cupertino)
// ✅ Versione con gestione corretta del context.mounted per prevenire crash

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ✅ Importa direttamente i moduli specializzati
import 'dialogs/dialog_commons.dart';
import 'dialogs/dialog_sheets.dart';
import 'dialogs/dialog_profile.dart';
import 'dialogs/dialog_inputs.dart';
import 'dialogs/dialog_pickers.dart';

class DialogUtils {
  /// ℹ️ Mostra un dialog informativo (OK)
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    if (!context.mounted) return;

    await _showDialog(
      context: context,
      title: title,
      content: content,
      actions: (context, textColor) => [
        DialogCommons.buildActionButton(context, "OK", textColor),
      ],
    );
  }

  /// ❓ Dialog di conferma (Annulla / Conferma)
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = "Conferma",
    String cancelText = "Annulla",
  }) async {
    if (!context.mounted) return false;

    final textColor = DialogCommons.textColor(context);
    final isDestructive = DialogCommons.isDestructiveAction(confirmText);
    final confirmColor = isDestructive ? AppColors.delete : textColor;

    return await _showDialog<bool>(
      context: context,
      title: title,
      content: content,
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

  /// 📊 Bottom sheet adattivo per selezione ordinamento
  static Future<String?> showSortSheet(
    BuildContext context, {
    required bool isDark,
    required List<Map<String, String>> options,
  }) async {
    if (!context.mounted) return null;

    return await DialogSheets.showAdaptiveSheet(
      context: context,
      title: 'Ordina spese',
      isDark: isDark,
      options: options,
    );
  }

  /// 👤 Bottom sheet adattivo con informazioni profilo e azioni
  static Future<void> showProfileSheet(
    BuildContext context, {
    required User? user,
    required File? localAvatar,
    required Future<void> Function() reloadAvatar,
  }) async {
    if (!context.mounted) return;

    final isDark = DialogCommons.isDark(context);
    final header = DialogProfile.buildProfileHeader(
      context,
      user,
      localAvatar,
      isDark,
    );

    if (DialogCommons.isIOS) {
      // ✅ Check aggiuntivo prima di showCupertinoModalPopup
      if (!context.mounted) return;

      await showCupertinoModalPopup(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: header,
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
        ),
      );
    } else {
      // ✅ Check aggiuntivo prima di showModalBottomSheet
      if (!context.mounted) return;

      await showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        builder: (_) => Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
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
        ),
      );
    }
  }

  /// ✏️ Dialog adattivo per inserimento campi di testo
  /// ✅ Ora usa InputDialogWidget che gestisce correttamente il dispose
  static Future<List<String>?> showInputDialogAdaptive(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> fields,
    String confirmText = "Salva",
    String cancelText = "Annulla",
    VoidCallback? onForgotPassword,
  }) async {
    if (!context.mounted) return null;

    final isCupertino = DialogCommons.isIOS;

    if (isCupertino) {
      // ✅ Check aggiuntivo prima di showCupertinoDialog
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

    // ✅ Check aggiuntivo prima di showDialog
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

  /// 💡 Dialog informativo con checkbox "Non mostrare più"
  static Future<bool> showInstructionDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = "OK",
    String checkboxLabel = "Non mostrare più",
  }) async {
    if (!context.mounted) return false;

    final textColor = DialogCommons.textColor(context);
    bool dontShowAgain = false;

    Widget buildContent(StateSetter setState) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: TextStyle(fontSize: DialogCommons.isIOS ? 13.sp : 14.sp),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        DialogInputs.buildCheckboxRow(
          setState,
          dontShowAgain,
          checkboxLabel,
          (value) => dontShowAgain = value,
        ),
      ],
    );

    if (DialogCommons.isIOS) {
      // ✅ Check aggiuntivo prima di showCupertinoDialog
      if (!context.mounted) return false;

      await showCupertinoDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setState) => CupertinoAlertDialog(
            title: Text(title, style: TextStyle(fontSize: 15.sp)),
            content: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Material(
                color: Colors.transparent,
                child: buildContent(setState),
              ),
            ),
            actions: [
              DialogCommons.buildActionButton(context, confirmText, textColor),
            ],
          ),
        ),
      );
    } else {
      // ✅ Check aggiuntivo prima di showDialog
      if (!context.mounted) return false;

      await showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: DialogCommons.roundedRectangleBorder(),
            title: Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            content: buildContent(setState),
            actions: [
              DialogCommons.buildActionButton(context, confirmText, textColor),
            ],
          ),
        ),
      );
    }

    return dontShowAgain;
  }

  /// 📅 Date picker adattivo (Material / Cupertino)
  static Future<DateTime?> showDatePickerAdaptive(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    if (!context.mounted) return null;

    final isDark = DialogCommons.isDark(context);
    final textColor = DialogCommons.textColor(context);
    final minDate = firstDate ?? DateTime(2000);
    final maxDate = lastDate ?? DateTime.now();

    if (DialogCommons.isIOS) {
      // ✅ Check aggiuntivo prima di showCupertinoModalPopup
      if (!context.mounted) return null;

      DateTime tempPicked = initialDate;

      return await showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (_) => Container(
          height: 300.h,
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              DialogPickers.buildDatePickerHeader(
                context,
                textColor,
                () => tempPicked,
              ),
              Divider(height: 0, thickness: 1.h),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  onDateTimeChanged: (newDate) => tempPicked = newDate,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Check aggiuntivo prima di showDatePicker
    if (!context.mounted) return null;

    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            shape: DialogCommons.roundedRectangleBorder(),
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

  /// 📆 Bottom sheet / Action sheet adattivo per selezione anno
  static Future<String?> showYearPickerAdaptive(
    BuildContext context, {
    required List<String> years,
    required String selectedYear,
  }) async {
    if (!context.mounted) return null;

    return await DialogSheets.showAdaptiveYearPicker(
      context: context,
      years: years,
      selectedYear: selectedYear,
      isDark: DialogCommons.isDark(context),
    );
  }

  /// 🕐 Dialog/Sheet adattivo per selezione orario
  static Future<TimeOfDay?> showTimePickerAdaptive(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) async {
    if (!context.mounted) return null;

    return await DialogPickers.showTimePickerAdaptive(
      context: context,
      initialTime: initialTime,
    );
  }

  // ========== METODO HELPER PRIVATO ==========
  /// Metodo unificato per mostrare dialog semplici (info/conferma)
  /// ✅ Con controllo context.mounted interno
  static Future<T?> _showDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    required List<Widget> Function(BuildContext, Color) actions,
  }) async {
    // ✅ Check all'inizio del metodo
    if (!context.mounted) return null;

    final textColor = DialogCommons.textColor(context);

    if (DialogCommons.isIOS) {
      // ✅ Check aggiuntivo prima di showCupertinoDialog
      if (!context.mounted) return null;

      return await showCupertinoDialog<T>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title, style: TextStyle(fontSize: 15.sp)),
          content: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(content, style: TextStyle(fontSize: 14.sp)),
          ),
          actions: actions(context, textColor),
        ),
      );
    }

    // ✅ Check aggiuntivo prima di showDialog
    if (!context.mounted) return null;

    return await showDialog<T>(
      context: context,
      builder: (_) => AlertDialog(
        shape: DialogCommons.roundedRectangleBorder(),
        title: Text(title, style: TextStyle(fontSize: 15.sp)),
        content: Text(content, style: TextStyle(fontSize: 14.sp)),
        actions: actions(context, textColor),
      ),
    );
  }
}
