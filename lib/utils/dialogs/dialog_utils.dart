import 'dart:io';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

part 'dialog_cupertino.dart';
part 'dialog_material.dart';

/// FILE: dialog_utils.dart
/// DESCRIZIONE: Classe di utilità statica per la gestione centralizzata dei dialoghi.
/// Ogni metodo pubblico qui espone l'API unica (showConfirmDialog, showSortSheet,
/// ecc.) e delega l'implementazione concreta alle funzioni private definite in
/// dialog_cupertino.dart (stile iOS) e dialog_material.dart (stile Android),
/// tenute insieme tramite part/part of: i tre file restano un'unica libreria
/// logica, quindi le funzioni "_cupertinoXxx"/"_materialXxx" restano private
/// all'esterno del modulo e nessuna chiamata altrove nel progetto cambia.
///
/// Organizzazione:
/// - dialog_utils.dart: API pubblica + helper/widget condivisi non legati a
///   una piattaforma specifica.
/// - dialog_cupertino.dart: implementazioni e widget specifici per iOS.
/// - dialog_material.dart: implementazioni e widget specifici per Android.

class DialogUtils {
  // --- HELPER CONDIVISI (non legati a una piattaforma specifica) ---

  static bool get isIOS => Platform.isIOS;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textColor(BuildContext context) =>
      isDark(context) ? AppColors.textLight : AppColors.textDark;

  // Euristica per determinare se un'azione è distruttiva (Rosso) basandosi sul testo.
  static bool isDestructiveAction(BuildContext context, String text) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return false;
    final t = text.toLowerCase();
    return t == loc.delete.toLowerCase() || t == loc.logout.toLowerCase();
  }

  /// Titolo standard per i bottom sheet, identico su entrambe le piattaforme.
  static Widget buildSheetTitle(String title) => Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
      );

  /// Pulsante d'azione per i Dialoghi (Alert). Dispatcha alla variante
  /// per-piattaforma: iOS (CupertinoDialogAction) o Android (TextButton).
  static Widget buildActionButton(
    BuildContext context,
    String text,
    Color color, [
    bool? returnValue,
  ]) {
    return isIOS
        ? _cupertinoActionButton(context, text, color, returnValue)
        : _materialActionButton(context, text, color, returnValue);
  }

  /// Pulsante d'azione per i Bottom Sheet. Dispatcha alla variante per-piattaforma.
  static Widget buildSheetAction(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    required bool isDark,
    bool isDestructive = false,
    bool isCancel = false,
  }) {
    return isIOS
        ? _cupertinoSheetAction(
            context,
            text: text,
            onPressed: onPressed,
            isDark: isDark,
            isDestructive: isDestructive,
            isCancel: isCancel,
          )
        : _materialSheetAction(
            text: text,
            onPressed: onPressed,
            isDark: isDark,
            isDestructive: isDestructive,
          );
  }

  // --- DIALOGHI DI BASE ---

  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    if (!context.mounted) return;
    final loc = AppLocalizations.of(context)!;

    await _showGenericDialog(
      context: context,
      title: title,
      content: content,
      actions: (ctx, color) => [buildActionButton(ctx, loc.ok, color)],
    );
  }

  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
  }) async {
    if (!context.mounted) return false;
    final loc = AppLocalizations.of(context)!;

    final effectiveConfirmText = confirmText ?? loc.confirm;
    final effectiveCancelText = cancelText ?? loc.cancel;

    final destructive = isDestructiveAction(context, effectiveConfirmText);
    final color = textColor(context);
    final confirmColor = destructive ? AppColors.delete : color;

    return await _showGenericDialog<bool>(
      context: context,
      title: title,
      content: content,
      actions: (ctx, _) => [
        buildActionButton(ctx, effectiveCancelText, color, false),
        buildActionButton(ctx, effectiveConfirmText, confirmColor, true),
      ],
    );
  }

  // Mostra un dialogo con una checkbox di stato (es. "Non mostrare più").
  static Future<bool> showInstructionDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? checkboxLabel,
  }) async {
    if (!context.mounted) return false;
    final loc = AppLocalizations.of(context)!;
    final effectiveConfirmText = confirmText ?? loc.ok;
    final effectiveCheckboxLabel = checkboxLabel ?? loc.dontShowAgain;

    return isIOS
        ? await _cupertinoInstructionDialog(
            context,
            title: title,
            message: message,
            confirmText: effectiveConfirmText,
            checkboxLabel: effectiveCheckboxLabel,
          )
        : await _materialInstructionDialog(
            context,
            title: title,
            message: message,
            confirmText: effectiveConfirmText,
            checkboxLabel: effectiveCheckboxLabel,
          );
  }

  // --- DIALOGHI DI INPUT ---

  static Future<List<String>?> showInputDialogAdaptive(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> fields,
    String? confirmText,
    String? cancelText,
    VoidCallback? onForgotPassword,
  }) async {
    if (!context.mounted) return null;
    final loc = AppLocalizations.of(context)!;

    final widget = InputDialogWidget(
      title: title,
      fields: fields,
      confirmText: confirmText ?? loc.save,
      cancelText: cancelText ?? loc.cancel,
      onForgotPassword: onForgotPassword,
    );

    if (isIOS) {
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

  static Future<String?> showSortSheet(
    BuildContext context, {
    required bool isDark,
    required List<Map<String, String>> options,
    required String title,
  }) async {
    if (!context.mounted) return null;
    final loc = AppLocalizations.of(context)!;
    final cancelLabel = loc.cancel;

    return isIOS
        ? await _cupertinoSortSheet(
            context,
            isDark: isDark,
            options: options,
            title: title,
            cancelLabel: cancelLabel,
          )
        : await _materialSortSheet(
            context,
            isDark: isDark,
            options: options,
            title: title,
            cancelLabel: cancelLabel,
          );
  }

  // --- DATE & TIME PICKERS ---

  static Future<DateTime?> showDatePickerAdaptive(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    if (!context.mounted) return null;
    final dark = isDark(context);
    final minDate = firstDate ?? DateTime(2000);
    final maxDate = lastDate ?? DateTime.now();

    return isIOS
        ? await _cupertinoDatePicker(
            context,
            initialDate: initialDate,
            minDate: minDate,
            maxDate: maxDate,
            isDark: dark,
          )
        : await _materialDatePicker(
            context,
            initialDate: initialDate,
            minDate: minDate,
            maxDate: maxDate,
            isDark: dark,
          );
  }

  static Future<TimeOfDay?> showTimePickerAdaptive(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) async {
    if (!context.mounted) return null;
    final dark = isDark(context);

    return isIOS
        ? await _cupertinoTimePicker(context, initialTime: initialTime, isDark: dark)
        : await _materialTimePicker(context, initialTime: initialTime, isDark: dark);
  }

  static Future<String?> showYearPickerAdaptive(
    BuildContext context, {
    required List<String> years,
    required String selectedYear,
  }) async {
    if (!context.mounted) return null;
    final dark = isDark(context);
    final loc = AppLocalizations.of(context)!;

    return isIOS
        ? await _cupertinoYearPicker(
            context,
            years: years,
            selectedYear: selectedYear,
            isDark: dark,
            title: loc.selectYear,
            cancelLabel: loc.cancel,
          )
        : await _materialYearPicker(
            context,
            years: years,
            selectedYear: selectedYear,
            isDark: dark,
            title: loc.selectYear,
            cancelLabel: loc.cancel,
          );
  }

  // --- PRIVATE DISPATCH: DIALOGO GENERICO (Info/Confirm) ---

  static Future<T?> _showGenericDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    required List<Widget> Function(BuildContext, Color) actions,
  }) async {
    final color = textColor(context);
    return isIOS
        ? await _cupertinoGenericDialog<T>(
            context,
            title: title,
            content: content,
            actions: actions(context, color),
          )
        : await _materialGenericDialog<T>(
            context,
            title: title,
            content: content,
            actions: actions(context, color),
          );
  }
}

// --- WIDGET CONDIVISI (platform-agnostic) ---

/// Riga con checkbox adattiva (Checkbox.adaptive gestisce da sola lo stile
/// per piattaforma), usata identica da entrambe le varianti di showInstructionDialog.
class DialogCheckboxRow extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const DialogCheckboxRow({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Checkbox.adaptive(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          SizedBox(width: 6.w),
          Flexible(child: Text(label, style: TextStyle(fontSize: 13.sp))),
        ],
      ),
    );
  }
}

/// Contenuto condiviso (testo + checkbox) di showInstructionDialog, identico
/// su entrambe le piattaforme: solo il "contenitore" del dialog differisce.
Widget _instructionDialogContent({
  required String message,
  required String checkboxLabel,
  required bool dontShowAgain,
  required ValueChanged<bool> onToggle,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        message,
        style: TextStyle(fontSize: DialogUtils.isIOS ? 13.sp : 14.sp),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 16.h),
      DialogCheckboxRow(value: dontShowAgain, label: checkboxLabel, onChanged: onToggle),
    ],
  );
}

// --- INPUT DIALOG WIDGET (stato condiviso, chrome per-piattaforma) ---

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

  Color get _textColor => DialogUtils.textColor(context);

  @override
  void initState() {
    super.initState();
    _controllers = widget.fields
        .map((f) => TextEditingController(text: f["initialValue"] ?? ""))
        .toList();
    _obscureStates = widget.fields
        .map((f) => ValueNotifier<bool>(f["obscureText"] ?? false))
        .toList();
    _focusNodes = List.generate(widget.fields.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _obscureStates) {
      n.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onConfirm() {
    Navigator.pop(context, _controllers.map((c) => c.text).toList());
  }

  Widget _buildTextField(int index) {
    final field = widget.fields[index];
    final isLast = index == widget.fields.length - 1;
    final hasPassword = field["obscureText"] == true;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: ValueListenableBuilder<bool>(
        valueListenable: _obscureStates[index],
        builder: (_, hide, _) => Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              selectionHandleColor: AppColors.primary,
            ),
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            cursorColor: AppColors.primary,
            obscureText: hide,
            keyboardType: field["keyboardType"] ?? TextInputType.text,
            textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
            onSubmitted: (_) {
              final scope = FocusScope.of(context);
              isLast ? scope.unfocus() : scope.requestFocus(_focusNodes[index + 1]);
            },
            style: TextStyle(fontSize: 15.sp),
            decoration: InputDecoration(
              labelText: field["label"],
              floatingLabelStyle: TextStyle(color: _textColor),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
              prefixIcon: field["prefixIcon"] != null
                  ? Icon(field["prefixIcon"], size: 20.sp)
                  : null,
              hintText: field["hintText"],
              hintStyle: TextStyle(fontSize: 14.sp),
              suffixIcon: hasPassword
                  ? IconButton(
                      icon: Icon(
                        hide ? Icons.visibility_off : Icons.visibility,
                        color: _textColor,
                        size: 20.sp,
                      ),
                      onPressed: () => _obscureStates[index].value = !hide,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: widget.onForgotPassword,
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(0, 30.h)),
          child: Text(
            loc.forgotPassword,
            style: TextStyle(
              color: _textColor,
              fontSize: 13.sp,
              decoration: TextDecoration.underline,
              decorationColor: _textColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(widget.fields.length, _buildTextField),
        if (widget.onForgotPassword != null) _buildForgotPassword(),
      ],
    );

    return DialogUtils.isIOS
        ? _cupertinoInputDialogChrome(
            context,
            title: widget.title,
            content: content,
            cancelText: widget.cancelText,
            confirmText: widget.confirmText,
            textColor: _textColor,
            onConfirm: _onConfirm,
          )
        : _materialInputDialogChrome(
            context,
            title: widget.title,
            content: content,
            cancelText: widget.cancelText,
            confirmText: widget.confirmText,
            textColor: _textColor,
            onConfirm: _onConfirm,
          );
  }
}