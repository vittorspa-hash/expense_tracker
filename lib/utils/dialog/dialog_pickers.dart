// dialog_pickers.dart
// Questo file contiene metodi statici per la gestione dei picker nei dialog,
// adattivi tra iOS e Android.
//
// Funzionalità principali:
// - Header personalizzato per date picker (Cupertino-style)
// - Time picker adattivo (iOS/Android) con supporto tema chiaro/scuro
// - Stili e pulsanti conferma/cancella coerenti con il resto dell'app

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dialog_commons.dart';

class DialogPickers {
  // ---------------------------------------------------------------------------
  // 🔹 HEADER PER DATE PICKER
  // ---------------------------------------------------------------------------
  // Costruisce la riga superiore dei CupertinoPicker contenente:
  // - pulsante "Annulla" → chiude il dialog senza restituire valori
  // - pulsante "OK"      → conferma la selezione e restituisce la data selezionata
  static Widget buildDatePickerHeader(
    BuildContext context,
    Color txtColor,
    DateTime Function() getSelectedDate,
  ) =>
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

  // ---------------------------------------------------------------------------
  // 🔹 TIME PICKER ADATTIVO (iOS / Android)
  // ---------------------------------------------------------------------------
  // Mostra un picker per selezionare l'orario adattivo alla piattaforma:
  // - iOS → CupertinoDatePicker in modalità time
  // - Android → showTimePicker con tema personalizzato
  static Future<TimeOfDay?> showTimePickerAdaptive({
    required BuildContext context,
    required TimeOfDay initialTime,
    Color? primaryColor,
    Color? onSurfaceColor,
  }) async {
    final isDarkMode = DialogCommons.isDark(context);
    final themePrimary = primaryColor ?? AppColors.primary;
    final themeOnSurface = onSurfaceColor ??
        (isDarkMode ? AppColors.textLight : AppColors.textDark);

    // ------------------------ iOS --------------------------------------------
    if (DialogCommons.isIOS) {
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
              // Header con pulsanti OK/Annulla
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
              // Picker vero e proprio
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

    // ------------------------ ANDROID ---------------------------------------
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

  // ---------------------------------------------------------------------------
  // 🔹 STILE PULSANTI PER DATE/TIME PICKER
  // ---------------------------------------------------------------------------
  static ButtonStyle datePickerButtonStyle(Color color, bool isConfirm) =>
      TextButton.styleFrom(
        foregroundColor: color,
        textStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: isConfirm ? FontWeight.w600 : FontWeight.normal,
        ),
      );
}
