// dialog_helpers.dart
// Helper methods per DialogUtils
// Questo file contiene una raccolta di metodi statici per la costruzione di dialog, bottom sheet e componenti correlati in modo riutilizzabile e adattivo tra iOS e Android.
// Tutte le funzioni sono pensate per essere pure, senza modificare stato globale, e facilitano la creazione di UI coerenti e accessibili.
// Ogni sezione è suddivisa per tipologia di componente o funzionalità.

import 'dart:io';
import 'package:expense_tracker/pages/profile_page.dart';
import 'package:expense_tracker/pages/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DialogHelpers {
  // ===================== PROPRIETÀ COMUNI =====================
  // Ritorna true se la piattaforma è iOS
  static bool get isIOS => Platform.isIOS;

  // Verifica se il tema attuale è scuro
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Restituisce il colore del testo in base al tema
  static Color textColor(BuildContext context) =>
      isDark(context) ? AppColors.textLight : AppColors.textDark;

  // ===================== UTILITY METHODS =====================
  // Controlla se il testo rappresenta un'azione distruttiva (es. elimina/logout)
  static bool isDestructiveAction(String text) =>
      text.toLowerCase().contains("elimina") ||
      text.toLowerCase().contains("logout");

  // Restituisce un bordo arrotondato per i dialog
  static RoundedRectangleBorder roundedRectangleBorder() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r));

  // ===================== DIALOG BUTTONS (UNIFICATI) =====================
  /// Crea un bottone adattivo per dialog (iOS/Android)
  static Widget buildActionButton(
    BuildContext context,
    String text,
    Color color, [
    bool? returnValue,
  ]) {
    if (isIOS) {
      return CupertinoDialogAction(
        isDefaultAction: returnValue != false,
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

  // ===================== SHEET COMPONENTS =====================
  // Crea il titolo per un bottom sheet
  static Widget buildSheetTitle(String title) => Text(
    title,
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
  );

  // Bottone per bottom sheet stile Cupertino
  static Widget buildCupertinoSheetButton(
    BuildContext context,
    String text,
    bool isDark,
    String? returnValue,
  ) => CupertinoActionSheetAction(
    isDefaultAction: returnValue == null,
    onPressed: () => Navigator.pop(context, returnValue),
    child: Text(
      text,
      style: TextStyle(
        color: isDark ? AppColors.textLight : AppColors.textDark,
        fontSize: 17.sp,
      ),
    ),
  );

  // Bottone per bottom sheet stile Material
  static Widget buildMaterialSheetButton(
    BuildContext context,
    String text,
    bool isDark,
    String? returnValue,
  ) => TextButton(
    onPressed: () => Navigator.pop(context, returnValue),
    child: Text(
      text,
      style: TextStyle(
        color: isDark ? AppColors.textLight : AppColors.textDark,
        fontSize: 17.sp,
      ),
    ),
  );

  // ===================== ADAPTIVE SHEET BUILDERS =====================
  // Mostra un bottom sheet adattivo con opzioni
  static Future<String?> showAdaptiveSheet({
    required BuildContext context,
    required String title,
    required bool isDark,
    required List<Map<String, String>> options,
  }) async {
    const cancelLabel = 'Annulla';

    if (isIOS) {
      return await showCupertinoModalPopup<String>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: buildSheetTitle(title),
          actions: options
              .map(
                (opt) => buildCupertinoSheetButton(
                  context,
                  opt["title"] ?? "",
                  isDark,
                  opt["criteria"],
                ),
              )
              .toList(),
          cancelButton: buildCupertinoSheetButton(
            context,
            cancelLabel,
            isDark,
            null,
          ),
        ),
      );
    }

    return await showModalBottomSheet<String>(
      context: context,
      shape: roundedRectangleBorder(),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 22.h),
            buildSheetTitle(title),
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
            buildMaterialSheetButton(context, cancelLabel, isDark, null),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  // Mostra un picker per la selezione dell'anno
  static Future<String?> showAdaptiveYearPicker({
    required BuildContext context,
    required List<String> years,
    required String selectedYear,
    required bool isDark,
  }) async {
    const title = "Seleziona anno";
    const cancelLabel = "Annulla";
    final txtColor = isDark ? AppColors.textLight : AppColors.textDark;

    Widget buildYearItem(String year) => Text(
      year,
      style: TextStyle(
        color: txtColor,
        fontWeight: year == selectedYear ? FontWeight.bold : FontWeight.normal,
        fontSize: isIOS ? 17.sp : 16.sp,
      ),
    );

    if (isIOS) {
      return await showCupertinoModalPopup<String>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: buildSheetTitle(title),
          actions: years
              .map(
                (year) => CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context, year),
                  child: buildYearItem(year),
                ),
              )
              .toList(),
          cancelButton: buildCupertinoSheetButton(
            context,
            cancelLabel,
            isDark,
            null,
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
                child: buildSheetTitle(title),
              ),
              ...years.map(
                (year) => ListTile(
                  title: Center(child: buildYearItem(year)),
                  onTap: () => Navigator.pop(context, year),
                ),
              ),
              Divider(height: 16.h),
              ListTile(
                title: Center(
                  child: Text(
                    cancelLabel,
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

  // ===================== PROFILE COMPONENTS =====================
  // Costruisce l'header del profilo utente
  static Widget buildProfileHeader(
    BuildContext context,
    User? user,
    File? localAvatar,
    bool isDark,
  ) {
    final txtColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Column(
      children: [
        buildAvatar(user, localAvatar),
        SizedBox(height: isIOS ? 10.h : 12.h),
        Text(
          user?.displayName ?? "Account",
          style: TextStyle(
            color: txtColor,
            fontWeight: FontWeight.bold,
            fontSize: isIOS ? 15.sp : 17.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          user?.email ?? "",
          style: TextStyle(color: txtColor, fontSize: isIOS ? 13.sp : 15.sp),
        ),
      ],
    );
  }

  // Restituisce l'avatar utente (locale o da rete)
  static Widget buildAvatar(User? user, File? localAvatar) => CircleAvatar(
    radius: 34.r,
    backgroundColor: AppColors.backgroundAvatar,
    backgroundImage: localAvatar != null
        ? FileImage(localAvatar)
        : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
    child: localAvatar == null && user?.photoURL == null
        ? Icon(Icons.person, size: 50.sp, color: AppColors.avatar)
        : null,
  );

  // Azione per aprire la pagina profilo e ricaricare l'avatar
  static Widget buildProfileAction(
    BuildContext context,
    User? user,
    File? localAvatar,
    Future<void> Function() reloadAvatar,
    bool isDark,
  ) => CupertinoActionSheetAction(
    onPressed: () async {
      Navigator.pop(context);
      await Navigator.pushNamed(context, ProfilePage.route);
      await reloadAvatar();
    },
    child: Text(
      "Profilo",
      style: TextStyle(
        color: isDark ? AppColors.textLight : AppColors.textDark,
        fontSize: 17.sp,
      ),
    ),
  );

  // Azione per aprire la pagina impostazioni
  static Widget buildSettingsAction(BuildContext context, bool isDark) =>
      CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, SettingsPage.route);
        },
        child: Text(
          "Impostazioni",
          style: TextStyle(
            color: isDark ? AppColors.textLight : AppColors.textDark,
            fontSize: 17.sp,
          ),
        ),
      );

  // Azione di logout per Cupertino
  static Widget buildLogoutAction(
    BuildContext context,
    bool isDark,
    bool isCupertino,
  ) {
    if (!isCupertino) return const SizedBox.shrink();

    return CupertinoActionSheetAction(
      isDestructiveAction: true,
      onPressed: () => _handleLogout(context),
      child: Text(
        "Logout",
        style: TextStyle(color: AppColors.delete, fontSize: 17.sp),
      ),
    );
  }

  // ListTile per aprire la pagina profilo
  static Widget buildProfileListTile(
    BuildContext context,
    User? user,
    File? localAvatar,
    Future<void> Function() reloadAvatar,
    bool isDark,
  ) => ListTile(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
    leading: Icon(Icons.person, color: AppColors.primary, size: 24.sp),
    title: Text("Profilo", style: TextStyle(fontSize: 16.sp)),
    onTap: () async {
      Navigator.pop(context);
      await Navigator.pushNamed(context, ProfilePage.route);
      await reloadAvatar();
    },
  );

  // ListTile per aprire la pagina impostazioni
  static Widget buildSettingsListTile(BuildContext context, bool isDark) =>
      ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        leading: Icon(Icons.settings, color: AppColors.primary, size: 24.sp),
        title: Text("Impostazioni", style: TextStyle(fontSize: 16.sp)),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, SettingsPage.route);
        },
      );

  // ListTile per logout
  static Widget buildLogoutListTile(BuildContext context, bool isDark) =>
      ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        leading: Icon(Icons.logout, color: AppColors.delete, size: 24.sp),
        title: Text(
          "Logout",
          style: TextStyle(color: AppColors.delete, fontSize: 16.sp),
        ),
        onTap: () => _handleLogout(context),
      );

  // Gestisce la logica di conferma e logout
  static Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context);

    final textColor = DialogHelpers.textColor(context);
    const title = "Conferma logout";
    const content = "Sei sicuro di voler uscire dall'account?";
    const cancelText = "Annulla";
    const confirmText = "Logout";

    bool? confirm;

    if (isIOS) {
      confirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title, style: TextStyle(fontSize: 15.sp)),
          content: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(content, style: TextStyle(fontSize: 14.sp)),
          ),
          actions: [
            buildActionButton(context, cancelText, textColor, false),
            buildActionButton(context, confirmText, AppColors.delete, true),
          ],
        ),
      );
    } else {
      confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: roundedRectangleBorder(),
          title: Text(
            title,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          content: Text(content, style: TextStyle(fontSize: 14.sp)),
          actions: [
            buildActionButton(context, cancelText, textColor, false),
            buildActionButton(context, confirmText, AppColors.delete, true),
          ],
        ),
      );
    }

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  // Bottone per chiudere un dialog
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

  // ===================== INPUT DIALOG COMPONENTS =====================
  // Costruisce un campo di testo per dialog, con gestione password e focus
  static Widget buildTextField(
    BuildContext dialogCtx,
    Map<String, dynamic> field,
    TextEditingController controller,
    ValueNotifier<bool> obscure,
    List<FocusNode> focusNodes,
    int index,
    int totalFields,
    Color txtColor,
  ) {
    final hasPassword = field["obscureText"] == true;
    final isLast = index == totalFields - 1;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: ValueListenableBuilder<bool>(
        valueListenable: obscure,
        builder: (_, hide, _) => TextField(
          controller: controller,
          focusNode: focusNodes[index],
          obscureText: hide,
          keyboardType: field["keyboardType"] ?? TextInputType.text,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          onSubmitted: (_) {
            final scope = FocusScope.of(dialogCtx);
            isLast
                ? scope.unfocus()
                : scope.requestFocus(focusNodes[index + 1]);
          },
          style: TextStyle(fontSize: 15.sp),
          decoration: InputDecoration(
            labelText: field["label"],
            prefixIcon: field["prefixIcon"] != null
                ? Icon(field["prefixIcon"], size: 20.sp)
                : null,
            hintText: field["hintText"],
            hintStyle: TextStyle(fontSize: 14.sp),
            suffixIcon: hasPassword
                ? IconButton(
                    icon: Icon(
                      hide ? Icons.visibility : Icons.visibility_off,
                      color: txtColor,
                      size: 20.sp,
                    ),
                    onPressed: () => obscure.value = !hide,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // Bottone per la funzione "Password dimenticata?"
  static Widget buildForgotPasswordButton(
    VoidCallback onPressed,
    Color txtColor,
  ) => Padding(
    padding: EdgeInsets.only(top: 8.h),
    child: Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size(0, 30.h),
        ),
        child: Text(
          "Password dimenticata?",
          style: TextStyle(
            color: txtColor,
            fontSize: 13.sp,
            decoration: TextDecoration.underline,
            decorationColor: txtColor,
          ),
        ),
      ),
    ),
  );

  // Costruisce le azioni di conferma/cancella per dialog di input
  static List<Widget> buildDialogActions(
    BuildContext context,
    String cancelText,
    String confirmText,
    List<TextEditingController> controllers,
    Color txtColor,
    bool isCupertino,
  ) {
    void onConfirm() =>
        Navigator.pop(context, controllers.map((c) => c.text).toList());

    if (isCupertino) {
      return [
        buildActionButton(context, cancelText, txtColor, null),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: onConfirm,
          child: Text(
            confirmText,
            style: TextStyle(color: txtColor, fontSize: 14.sp),
          ),
        ),
      ];
    }

    return [
      buildActionButton(context, cancelText, txtColor, null),
      TextButton(
        onPressed: onConfirm,
        child: Text(
          confirmText,
          style: TextStyle(color: txtColor, fontSize: 14.sp),
        ),
      ),
    ];
  }

  // ===================== INSTRUCTION DIALOG COMPONENTS =====================
  // Costruisce una riga con checkbox per dialog istruzioni
  static Widget buildCheckboxRow(
    StateSetter setState,
    bool value,
    String label,
    Function(bool) onChanged,
  ) => GestureDetector(
    onTap: () => setState(() => onChanged(!value)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox.adaptive(
          value: value,
          onChanged: (v) => setState(() => onChanged(v ?? false)),
          activeColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(label, style: TextStyle(fontSize: 13.sp)),
        ),
      ],
    ),
  );

  // ===================== DATE PICKER COMPONENTS =====================
  // Header per date picker stile Cupertino
  static Widget buildDatePickerHeader(
    BuildContext context,
    Color txtColor,
    DateTime Function() getSelectedDate,
  ) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            "Annulla",
            style: TextStyle(color: txtColor, fontSize: 14.sp),
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context, getSelectedDate()),
          child: Text(
            "OK",
            style: TextStyle(
              color: txtColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  // Mostra un time picker adattivo (iOS/Android)
  static Future<TimeOfDay?> showTimePickerAdaptive({
    required BuildContext context,
    required TimeOfDay initialTime,
    Color? primaryColor,
    Color? onSurfaceColor,
  }) async {
    final isDarkMode = isDark(context);
    final themePrimary = primaryColor ?? AppColors.primary;
    final themeOnSurface =
        onSurfaceColor ??
        (isDarkMode ? AppColors.textLight : AppColors.textDark);

    if (isIOS) {
      TimeOfDay picked = initialTime;
      DateTime now = DateTime.now();
      DateTime initialDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        initialTime.hour,
        initialTime.minute,
      );

      return await showCupertinoModalPopup<TimeOfDay>(
        context: context,
        builder: (_) => Container(
          height: 300.h,
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context, null),
                      child: Text(
                        "Annulla",
                        style: TextStyle(
                          color: themeOnSurface,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context, picked),
                      child: Text(
                        "OK",
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.textLight
                              : AppColors.textDark,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 0, thickness: 1.h),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  use24hFormat: true,
                  onDateTimeChanged: (dateTime) {
                    picked = TimeOfDay(
                      hour: dateTime.hour,
                      minute: dateTime.minute,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme(
            brightness: isDarkMode ? Brightness.dark : Brightness.light,
            primary: themePrimary,
            onPrimary: AppColors.textLight,
            secondary: themePrimary,
            onSecondary: AppColors.textLight,
            surface: isDarkMode
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            onSurface: themeOnSurface,
            error: AppColors.delete,
            onError: AppColors.textLight,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: isDarkMode
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            hourMinuteTextColor: WidgetStateColor.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.textLight
                  : themeOnSurface,
            ),
            dayPeriodTextColor: WidgetStateColor.resolveWith(
              (_) => themeOnSurface,
            ),
            dialBackgroundColor: isDarkMode
                ? AppColors.cardDark
                : AppColors.cardLight,
            entryModeIconColor: themePrimary,
          ),
        ),
        child: child!,
      ),
    );
  }

  // Stile per i bottoni del date picker
  static ButtonStyle datePickerButtonStyle(Color color, bool isConfirm) =>
      TextButton.styleFrom(
        foregroundColor: color,
        textStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: isConfirm ? FontWeight.w600 : FontWeight.normal,
        ),
      );
}
