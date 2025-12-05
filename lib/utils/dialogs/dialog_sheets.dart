// dialog_sheets.dart
// Questo file contiene funzioni dedicate alla creazione di bottom sheet e
// action sheet adattivi tra iOS e Android. Gestisce:
// - Pulsanti in stile Cupertino e Material
// - Bottom sheet personalizzati
// - Selettore anni adattivo
// Le funzioni sono pure e restituiscono widget pronti all'uso.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dialog_commons.dart';

class DialogSheets {
  // Costruisce un pulsante in stile iOS (CupertinoActionSheetAction)
  // - `returnValue` viene passato al Navigator quando il pulsante viene premuto
  // - Lo stile del testo si adatta al tema scuro/chiaro
  static Widget buildCupertinoSheetButton(
    BuildContext context,
    String text,
    bool isDark,
    String? returnValue,
  ) => CupertinoActionSheetAction(
    isDefaultAction:
        returnValue == null, // evidenziazione del pulsante principale
    onPressed: () => Navigator.pop(context, returnValue),
    child: Text(
      text,
      style: TextStyle(
        color: isDark ? AppColors.textLight : AppColors.textDark,
        fontSize: 17.sp,
      ),
    ),
  );

  // Pulsante in stile Material per bottom sheet Android
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

  // ---------------------------------------------------------------------------
  // 📋 BOTTOM SHEET ADATTIVO
  // ---------------------------------------------------------------------------
  // Mostra un foglio azioni adattivo:
  // - ActionSheet per iOS
  // - BottomSheet Material per Android
  // `options` è una lista di mappe con:
  //   "title": testo da mostrare
  //   "criteria": valore da ritornare al pop
  static Future<String?> showAdaptiveSheet({
    required BuildContext context,
    required String title,
    required bool isDark,
    required List<Map<String, String>> options,
  }) async {
    if (!context.mounted) return null;
    const cancelLabel = 'Annulla';

    // Modal stile iOS
    if (DialogCommons.isIOS) {
      if (!context.mounted) return null;
      return await showCupertinoModalPopup<String>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: DialogCommons.buildSheetTitle(title),
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

    // BottomSheet stile Material
    if (!context.mounted) return null;
    return await showModalBottomSheet<String>(
      context: context,
      shape: DialogCommons.roundedRectangleBorder(),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 22.h),
            DialogCommons.buildSheetTitle(title),
            const Divider(),

            // Lista opzioni
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

  // ---------------------------------------------------------------------------
  // 📅 SELETTORE ANNI ADATTIVO
  // ---------------------------------------------------------------------------
  // Mostra un selettore di anni compatibile con entrambe le piattaforme.
  // `years` contiene la lista completa degli anni selezionabili.
  // `selectedYear` permette di evidenziare l’anno attualmente scelto.
  static Future<String?> showAdaptiveYearPicker({
    required BuildContext context,
    required List<String> years,
    required String selectedYear,
    required bool isDark,
  }) async {
    if (!context.mounted) return null;

    const title = "Seleziona anno";
    const cancelLabel = "Annulla";
    final txtColor = isDark ? AppColors.textLight : AppColors.textDark;

    // Costruisce il widget visuale per ogni anno
    Widget buildYearItem(String year) => Text(
      year,
      style: TextStyle(
        color: txtColor,
        fontWeight: year == selectedYear ? FontWeight.bold : FontWeight.normal,
        fontSize: DialogCommons.isIOS ? 17.sp : 16.sp,
      ),
    );

    // Versione iOS Cupertino
    if (DialogCommons.isIOS) {
      if (!context.mounted) return null;
      return await showCupertinoModalPopup<String>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: DialogCommons.buildSheetTitle(title),
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

    // Versione Android Material
    if (!context.mounted) return null;
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
                child: DialogCommons.buildSheetTitle(title),
              ),

              // Elenco anni con altezza massima per evitare overflow
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final year = years[index];
                    return ListTile(
                      title: Center(child: buildYearItem(year)),
                      onTap: () => Navigator.pop(context, year),
                    );
                  },
                ),
              ),

              Divider(height: 16.h),

              // Pulsante Annulla
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
