// dialog_inputs.dart
// Questo file contiene una serie di metodi statici dedicati alla costruzione
// degli input all'interno dei dialog (Cupertino e Material), includendo:
//
// - TextField dinamici con gestione focus, icone e campi password
// - Pulsante "Password dimenticata"
// - Azioni del dialog di conferma (Cupertino/Material)
// - Checkbox interattivo personalizzato
// - Widget stateful per gestire correttamente il dispose dei controller

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dialog_commons.dart';

// ===========================================================================
// 📝 WIDGET STATEFUL PER INPUT DIALOG
// ===========================================================================
// Questo widget gestisce correttamente il ciclo di vita dei controller,
// focus nodes e value notifier, prevenendo memory leak.
// ===========================================================================

class InputDialogWidget extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> fields;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onForgotPassword;


  const InputDialogWidget({
    super.key,
    required this.title,
    required this.fields,
    required this.confirmText,
    required this.cancelText,
    this.onForgotPassword,
  });

  @override
  State<InputDialogWidget> createState() => _InputDialogWidgetState();
}

class _InputDialogWidgetState extends State<InputDialogWidget> {
  late final List<TextEditingController> _controllers;
  late final List<ValueNotifier<bool>> _obscureStates;
  late final List<FocusNode> _focusNodes;

  Color get _textColor => DialogCommons.textColor(context);

  @override
  void initState() {
    super.initState();

    // Inizializza i controller
    _controllers = widget.fields
        .map((f) => TextEditingController(text: f["initialValue"] ?? ""))
        .toList();

    // Inizializza gli obscure states
    _obscureStates = widget.fields
        .map((f) => ValueNotifier<bool>(f["obscureText"] ?? false))
        .toList();

    // Inizializza i focus nodes
    _focusNodes = List.generate(widget.fields.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    // ✅ PULISCI TUTTO per prevenire memory leak!
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var notifier in _obscureStates) {
      notifier.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Widget _buildFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          widget.fields.length,
          (i) => DialogInputs.buildTextField(
            context,
            widget.fields[i],
            _controllers[i],
            _obscureStates[i],
            _focusNodes,
            i,
            widget.fields.length,
            _textColor,
          ),
        ),
        if (widget.onForgotPassword != null)
          DialogInputs.buildForgotPasswordButton(
            widget.onForgotPassword!,
            _textColor,
          ),
      ],
    );
  }

  List<Widget> _buildActions() {
    return DialogInputs.buildDialogActions(
      context,
      widget.cancelText,
      widget.confirmText,
      _controllers,
      _textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (DialogCommons.isIOS) {
      return CupertinoAlertDialog(
        title: Text(widget.title, style: TextStyle(fontSize: 16.sp)),
        content: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Material(color: Colors.transparent, child: _buildFields()),
        ),
        actions: _buildActions(),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        widget.title,
        style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(child: _buildFields()),
      actions: _buildActions(),
    );
  }
}

// ===========================================================================
// 🛠️ METODI STATICI PER COMPONENTI INPUT
// ===========================================================================

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
                      hide ? Icons.visibility_off : Icons.visibility,
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

  // ---------------------------------------------------------------------------
  // 🔹 AZIONI DEL DIALOG (Annulla / Conferma)
  // ---------------------------------------------------------------------------
  static List<Widget> buildDialogActions(
    BuildContext context,
    String cancelText,
    String confirmText,
    List<TextEditingController> controllers,
    Color txtColor,
  ) {
    void onConfirm() =>
        Navigator.pop(context, controllers.map((c) => c.text).toList());

    // -------------------------- iOS -----------------------------------------
    if (DialogCommons.isIOS) {
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
}
