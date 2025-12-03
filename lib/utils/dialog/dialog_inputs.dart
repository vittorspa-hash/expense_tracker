// dialog_inputs.dart
// Questo file contiene una serie di metodi statici dedicati alla costruzione
// degli input all’interno dei dialog (Cupertino e Material), includendo:
//
// - TextField dinamici con gestione focus, icone e campi password
// - Pulsante "Password dimenticata"
// - Azioni del dialog di conferma (Cupertino/Material)
// - Checkbox interattivo personalizzato

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dialog_commons.dart';

class DialogInputs {
  // ---------------------------------------------------------------------------
  // 🔹 CAMPO DI TESTO GENERICO
  // ---------------------------------------------------------------------------
  // Costruisce un TextField flessibile basato su una mappa "field" che include:
  // - label
  // - hintText
  // - prefixIcon
  // - keyboardType
  // - obscureText (per i campi password)
  // ---------------------------------------------------------------------------
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

          // Gestione spostamento focus
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

            // Icona visibilità password
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

  // ---------------------------------------------------------------------------
  // 🔹 PULSANTE "Password dimenticata?"
  // ---------------------------------------------------------------------------
  static Widget buildForgotPasswordButton(
    VoidCallback onPressed,
    Color txtColor,
  ) =>
      Padding(
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

  // ---------------------------------------------------------------------------
  // 🔹 AZIONI DEL DIALOG (Annulla / Conferma)
  // ---------------------------------------------------------------------------
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

    // -------------------------- iOS -----------------------------------------
    if (isCupertino) {
      return [
        DialogCommons.buildActionButton(context, cancelText, txtColor, null),
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

    // ------------------------- ANDROID --------------------------------------
    return [
      DialogCommons.buildActionButton(context, cancelText, txtColor, null),
      TextButton(
        onPressed: onConfirm,
        child: Text(
          confirmText,
          style: TextStyle(color: txtColor, fontSize: 14.sp),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // 🔹 CHECKBOX PERSONALIZZATO
  // ---------------------------------------------------------------------------
  static Widget buildCheckboxRow(
    StateSetter setState,
    bool value,
    String label,
    Function(bool) onChanged,
  ) =>
      GestureDetector(
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
}
