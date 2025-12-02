// dialog_utils.dart
// Gestisce dialog, popup e bottom sheet adattivi (Material / Cupertino)
// Questo file fornisce una serie di metodi statici per mostrare dialog, popup e bottom sheet che si adattano automaticamente allo stile della piattaforma (iOS/Android).
// Include: info dialog, conferma, input multipli, istruzioni, date/anno picker, profile sheet.
// Tutte le funzioni sono pensate per essere chiamate da qualsiasi punto dell'applicazione.
// Utilizza DialogHelpers per componenti riutilizzabili e logica di stile.

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dialog_helpers.dart';

class DialogUtils {
  /// ℹ️ Mostra un dialog informativo (OK)
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    if (!context.mounted) return;

    return _showDialog(
      context: context,
      title: title,
      content: content,
      actions: (context, textColor) => [
        DialogHelpers.buildActionButton(context, "OK", textColor),
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

    final textColor = DialogHelpers.textColor(context);
    final isDestructive = DialogHelpers.isDestructiveAction(confirmText);
    final confirmColor = isDestructive ? AppColors.delete : textColor;

    return _showDialog<bool>(
      context: context,
      title: title,
      content: content,
      actions: (context, _) => [
        DialogHelpers.buildActionButton(context, cancelText, textColor, false),
        DialogHelpers.buildActionButton(context, confirmText, confirmColor, true),
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

    return DialogHelpers.showAdaptiveSheet(
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

    final isDark = DialogHelpers.isDark(context);
    final header = DialogHelpers.buildProfileHeader(
      context,
      user,
      localAvatar,
      isDark,
    );

    if (DialogHelpers.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: header,
          actions: [
            DialogHelpers.buildProfileAction(
              context,
              user,
              localAvatar,
              reloadAvatar,
              isDark,
            ),
            DialogHelpers.buildSettingsAction(context, isDark),
            DialogHelpers.buildLogoutAction(context, isDark, true),
          ],
          cancelButton: DialogHelpers.buildCupertinoSheetButton(
            context,
            "Chiudi",
            isDark,
            null,
          ),
        ),
      );
    } else {
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
                DialogHelpers.buildProfileListTile(
                  context,
                  user,
                  localAvatar,
                  reloadAvatar,
                  isDark,
                ),
                DialogHelpers.buildSettingsListTile(context, isDark),
                DialogHelpers.buildLogoutListTile(context, isDark),
                SizedBox(height: 12.h),
                DialogHelpers.buildCloseButton(context),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// ✏️ Dialog adattivo per inserimento campi di testo
  static Future<List<String>?> showInputDialogAdaptive(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> fields,
    String confirmText = "Salva",
    String cancelText = "Annulla",
    VoidCallback? onForgotPassword,
  }) async {
    if (!context.mounted) return null;

    final textColor = DialogHelpers.textColor(context);
    final controllers = fields
        .map((f) => TextEditingController(text: f["initialValue"] ?? ""))
        .toList();
    final obscureStates = fields
        .map((f) => ValueNotifier<bool>(f["obscureText"] ?? false))
        .toList();
    final focusNodes = List.generate(fields.length, (_) => FocusNode());

    Widget buildFields(BuildContext dialogCtx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          fields.length,
          (i) => DialogHelpers.buildTextField(
            dialogCtx,
            fields[i],
            controllers[i],
            obscureStates[i],
            focusNodes,
            i,
            fields.length,
            textColor,
          ),
        ),
        if (onForgotPassword != null)
          DialogHelpers.buildForgotPasswordButton(onForgotPassword, textColor),
      ],
    );

    if (DialogHelpers.isIOS) {
      return await showCupertinoDialog<List<String>>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title, style: TextStyle(fontSize: 16.sp)),
          content: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Material(color: Colors.transparent, child: buildFields(ctx)),
          ),
          actions: DialogHelpers.buildDialogActions(
            ctx,
            cancelText,
            confirmText,
            controllers,
            textColor,
            true,
          ),
        ),
      );
    }

    return await showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(child: buildFields(ctx)),
        actions: DialogHelpers.buildDialogActions(
          ctx,
          cancelText,
          confirmText,
          controllers,
          textColor,
          false,
        ),
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

    final textColor = DialogHelpers.textColor(context);
    bool dontShowAgain = false;

    Widget buildContent(StateSetter setState) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: TextStyle(fontSize: DialogHelpers.isIOS ? 13.sp : 14.sp),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        DialogHelpers.buildCheckboxRow(
          setState,
          dontShowAgain,
          checkboxLabel,
          (value) => dontShowAgain = value,
        ),
      ],
    );

    if (DialogHelpers.isIOS) {
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
              DialogHelpers.buildActionButton(context, confirmText, textColor),
            ],
          ),
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: DialogHelpers.roundedRectangleBorder(),
            title: Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            content: buildContent(setState),
            actions: [
              DialogHelpers.buildActionButton(context, confirmText, textColor),
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

    final isDark = DialogHelpers.isDark(context);
    final textColor = DialogHelpers.textColor(context);
    final minDate = firstDate ?? DateTime(2000);
    final maxDate = lastDate ?? DateTime.now();

    if (DialogHelpers.isIOS) {
      DateTime tempPicked = initialDate;

      return await showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (_) => Container(
          height: 300.h,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              DialogHelpers.buildDatePickerHeader(
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

    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            shape: DialogHelpers.roundedRectangleBorder(),
            cancelButtonStyle: DialogHelpers.datePickerButtonStyle(
              textColor,
              false,
            ),
            confirmButtonStyle: DialogHelpers.datePickerButtonStyle(
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

    return DialogHelpers.showAdaptiveYearPicker(
      context: context,
      years: years,
      selectedYear: selectedYear,
      isDark: DialogHelpers.isDark(context),
    );
  }

  /// 🕐 Dialog/Sheet adattivo per selezione orario
  static Future<TimeOfDay?> showTimePickerAdaptive(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) async {
    if (!context.mounted) return null;

    return await DialogHelpers.showTimePickerAdaptive(
      context: context,
      initialTime: initialTime,
    );
  }

  // ========== METODO HELPER PRIVATO ==========
  /// Metodo unificato per mostrare dialog semplici (info/conferma)
  static Future<T?> _showDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    required List<Widget> Function(BuildContext, Color) actions,
  }) async {
    final textColor = DialogHelpers.textColor(context);

    if (DialogHelpers.isIOS) {
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

    return await showDialog<T>(
      context: context,
      builder: (_) => AlertDialog(
        shape: DialogHelpers.roundedRectangleBorder(),
        title: Text(title, style: TextStyle(fontSize: 15.sp)),
        content: Text(content, style: TextStyle(fontSize: 14.sp)),
        actions: actions(context, textColor),
      ),
    );
  }
}
