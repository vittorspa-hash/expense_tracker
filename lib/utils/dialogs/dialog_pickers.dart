// dialog_pickers.dart
// Contiene utility per la costruzione di picker di data e ora adattivi (Material/Cupertino).
// Fornisce metodi per costruire l'header dei picker e per la visualizzazione dei dialoghi di selezione.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dialog_commons.dart';

class DialogPickers {
  // Costruisce l'header standard per i picker modali (utilizzato in stile Cupertino).
  static Widget buildPickerHeader(
    BuildContext context,
    Color txtColor, {
    VoidCallback? onCancel, // Azione specifica per il pulsante Annulla.
    required VoidCallback
    onConfirm, // Azione specifica per il pulsante OK/Conferma.
  }) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Pulsante Annulla
        CupertinoButton(
          padding: EdgeInsets.zero,
          // Se onCancel è fornito, lo usa, altrimenti chiude restituendo null.
          onPressed: onCancel ?? () => Navigator.pop(context, null),
          child: Text(
            "Annulla",
            style: TextStyle(color: txtColor, fontSize: 14.sp),
          ),
        ),
        // Pulsante OK/Conferma
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

  // Costruisce l'header specifico per il DatePicker (usa buildPickerHeader).
  static Widget buildDatePickerHeader(
    BuildContext context,
    Color txtColor,
    DateTime Function()
    getSelectedDate, // Funzione per recuperare la data selezionata.
  ) => buildPickerHeader(
    context,
    txtColor,
    // L'azione di conferma chiude il popup restituendo la data selezionata.
    onConfirm: () => Navigator.pop(context, getSelectedDate()),
  );

  // Mostra un picker di ora adattivo (TimePicker).
  static Future<TimeOfDay?> showTimePickerAdaptive({
    required BuildContext context,
    required TimeOfDay initialTime,
    Color? primaryColor,
    Color? onSurfaceColor,
  }) async {
    // Verifica se il widget è montato.
    if (!context.mounted) return null;

    final isDarkMode = DialogCommons.isDark(context);
    // Imposta i colori predefiniti o utilizza quelli forniti.
    final themePrimary = primaryColor ?? AppColors.primary;
    final themeOnSurface =
        onSurfaceColor ??
        (isDarkMode ? AppColors.textLight : AppColors.textDark);

    // Gestione specifica per iOS (CupertinoDatePicker in modalità time).
    if (DialogCommons.isIOS) {
      if (!context.mounted) return null;

      TimeOfDay picked =
          initialTime; // Variabile per tracciare l'ora selezionata.

      final now = DateTime.now();
      // Converte TimeOfDay in DateTime per inizializzare il CupertinoDatePicker.
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
            // Sfondo adattivo.
            color: isDarkMode
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              // Header con i pulsanti OK e Annulla.
              buildPickerHeader(
                context,
                themeOnSurface,
                // Al tocco di OK, chiude restituendo l'ora tracciata.
                onConfirm: () => Navigator.pop(context, picked),
              ),
              Divider(height: 0, thickness: 1.h),

              // Picker vero e proprio
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  use24hFormat: true,
                  // Aggiorna la variabile 'picked' al cambio di ora.
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

    // Gestione specifica per Android/Material (showTimePicker).
    if (!context.mounted) return null;

    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      // Personalizzazione del tema del TimePicker di Material.
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          // Schema colori personalizzato.
          colorScheme: _buildTimePickerColorScheme(
            isDarkMode,
            themePrimary,
            themeOnSurface,
          ),
          // Tema specifico per il TimePicker.
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

  // Costruisce uno schema di colori (ColorScheme) personalizzato per il TimePicker.
  static ColorScheme _buildTimePickerColorScheme(
    bool isDarkMode,
    Color primary,
    Color onSurface,
  ) {
    return ColorScheme(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: AppColors.textLight, // Testo sul colore primario.
      secondary: primary,
      onSecondary: AppColors.textLight,
      // Colore di superficie (sfondo del dialogo).
      surface: isDarkMode
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      onSurface: onSurface, // Testo sulla superficie.
      error: AppColors.delete,
      onError: AppColors.textLight,
    );
  }

  // Costruisce i dati del tema (TimePickerThemeData) per il TimePicker.
  static TimePickerThemeData _buildTimePickerTheme(
    bool isDarkMode,
    Color primary,
    Color onSurface,
  ) {
    return TimePickerThemeData(
      // Sfondo del TimePicker.
      backgroundColor: isDarkMode
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      // Colore del testo di ore/minuti.
      hourMinuteTextColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors
                  .textLight // Se selezionato, usa testo chiaro.
            : onSurface, // Altrimenti usa colore onSurface.
      ),
      // Colore del testo AM/PM.
      dayPeriodTextColor: WidgetStateColor.resolveWith((_) => onSurface),
      // Sfondo del quadrante dell'orologio.
      dialBackgroundColor: isDarkMode
          ? AppColors.cardDark
          : AppColors.cardLight,
      entryModeIconColor:
          primary, // Colore dell'icona per cambiare modalità (orologio/input).
    );
  }

  // Stile dei pulsanti per il DatePicker di Material.
  static ButtonStyle datePickerButtonStyle(Color color, bool isConfirm) =>
      TextButton.styleFrom(
        foregroundColor: color, // Colore del testo del pulsante.
        textStyle: TextStyle(
          fontSize: 14.sp,
          // Grassetto se è il pulsante di conferma.
          fontWeight: isConfirm ? FontWeight.w600 : FontWeight.normal,
        ),
      );
}
