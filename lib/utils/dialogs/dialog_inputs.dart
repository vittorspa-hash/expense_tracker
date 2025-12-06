// input_dialog_widget.dart
// Implementa uno StatefulWidget per un dialog di input adattivo
// (utilizzando AlertDialog o CupertinoAlertDialog) che gestisce uno o più campi di testo.
// La classe DialogInputs contiene metodi statici per costruire gli elementi interni
// del dialogo (TextFields, pulsanti, azioni).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dialog_commons.dart';

// Widget Stateful che rappresenta il dialogo di input adattivo.
class InputDialogWidget extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>>
  fields; // Lista delle configurazioni dei campi di input.
  final String confirmText;
  final String cancelText;
  final VoidCallback?
  onForgotPassword; // Callback per il pulsante "Password dimenticata?".

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
  // Controller per gestire il testo di ogni campo di input.
  late final List<TextEditingController> _controllers;
  // Notifier per gestire lo stato di oscuramento dei campi (es. password).
  late final List<ValueNotifier<bool>> _obscureStates;
  // FocusNode per la gestione del focus tra i campi.
  late final List<FocusNode> _focusNodes;

  // Ottiene il colore del testo in base al tema corrente.
  Color get _textColor => DialogCommons.textColor(context);

  @override
  void initState() {
    super.initState();

    // Inizializza i controller con i valori iniziali se presenti.
    _controllers = widget.fields
        .map((f) => TextEditingController(text: f["initialValue"] ?? ""))
        .toList();

    // Inizializza gli stati di oscuramento (true se è un campo password).
    _obscureStates = widget.fields
        .map((f) => ValueNotifier<bool>(f["obscureText"] ?? false))
        .toList();

    // Inizializza i FocusNode.
    _focusNodes = List.generate(widget.fields.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    // Rilascia tutte le risorse allocate.
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

  // Costruisce la colonna dei campi di input.
  Widget _buildFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Genera i widget TextField per ogni campo configurato.
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
        // Aggiunge il pulsante "Password dimenticata?" se la callback è fornita.
        if (widget.onForgotPassword != null)
          DialogInputs.buildForgotPasswordButton(
            widget.onForgotPassword!,
            _textColor,
          ),
      ],
    );
  }

  // Costruisce la lista di azioni (pulsanti) per il dialogo.
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
    // Se su iOS, usa CupertinoAlertDialog.
    if (DialogCommons.isIOS) {
      return CupertinoAlertDialog(
        title: Text(widget.title, style: TextStyle(fontSize: 16.sp)),
        content: Padding(
          padding: EdgeInsets.only(top: 8.h),
          // Inserisce Material per assicurare che i TextField abbiano l'aspetto corretto.
          child: Material(color: Colors.transparent, child: _buildFields()),
        ),
        actions: _buildActions(),
      );
    }

    // Se su Material/Android, usa AlertDialog.
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        widget.title,
        style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
      ),
      // Avvolge il contenuto in SingleChildScrollView per evitare overflow della tastiera.
      content: SingleChildScrollView(child: _buildFields()),
      actions: _buildActions(),
    );
  }
}

// Classe statica che gestisce la costruzione degli elementi di input specifici.
class DialogInputs {
  // Costruisce un singolo TextField adattivo con gestione del focus e dell'oscuramento.
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
      // Usa ValueListenableBuilder per reagire al cambio dello stato di oscuramento.
      child: ValueListenableBuilder<bool>(
        valueListenable: obscure,
        builder: (_, hide, _) => TextField(
          controller: controller,
          focusNode: focusNodes[index],
          obscureText: hide,
          keyboardType: field["keyboardType"] ?? TextInputType.text,
          // Imposta l'azione della tastiera (Next o Done).
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          // Gestisce il passaggio del focus al campo successivo o la chiusura della tastiera.
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

            // Icona per la visibilità della password (suffixIcon).
            suffixIcon: hasPassword
                ? IconButton(
                    icon: Icon(
                      hide ? Icons.visibility_off : Icons.visibility,
                      color: txtColor,
                      size: 20.sp,
                    ),
                    // Inverte lo stato di oscuramento al tocco.
                    onPressed: () => obscure.value = !hide,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // Costruisce il pulsante "Password dimenticata?".
  static Widget buildForgotPasswordButton(
    VoidCallback onPressed,
    Color txtColor,
  ) => Padding(
    padding: EdgeInsets.only(top: 8.h),
    child: Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onPressed,
        // Stile per minimizzare padding e dimensioni.
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

  // Costruisce la lista di pulsanti (azioni) in fondo al dialogo.
  static List<Widget> buildDialogActions(
    BuildContext context,
    String cancelText,
    String confirmText,
    List<TextEditingController> controllers,
    Color txtColor,
  ) {
    // Funzione che viene chiamata per confermare: raccoglie tutti i testi e chiude il dialogo.
    void onConfirm() =>
        Navigator.pop(context, controllers.map((c) => c.text).toList());

    // Azioni per iOS (CupertinoDialogAction).
    if (DialogCommons.isIOS) {
      return [
        // Pulsante Annulla (generico).
        DialogCommons.buildActionButton(context, cancelText, txtColor, null),
        // Pulsante Conferma (specifico per Cupertino per impostare isDefaultAction).
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

    // Azioni per Material (TextButton).
    return [
      // Pulsante Annulla (generico).
      DialogCommons.buildActionButton(context, cancelText, txtColor, null),
      // Pulsante Conferma (TextButton).
      TextButton(
        onPressed: onConfirm,
        child: Text(
          confirmText,
          style: TextStyle(color: txtColor, fontSize: 14.sp),
        ),
      ),
    ];
  }

  // Costruisce una riga contenente una checkbox e un'etichetta.
  static Widget buildCheckboxRow(
    StateSetter
    setState, // Usato per aggiornare lo stato del dialogo contenitore.
    bool value,
    String label,
    Function(bool) onChanged,
  ) => GestureDetector(
    // Gestisce il tap su tutta la riga per cambiare lo stato della checkbox.
    onTap: () => setState(() => onChanged(!value)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Checkbox adattiva.
        Checkbox.adaptive(
          value: value,
          // Gestisce il cambio di stato della checkbox.
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
