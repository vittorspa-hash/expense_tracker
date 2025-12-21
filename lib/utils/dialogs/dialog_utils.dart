import 'package:expense_tracker/pages/profile_page.dart';
import 'package:expense_tracker/pages/settings_page.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/profile_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/dialogs/dialog_styles.dart';
import 'package:expense_tracker/utils/dialogs/dialog_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// FILE: dialog_utils.dart
/// DESCRIZIONE: Classe di utilità statica per la gestione centralizzata dei dialoghi.
/// Implementa il pattern "Adaptive": controlla la piattaforma (iOS o Android)
/// e restituisce il widget nativo appropriato (Cupertino vs Material).
/// Gestisce:
/// 1. Alert (Info, Conferma, Istruzioni).
/// 2. Input (Form in dialog).
/// 3. Bottom Sheets (Menu, Profilo).
/// 4. Pickers (Data, Ora, Anno).

class DialogUtils {
  
  // --- DIALOGHI DI BASE ---
  // Metodi per mostrare avvisi semplici o richieste di conferma.
  // Utilizzano un helper privato `_showGenericDialog` per astrarre la scelta del widget.
  // 

  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    if (!context.mounted) return;
    await _showGenericDialog(
      context: context,
      title: title,
      content: content,
      actions: (ctx, color) => [
        DialogStyles.buildActionButton(ctx, "OK", color),
      ],
    );
  }

  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = "Conferma",
    String cancelText = "Annulla",
  }) async {
    if (!context.mounted) return false;
    final isDestructive = DialogStyles.isDestructiveAction(confirmText);
    final textColor = DialogStyles.textColor(context);
    final confirmColor = isDestructive ? AppColors.delete : textColor;

    return await _showGenericDialog<bool>(
      context: context,
      title: title,
      content: content,
      actions: (ctx, _) => [
        DialogStyles.buildActionButton(ctx, cancelText, textColor, false),
        DialogStyles.buildActionButton(ctx, confirmText, confirmColor, true),
      ],
    );
  }

  // Mostra un dialogo con una checkbox di stato (es. "Non mostrare più").
  // Richiede StatefulBuilder interno per aggiornare la UI del dialog senza ricostruire l'intera pagina.
  static Future<bool> showInstructionDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = "OK",
    String checkboxLabel = "Non mostrare più",
  }) async {
    if (!context.mounted) return false;
    final textColor = DialogStyles.textColor(context);
    bool dontShowAgain = false;

    Widget buildContent(StateSetter setState) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: TextStyle(fontSize: DialogStyles.isIOS ? 13.sp : 14.sp),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        DialogCheckboxRow(
          value: dontShowAgain,
          label: checkboxLabel,
          onChanged: (val) => setState(() => dontShowAgain = val),
        ),
      ],
    );

    if (DialogStyles.isIOS) {
      await showCupertinoDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setState) => CupertinoAlertDialog(
            title: Text(title, style: TextStyle(fontSize: 15.sp)),
            content: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Material(
                color: Colors.transparent,
                child: buildContent(setState),
              ),
            ),
            actions: [
              DialogStyles.buildActionButton(ctx, confirmText, textColor),
            ],
          ),
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape: DialogStyles.roundedRectangleBorder(),
            title: Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            content: buildContent(setState),
            actions: [
              DialogStyles.buildActionButton(ctx, confirmText, textColor),
            ],
          ),
        ),
      );
    }
    return dontShowAgain;
  }

  // --- DIALOGHI DI INPUT ---
  // Wrapper per mostrare form complessi (es. cambio password) dentro un dialog.
  static Future<List<String>?> showInputDialogAdaptive(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> fields,
    String confirmText = "Salva",
    String cancelText = "Annulla",
    VoidCallback? onForgotPassword,
  }) async {
    if (!context.mounted) return null;
    final widget = InputDialogWidget(
      title: title,
      fields: fields,
      confirmText: confirmText,
      cancelText: cancelText,
      onForgotPassword: onForgotPassword,
    );

    if (DialogStyles.isIOS) {
      return await showCupertinoDialog<List<String>>(
        context: context,
        builder: (_) => widget,
      );
    }
    return await showDialog<List<String>>(
      context: context,
      builder: (_) => widget,
    );
  }

  // --- BOTTOM SHEETS & MENU ---
  // Gestisce menu a comparsa dal basso.
  // Su iOS usa `CupertinoActionSheet`, su Android `showModalBottomSheet`.

  static Future<String?> showSortSheet(
    BuildContext context, {
    required bool isDark,
    required List<Map<String, String>> options,
  }) async {
    if (!context.mounted) return null;
    const cancelLabel = 'Annulla';

    if (DialogStyles.isIOS) {
      return await showCupertinoModalPopup<String>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: DialogStyles.buildSheetTitle('Ordina spese'),
          actions: options.map((opt) {
            return DialogStyles.buildSheetAction(
              context,
              text: opt["title"] ?? "",
              isDark: isDark,
              onPressed: () => Navigator.pop(context, opt["criteria"]),
            );
          }).toList(),
          cancelButton: DialogStyles.buildSheetAction(
            context,
            text: cancelLabel,
            isDark: isDark,
            isCancel: true,
            onPressed: () => Navigator.pop(context, null),
          ),
        ),
      );
    }

    return await showModalBottomSheet<String>(
      context: context,
      shape: DialogStyles.roundedRectangleBorder(),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 22.h),
            DialogStyles.buildSheetTitle('Ordina spese'),
            const Divider(),
            ...options.map(
              (opt) => ListTile(
                title: Text(
                  opt["title"] ?? "",
                  style: TextStyle(fontSize: 17.sp),
                ),
                onTap: () => Navigator.pop(context, opt["criteria"]),
              ),
            ),
            const Divider(),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(
                cancelLabel,
                style: TextStyle(
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                  fontSize: 17.sp,
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  // Menu Profilo complesso: gestisce navigazione e logica di logout.
  // 
  static Future<void> showProfileSheet(BuildContext context) async {
    if (!context.mounted) return;
    final isDark = DialogStyles.isDark(context);

    // -- Logica di Navigazione e Logout interna --
    Future<void> handleNav(
      String routeName,
      Future<void> Function()? reload,
    ) async {
      Navigator.pop(context);
      await Future.delayed(Duration.zero);
      if (context.mounted) await Navigator.pushNamed(context, routeName);
      if (reload != null && context.mounted) {
        try {
          await reload();
        } catch (e) {
          debugPrint('⚠️ Errore reload avatar: $e');
        }
      }
    }

    Future<void> handleLogout() async {
      final auth = context.read<AuthProvider>();
      // Chiude il sheet del profilo per mostrare la conferma pulita
      Navigator.pop(context);

      final confirm = await showConfirmDialog(
        context,
        title: "Conferma logout",
        content: "Sei sicuro di voler uscire dall'account?",
        confirmText: "Logout",
      );

      if (confirm == true && context.mounted) {
        try {
          await auth.signOut();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Errore logout: $e"),
                backgroundColor: AppColors.snackBar,
              ),
            );
          }
        }
      }
    }
    // ---------------------------------------------

    // UI Builder usando Consumer
    Widget sheetBuilder(BuildContext _) => Consumer<ProfileProvider>(
      builder: (ctx, provider, _) {
        final user = provider.user;
        final localAvatar = provider.localImage;
        Future<void> reload() => provider.loadLocalData();

        if (DialogStyles.isIOS) {
          return CupertinoActionSheet(
            title: ProfileHeader(user: user, localAvatar: localAvatar),
            actions: [
              DialogStyles.buildSheetAction(
                context,
                text: "Profilo",
                isDark: isDark,
                onPressed: () => handleNav(ProfilePage.route, reload),
              ),
              DialogStyles.buildSheetAction(
                context,
                text: "Impostazioni",
                isDark: isDark,
                onPressed: () => handleNav(SettingsPage.route, null),
              ),
              DialogStyles.buildSheetAction(
                context,
                text: "Logout",
                isDark: isDark,
                isDestructive: true,
                onPressed: handleLogout,
              ),
            ],
            cancelButton: DialogStyles.buildSheetAction(
              context,
              text: "Chiudi",
              isDark: isDark,
              isCancel: true,
              onPressed: () => Navigator.pop(context),
            ),
          );
        } else {
          // Material
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProfileHeader(user: user, localAvatar: localAvatar),
                  SizedBox(height: 20.h),
                  MaterialProfileTile(
                    icon: Icons.person,
                    text: "Profilo",
                    onTap: () => handleNav(ProfilePage.route, reload),
                  ),
                  MaterialProfileTile(
                    icon: Icons.settings,
                    text: "Impostazioni",
                    onTap: () => handleNav(SettingsPage.route, null),
                  ),
                  MaterialProfileTile(
                    icon: Icons.logout,
                    text: "Logout",
                    color: AppColors.delete,
                    onTap: handleLogout,
                  ),
                  SizedBox(height: 12.h),
                  DialogStyles.buildCloseButton(context),
                ],
              ),
            ),
          );
        }
      },
    );

    if (DialogStyles.isIOS) {
      await showCupertinoModalPopup(context: context, builder: sheetBuilder);
    } else {
      await showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        builder: sheetBuilder,
      );
    }
  }

  // --- DATE & TIME PICKERS ---
  // Selettori di data e ora.
  // Su iOS usano un container custom con altezza fissa per simulare lo slot machine style.
  // Su Android usano i dialoghi nativi full-screen.
  // 

  static Future<DateTime?> showDatePickerAdaptive(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    if (!context.mounted) return null;
    final isDark = DialogStyles.isDark(context);
    final minDate = firstDate ?? DateTime(2000);
    final maxDate = lastDate ?? DateTime.now();

    if (DialogStyles.isIOS) {
      DateTime tempPicked = initialDate;
      return await showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (_) => Container(
          height: 300.h,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              PickerHeader(
                textColor: DialogStyles.textColor(context),
                onConfirm: () => Navigator.pop(context, tempPicked),
              ),
              Divider(height: 0, thickness: 1.h),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  onDateTimeChanged: (val) => tempPicked = val,
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
            shape: DialogStyles.roundedRectangleBorder(),
          ),
        ),
        child: child!,
      ),
    );
  }

  static Future<TimeOfDay?> showTimePickerAdaptive(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) async {
    if (!context.mounted) return null;
    final isDark = DialogStyles.isDark(context);

    if (DialogStyles.isIOS) {
      TimeOfDay picked = initialTime;
      final now = DateTime.now();
      return await showCupertinoModalPopup<TimeOfDay>(
        context: context,
        builder: (_) => Container(
          height: 300.h,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              PickerHeader(
                textColor: DialogStyles.textColor(context),
                onConfirm: () => Navigator.pop(context, picked),
              ),
              Divider(height: 0, thickness: 1.h),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    now.year,
                    now.month,
                    now.day,
                    initialTime.hour,
                    initialTime.minute,
                  ),
                  use24hFormat: true,
                  onDateTimeChanged: (val) =>
                      picked = TimeOfDay(hour: val.hour, minute: val.minute),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Material Theme helpers locali
    ColorScheme timeScheme(bool dark) => ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textLight,
      secondary: AppColors.primary,
      onSecondary: AppColors.textLight,
      surface: dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      onSurface: dark ? AppColors.textLight : AppColors.textDark,
      error: AppColors.delete,
      onError: AppColors.textLight,
    );

    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: timeScheme(isDark),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            dialBackgroundColor: isDark
                ? AppColors.cardDark
                : AppColors.cardLight,
            entryModeIconColor: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
  }

  static Future<String?> showYearPickerAdaptive(
    BuildContext context, {
    required List<String> years,
    required String selectedYear,
  }) async {
    if (!context.mounted) return null;
    final isDark = DialogStyles.isDark(context);
    final txtColor = DialogStyles.textColor(context);

    Widget buildItem(String year) => Text(
      year,
      style: TextStyle(
        color: txtColor,
        fontWeight: year == selectedYear ? FontWeight.bold : FontWeight.normal,
        fontSize: DialogStyles.isIOS ? 17.sp : 16.sp,
      ),
    );

    if (DialogStyles.isIOS) {
      return await showCupertinoModalPopup<String>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: DialogStyles.buildSheetTitle("Seleziona anno"),
          actions: years
              .map(
                (year) => CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context, year),
                  child: buildItem(year),
                ),
              )
              .toList(),
          cancelButton: DialogStyles.buildSheetAction(
            context,
            text: "Annulla",
            isDark: isDark,
            isCancel: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    }

    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: DialogStyles.buildSheetTitle("Seleziona anno"),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: years.length,
                  itemBuilder: (ctx, i) => ListTile(
                    title: Center(child: buildItem(years[i])),
                    onTap: () => Navigator.pop(context, years[i]),
                  ),
                ),
              ),
              Divider(height: 16.h),
              ListTile(
                title: Center(
                  child: Text(
                    "Annulla",
                    style: TextStyle(color: txtColor, fontSize: 15.sp),
                  ),
                ),
                onTap: () => Navigator.pop(context, null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- PRIVATE HELPERS ---
  
  static Future<T?> _showGenericDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    required List<Widget> Function(BuildContext, Color) actions,
  }) async {
    final textColor = DialogStyles.textColor(context);

    if (DialogStyles.isIOS) {
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
        shape: DialogStyles.roundedRectangleBorder(),
        title: Text(title, style: TextStyle(fontSize: 15.sp)),
        content: Text(content, style: TextStyle(fontSize: 14.sp)),
        actions: actions(context, textColor),
      ),
    );
  }
}