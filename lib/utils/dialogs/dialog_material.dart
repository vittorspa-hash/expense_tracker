part of 'dialog_utils.dart';

// --- IMPLEMENTAZIONI MATERIAL (Android) ---
// Tutte le costruzioni di widget/dialog specifiche per lo stile Material.
// Funzioni private alla libreria: richiamate solo da dialog_utils.dart.

RoundedRectangleBorder _materialRoundedRectangleBorder() =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r));

/// Helper centralizzato per i pulsanti di azione dei dialoghi Material.
/// Gestisce sia la chiusura diretta con valore (Navigator.pop) che callback personalizzate.
Widget _materialActionButton(
  BuildContext context,
  String text,
  Color color, [
  bool? returnValue,
  VoidCallback? onPressed,
]) {
  return TextButton(
    style: TextButton.styleFrom(
      foregroundColor: color,
      overlayColor: color.withValues(alpha: 0.12),
    ),
    onPressed: onPressed ?? () => Navigator.pop(context, returnValue),
    child: Text(text, style: TextStyle(fontSize: 14.sp)),
  );
}

/// Helper centralizzato per i pulsanti nei Bottom Sheet.
Widget _materialSheetAction({
  required String text,
  required VoidCallback onPressed,
  required bool isDark,
  required bool isDestructive,
}) {
  final color = isDestructive
      ? AppColors.delete
      : (isDark ? AppColors.textLight : AppColors.textDark);

  return TextButton(
    style: TextButton.styleFrom(
      foregroundColor: color,
      overlayColor: color.withValues(alpha: 0.12),
    ),
    onPressed: onPressed,
    child: Text(
      text,
      style: TextStyle(fontSize: 17.sp),
    ),
  );
}

Future<T?> _materialGenericDialog<T>(
  BuildContext context, {
  required String title,
  required String content,
  required List<Widget> actions,
}) async {
  return await showDialog<T>(
    context: context,
    builder: (_) => AlertDialog(
      shape: _materialRoundedRectangleBorder(),
      title: Text(title, style: TextStyle(fontSize: 15.sp)),
      content: Text(content, style: TextStyle(fontSize: 14.sp)),
      actions: actions,
    ),
  );
}

Future<bool> _materialInstructionDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  required String checkboxLabel,
}) async {
  final textColor = DialogUtils.textColor(context);
  bool dontShowAgain = false;

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: _materialRoundedRectangleBorder(),
        title: Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        content: _instructionDialogContent(
          message: message,
          checkboxLabel: checkboxLabel,
          dontShowAgain: dontShowAgain,
          onToggle: (val) => setState(() => dontShowAgain = val),
        ),
        actions: [_materialActionButton(ctx, confirmText, textColor, null)],
      ),
    ),
  );
  return dontShowAgain;
}

Widget _materialInputDialogChrome(
  BuildContext context, {
  required String title,
  required Widget content,
  required String cancelText,
  required String confirmText,
  required Color textColor,
  required VoidCallback onConfirm,
}) {
  return AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
    title: Text(title, style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: content),
    actions: [
      DialogUtils.buildActionButton(context, cancelText, textColor, null),
      _materialActionButton(context, confirmText, textColor, null, onConfirm),
    ],
  );
}

Future<String?> _materialSortSheet(
  BuildContext context, {
  required bool isDark,
  required List<Map<String, String>> options,
  required String title,
  required String cancelLabel,
}) async {

  return await showModalBottomSheet<String>(
    context: context,
    shape: _materialRoundedRectangleBorder(),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 22.h),
          DialogUtils.buildSheetTitle(title),
          const Divider(),
          ...options.map(
            (opt) => ListTile(
              title: Text(opt["title"] ?? "", style: TextStyle(fontSize: 17.sp)),
              onTap: () => Navigator.pop(context, opt["criteria"]),
            ),
          ),
          const Divider(),
          _materialSheetAction(
            text: cancelLabel,
            onPressed: () => Navigator.pop(context, null),
            isDark: isDark,
            isDestructive: false,
          ),
          SizedBox(height: 8.h),
        ],
      ),
    ),
  );
}

Future<String?> _materialYearPicker(
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
          fontSize: 16.sp,
        ),
      );

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
              child: DialogUtils.buildSheetTitle(title),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: years.length,
                itemBuilder: (ctx, i) => ListTile(
                  splashColor: txtColor.withValues(alpha: 0.12),
                  title: Center(child: buildItem(years[i])),
                  onTap: () => Navigator.pop(context, years[i]),
                ),
              ),
            ),
            Divider(height: 16.h),
            _materialSheetAction(
              text: cancelLabel,
              onPressed: () => Navigator.pop(context, null),
              isDark: isDark,
              isDestructive: false,
            ),
          ],
        ),
      ),
    ),
  );
}

Future<DateTime?> _materialDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime minDate,
  required DateTime maxDate,
  required bool isDark,
}) async {
  final btnColor = isDark ? AppColors.textLight : AppColors.textDark;

  return await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: minDate,
    lastDate: maxDate,
    builder: (context, child) {
      final theme = Theme.of(context);
      return Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(primary: AppColors.primary),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: btnColor,
              overlayColor: btnColor.withValues(alpha: 0.12),
            ),
          ),
          datePickerTheme: DatePickerThemeData(shape: _materialRoundedRectangleBorder()),
        ),
        child: child!,
      );
    },
  );
}

ColorScheme _materialTimePickerColorScheme(bool dark) => ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textLight,
      secondary: AppColors.primary,
      onSecondary: AppColors.textLight,
      surface: dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      onSurface: dark ? AppColors.textLight : AppColors.textDark,
      error: AppColors.delete,
      onError: AppColors.textLight,
    );

Future<TimeOfDay?> _materialTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  required bool isDark,
}) async {
  final btnColor = isDark ? AppColors.textLight : AppColors.textDark;

  return await showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: _materialTimePickerColorScheme(isDark),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: btnColor,
            overlayColor: btnColor.withValues(alpha: 0.12),
          ),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          dialBackgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          entryModeIconColor: AppColors.primary,
        ),
      ),
      child: child!,
    ),
  );
}