// dialog_pickers.dart
// Questo file contiene metodi statici per la gestione dei picker nei dialog,
// adattivi tra iOS e Android.
// ✅ Versione migliorata con context safety, DRY e costanti centralizzate

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dialog_commons.dart';

class DialogPickers {
  // ========== PICKER HEADER BUILDER ==========

  /// Costruisce l'header standard per i picker Cupertino
  ///
  /// **Parametri:**
  /// - [onCancel]: Callback quando si preme "Annulla" (default: pop con null)
  /// - [onConfirm]: Callback quando si preme "OK" (deve restituire il valore)
  ///
  /// ✅ Estratto per evitare duplicazione codice
  static Widget buildPickerHeader(
    BuildContext context,
    Color txtColor, {
    VoidCallback? onCancel,
    required VoidCallback onConfirm,
  }) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Pulsante Annulla
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onCancel ?? () => Navigator.pop(context, null),
          child: Text(
            "Annulla",
            style: TextStyle(color: txtColor, fontSize: 14.sp),
          ),
        ),
        // Pulsante OK
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onConfirm,
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

  // ========== DATE PICKER HEADER ==========

  /// Header per date picker con callback per ottenere la data selezionata
  /// ✅ Ora usa il builder generico
  static Widget buildDatePickerHeader(
    BuildContext context,
    Color txtColor,
    DateTime Function() getSelectedDate,
  ) => buildPickerHeader(
    context,
    txtColor,
    onConfirm: () => Navigator.pop(context, getSelectedDate()),
  );

  // ========== TIME PICKER ADAPTIVE ==========

  /// Mostra un picker per selezionare l'orario adattivo alla piattaforma
  ///
  /// **Parametri:**
  /// - [initialTime]: Orario iniziale mostrato nel picker
  /// - [primaryColor]: Colore primario per il tema (opzionale)
  /// - [onSurfaceColor]: Colore del testo (opzionale)
  ///
  /// **Comportamento:**
  /// - iOS: CupertinoDatePicker con header personalizzato
  /// - Android: showTimePicker Material con tema scuro/chiaro
  ///
  /// ✅ Ora con context.mounted check per prevenire crash
  static Future<TimeOfDay?> showTimePickerAdaptive({
    required BuildContext context,
    required TimeOfDay initialTime,
    Color? primaryColor,
    Color? onSurfaceColor,
  }) async {
    // ✅ Check iniziale
    if (!context.mounted) return null;

    final isDarkMode = DialogCommons.isDark(context);
    final themePrimary = primaryColor ?? AppColors.primary;
    final themeOnSurface =
        onSurfaceColor ??
        (isDarkMode ? AppColors.textLight : AppColors.textDark);

    // ========== iOS CUPERTINO ==========
    if (DialogCommons.isIOS) {
      // ✅ Check aggiuntivo prima di showCupertinoModalPopup
      if (!context.mounted) return null;

      // Variabile per catturare la selezione
      TimeOfDay picked = initialTime;

      final now = DateTime.now();
      final initialDateTime = DateTime(
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
              // ✅ Usa il builder generico invece di duplicare codice
              buildPickerHeader(
                context,
                themeOnSurface,
                onConfirm: () => Navigator.pop(context, picked),
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

    // ========== ANDROID MATERIAL ==========
    // ✅ Check aggiuntivo prima di showTimePicker
    if (!context.mounted) return null;

    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: _buildTimePickerColorScheme(
            isDarkMode,
            themePrimary,
            themeOnSurface,
          ),
          timePickerTheme: _buildTimePickerTheme(
            isDarkMode,
            themePrimary,
            themeOnSurface,
          ),
        ),
        child: child!,
      ),
    );
  }

  // ========== THEME BUILDERS (Private) ==========

  /// Costruisce il ColorScheme per il time picker Material
  /// ✅ Estratto per ridurre complessità
  static ColorScheme _buildTimePickerColorScheme(
    bool isDarkMode,
    Color primary,
    Color onSurface,
  ) {
    return ColorScheme(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: AppColors.textLight,
      secondary: primary,
      onSecondary: AppColors.textLight,
      surface: isDarkMode
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      onSurface: onSurface,
      error: AppColors.delete,
      onError: AppColors.textLight,
    );
  }

  /// Costruisce il TimePickerThemeData per il time picker Material
  /// ✅ Estratto per ridurre complessità
  static TimePickerThemeData _buildTimePickerTheme(
    bool isDarkMode,
    Color primary,
    Color onSurface,
  ) {
    return TimePickerThemeData(
      backgroundColor: isDarkMode
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      hourMinuteTextColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.textLight
            : onSurface,
      ),
      dayPeriodTextColor: WidgetStateColor.resolveWith((_) => onSurface),
      dialBackgroundColor: isDarkMode
          ? AppColors.cardDark
          : AppColors.cardLight,
      entryModeIconColor: primary,
    );
  }

  // ========== BUTTON STYLES ==========

  /// Stile standard per i pulsanti dei date/time picker Material
  static ButtonStyle datePickerButtonStyle(Color color, bool isConfirm) =>
      TextButton.styleFrom(
        foregroundColor: color,
        textStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: isConfirm ? FontWeight.w600 : FontWeight.normal,
        ),
      );
}
