// dialog_sheets.dart
// Contiene metodi per la visualizzazione di bottom sheet adattivi (Material/Cupertino).
// Gestisce sheet generici per la selezione di opzioni e sheet specifici per la selezione dell'anno.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dialog_commons.dart';

class DialogSheets {
  // Costruisce un pulsante d'azione specifico per il CupertinoActionSheet (iOS style).
  static Widget buildCupertinoSheetButton(
    BuildContext context,
    String text,
    bool isDark,
    String?
    returnValue, // Valore da restituire alla chiusura (es. criterio di ordinamento).
  ) => CupertinoActionSheetAction(
    // Rende il pulsante di default (visivamente evidenziato) se returnValue è null (es. "Annulla").
    isDefaultAction: returnValue == null,
    // Chiude il sheet restituendo il returnValue.
    onPressed: () => Navigator.pop(context, returnValue),
    child: Text(
      text,
      style: TextStyle(
        color: isDark ? AppColors.textLight : AppColors.textDark,
        fontSize: 17.sp,
      ),
    ),
  );

  // Costruisce un pulsante d'azione specifico per il ModalBottomSheet (Material style).
  static Widget buildMaterialSheetButton(
    BuildContext context,
    String text,
    bool isDark,
    String? returnValue,
  ) => TextButton(
    // Chiude il sheet restituendo il returnValue.
    onPressed: () => Navigator.pop(context, returnValue),
    child: Text(
      text,
      style: TextStyle(
        color: isDark ? AppColors.textLight : AppColors.textDark,
        fontSize: 17.sp,
      ),
    ),
  );

  // Mostra un bottom sheet generico adattivo per la selezione di opzioni (es. ordinamento).
  static Future<String?> showAdaptiveSheet({
    required BuildContext context,
    required String title,
    required bool isDark,
    required List<Map<String, String>> options,
  }) async {
    // Verifica se il widget è montato.
    if (!context.mounted) return null;
    const cancelLabel = 'Annulla';

    // Modal stile iOS (CupertinoActionSheet).
    if (DialogCommons.isIOS) {
      if (!context.mounted) return null;
      return await showCupertinoModalPopup<String>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: DialogCommons.buildSheetTitle(title),
          // Mappa le opzioni in CupertinoActionSheetAction.
          actions: options
              .map(
                (opt) => buildCupertinoSheetButton(
                  context,
                  opt["title"] ?? "", // Testo del pulsante.
                  isDark,
                  opt["criteria"], // Valore da restituire (il criterio).
                ),
              )
              .toList(),
          // Pulsante Annulla separato.
          cancelButton: buildCupertinoSheetButton(
            context,
            cancelLabel,
            isDark,
            null, // Annulla restituisce null.
          ),
        ),
      );
    }

    // Modal stile Material (showModalBottomSheet).
    if (!context.mounted) return null;
    return await showModalBottomSheet<String>(
      context: context,
      shape: DialogCommons.roundedRectangleBorder(),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Occupa solo lo spazio necessario.
          children: [
            SizedBox(height: 22.h),
            DialogCommons.buildSheetTitle(title),
            const Divider(),

            // Mappa le opzioni in ListTile per Material.
            ...options.map(
              (opt) => ListTile(
                title: Text(
                  opt["title"] ?? "",
                  style: TextStyle(fontSize: 17.sp),
                ),
                // Al tocco, chiude restituendo il criterio.
                onTap: () => Navigator.pop(context, opt["criteria"]),
              ),
            ),

            const Divider(),
            // Pulsante Annulla per Material.
            buildMaterialSheetButton(context, cancelLabel, isDark, null),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  // Mostra un picker di anno adattivo (usando un sheet per mostrare le opzioni).
  static Future<String?> showAdaptiveYearPicker({
    required BuildContext context,
    required List<String> years,
    required String selectedYear,
    required bool isDark,
  }) async {
    // Verifica se il widget è montato.
    if (!context.mounted) return null;

    const title = "Seleziona anno";
    const cancelLabel = "Annulla";
    final txtColor = isDark ? AppColors.textLight : AppColors.textDark;

    // Costruisce il widget Text per rappresentare un anno nell'elenco.
    Widget buildYearItem(String year) => Text(
      year,
      style: TextStyle(
        color: txtColor,
        // Evidenzia l'anno selezionato.
        fontWeight: year == selectedYear ? FontWeight.bold : FontWeight.normal,
        fontSize: DialogCommons.isIOS ? 17.sp : 16.sp,
      ),
    );

    // Modal stile iOS (CupertinoActionSheet).
    if (DialogCommons.isIOS) {
      if (!context.mounted) return null;
      return await showCupertinoModalPopup<String>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: DialogCommons.buildSheetTitle(title),
          // Mappa gli anni in pulsanti d'azione.
          actions: years
              .map(
                (year) => CupertinoActionSheetAction(
                  // Al tocco, chiude restituendo l'anno.
                  onPressed: () => Navigator.pop(context, year),
                  child: buildYearItem(year),
                ),
              )
              .toList(),
          // Pulsante Annulla.
          cancelButton: buildCupertinoSheetButton(
            context,
            cancelLabel,
            isDark,
            null,
          ),
        ),
      );
    }

    // Modal stile Material (showModalBottomSheet).
    if (!context.mounted) return null;
    return await showModalBottomSheet<String>(
      context: context,
      // Imposta il colore di sfondo del sheet.
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
                child: DialogCommons.buildSheetTitle(title),
              ),

              // Utilizza Flexible e ListView.builder per gestire un elenco potenzialmente lungo di anni.
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true, // Adatta l'altezza al contenuto.
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final year = years[index];
                    return ListTile(
                      title: Center(child: buildYearItem(year)),
                      // Al tocco, chiude restituendo l'anno.
                      onTap: () => Navigator.pop(context, year),
                    );
                  },
                ),
              ),

              Divider(height: 16.h),

              // Pulsante Annulla separato per Material (come ListTile centrato).
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
}
