part of 'dialog_utils.dart';

// --- IMPLEMENTAZIONI CUPERTINO (iOS) ---
// Tutte le costruzioni di widget/dialog specifiche per lo stile iOS.
// Funzioni private alla libreria: richiamate solo da dialog_utils.dart.

Widget _cupertinoActionButton(
  BuildContext context,
  String text,
  Color color,
  bool? returnValue,
) {
  return CupertinoDialogAction(
    isDefaultAction: returnValue != false,
    isDestructiveAction:
        returnValue == true && DialogUtils.isDestructiveAction(context, text),
    onPressed: () => Navigator.pop(context, returnValue),
    child: Text(text, style: TextStyle(color: color, fontSize: 14.sp)),
  );
}

Widget _cupertinoSheetAction(
  BuildContext context, {
  required String text,
  required VoidCallback onPressed,
  required bool isDark,
  required bool isDestructive,
  required bool isCancel,
}) {
  return CupertinoActionSheetAction(
    isDefaultAction: isCancel,
    isDestructiveAction: isDestructive,
    onPressed: onPressed,
    child: Text(
      text,
      style: TextStyle(
        color: isDestructive
            ? AppColors.delete
            : (isDark ? AppColors.textLight : AppColors.textDark),
        fontSize: 17.sp,
      ),
    ),
  );
}

Future<T?> _cupertinoGenericDialog<T>(
  BuildContext context, {
  required String title,
  required String content,
  required List<Widget> actions,
}) async {
  return await showCupertinoDialog<T>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(title, style: TextStyle(fontSize: 15.sp)),
      content: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Text(content, style: TextStyle(fontSize: 14.sp)),
      ),
      actions: actions,
    ),
  );
}

Future<bool> _cupertinoInstructionDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  required String checkboxLabel,
}) async {
  final textColor = DialogUtils.textColor(context);
  bool dontShowAgain = false;

  await showCupertinoDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => CupertinoAlertDialog(
        title: Text(title, style: TextStyle(fontSize: 15.sp)),
        content: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Material(
            color: Colors.transparent,
            child: _instructionDialogContent(
              message: message,
              checkboxLabel: checkboxLabel,
              dontShowAgain: dontShowAgain,
              onToggle: (val) => setState(() => dontShowAgain = val),
            ),
          ),
        ),
        actions: [_cupertinoActionButton(ctx, confirmText, textColor, null)],
      ),
    ),
  );
  return dontShowAgain;
}

Widget _cupertinoInputDialogChrome(
  BuildContext context, {
  required String title,
  required Widget content,
  required String cancelText,
  required String confirmText,
  required Color textColor,
  required VoidCallback onConfirm,
}) {
  return CupertinoAlertDialog(
    title: Text(title, style: TextStyle(fontSize: 16.sp)),
    content: Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Material(color: Colors.transparent, child: content),
    ),
    actions: [
      DialogUtils.buildActionButton(context, cancelText, textColor, null),
      CupertinoDialogAction(
        isDefaultAction: true,
        onPressed: onConfirm,
        child: Text(confirmText, style: TextStyle(color: textColor, fontSize: 14.sp)),
      ),
    ],
  );
}

Future<String?> _cupertinoSortSheet(
  BuildContext context, {
  required bool isDark,
  required List<Map<String, String>> options,
  required String title,
  required String cancelLabel,
}) async {
  return await showCupertinoModalPopup<String>(
    context: context,
    builder: (_) => CupertinoActionSheet(
      title: DialogUtils.buildSheetTitle(title),
      actions: options.map((opt) {
        return _cupertinoSheetAction(
          context,
          text: opt["title"] ?? "",
          isDark: isDark,
          isDestructive: false,
          isCancel: false,
          onPressed: () => Navigator.pop(context, opt["criteria"]),
        );
      }).toList(),
      cancelButton: _cupertinoSheetAction(
        context,
        text: cancelLabel,
        isDark: isDark,
        isDestructive: false,
        isCancel: true,
        onPressed: () => Navigator.pop(context, null),
      ),
    ),
  );
}

Future<String?> _cupertinoYearPicker(
  BuildContext context, {
  required List<String> years,
  required String selectedYear,
  required bool isDark,
  required String title,
  required String cancelLabel,
}) async {
  final txtColor = DialogUtils.textColor(context);

  Widget buildItem(String year) => Text(
        year,
        style: TextStyle(
          color: txtColor,
          fontWeight: year == selectedYear ? FontWeight.bold : FontWeight.normal,
          fontSize: 17.sp,
        ),
      );

  return await showCupertinoModalPopup<String>(
    context: context,
    builder: (_) => CupertinoActionSheet(
      title: DialogUtils.buildSheetTitle(title),
      actions: years
          .map(
            (year) => CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, year),
              child: buildItem(year),
            ),
          )
          .toList(),
      cancelButton: _cupertinoSheetAction(
        context,
        text: cancelLabel,
        isDark: isDark,
        isDestructive: false,
        isCancel: true,
        onPressed: () => Navigator.pop(context),
      ),
    ),
  );
}

/// Scaffolding condiviso tra i picker iOS (data e ora): stesso Container con
/// altezza fissa, stesso PickerHeader, stesso Divider — cambia solo il
/// CupertinoDatePicker interno (mode diverso). Elimina la duplicazione che
/// c'era tra showDatePickerAdaptive e showTimePickerAdaptive nel file originale.
Future<T?> _cupertinoPickerSheet<T>(
  BuildContext context, {
  required bool isDark,
  required VoidCallback Function(BuildContext ctx) buildOnConfirm,
  required Widget picker,
}) async {
  return await showCupertinoModalPopup<T>(
    context: context,
    builder: (ctx) => Container(
      height: 300.h,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          PickerHeader(
            textColor: DialogUtils.textColor(context),
            onConfirm: buildOnConfirm(ctx),
          ),
          Divider(height: 0, thickness: 1.h),
          Expanded(child: picker),
        ],
      ),
    ),
  );
}

Future<DateTime?> _cupertinoDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime minDate,
  required DateTime maxDate,
  required bool isDark,
}) async {
  DateTime tempPicked = initialDate;
  return await _cupertinoPickerSheet<DateTime>(
    context,
    isDark: isDark,
    buildOnConfirm: (ctx) => () => Navigator.pop(ctx, tempPicked),
    picker: CupertinoDatePicker(
      mode: CupertinoDatePickerMode.date,
      initialDateTime: initialDate,
      minimumDate: minDate,
      maximumDate: maxDate,
      onDateTimeChanged: (val) => tempPicked = val,
    ),
  );
}

Future<TimeOfDay?> _cupertinoTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  required bool isDark,
}) async {
  TimeOfDay picked = initialTime;
  final now = DateTime.now();
  return await _cupertinoPickerSheet<TimeOfDay>(
    context,
    isDark: isDark,
    buildOnConfirm: (ctx) => () => Navigator.pop(ctx, picked),
    picker: CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time,
      initialDateTime: DateTime(
        now.year,
        now.month,
        now.day,
        initialTime.hour,
        initialTime.minute,
      ),
      use24hFormat: true,
      onDateTimeChanged: (val) => picked = TimeOfDay(hour: val.hour, minute: val.minute),
    ),
  );
}

/// Header con Annulla/Conferma per i picker a comparsa iOS (data, ora).
class PickerHeader extends StatelessWidget {
  final Color textColor;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;

  const PickerHeader({
    super.key,
    required this.textColor,
    this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onCancel ?? () => Navigator.pop(context, null),
            child: Text(loc.cancel, style: TextStyle(color: textColor, fontSize: 14.sp)),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onConfirm,
            child: Text(
              loc.ok,
              style: TextStyle(color: textColor, fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}