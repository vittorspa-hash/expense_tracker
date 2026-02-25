import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/currency_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FILE: expense_edit.dart
/// DESCRIZIONE: Schermata generica per la creazione o la modifica di una spesa.
/// Gestisce l'input dell'utente e funge da "Hub" per il feedback visivo delle operazioni.
/// Centralizza la logica di visualizzazione delle Snackbar (Successo vs Warning)
/// basandosi sullo stato del Provider dopo il tentativo di salvataggio.

class ExpenseEdit extends StatefulWidget {
  // --- PARAMETRI ---
  final double? initialValue;
  final String? initialDescription;
  final DateTime? initialDate;
  final String? initialCurrencyCode;
  final ExpenseCategory? initialCategory; // NUOVO

  final Widget? Function(bool isHovered)? headerBuilder;

  final IconData? floatingActionButtonIcon;
  final Future<ExpenseModel?> Function()? onFloatingActionButtonPressed;

  final Future<void> Function({
    required double value,
    required String? description,
    required DateTime date,
    required ExpenseCurrency currencyCode,
    required ExpenseCategory category, // NUOVO
    required AppLocalizations l10n,
  }) onSubmit;

  const ExpenseEdit({
    super.key,
    this.initialValue,
    this.initialDescription,
    this.initialDate,
    this.initialCurrencyCode,
    this.initialCategory, // NUOVO
    this.headerBuilder,
    this.floatingActionButtonIcon,
    this.onFloatingActionButtonPressed,
    required this.onSubmit,
  });

  @override
  State<ExpenseEdit> createState() => _ExpenseEditState();
}

class _ExpenseEditState extends State<ExpenseEdit> {
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isTappedDown = false;
  late DateTime selectedDate;
  late ExpenseCurrency _selectedCurrency;
  late ExpenseCategory _selectedCategory; // NUOVO

  // --- INIZIALIZZAZIONE ---
  @override
  void initState() {
    super.initState();
    priceController.text = widget.initialValue?.toString() ?? "";
    descriptionController.text = widget.initialDescription ?? "";
    selectedDate = widget.initialDate ?? DateTime.now();

    if (widget.initialCurrencyCode != null) {
      _selectedCurrency = ExpenseCurrency.fromCode(widget.initialCurrencyCode!);
    } else {
      _selectedCurrency = context.read<CurrencyProvider>().currentCurrency;
    }

    // Categoria: usa quella passata oppure default a "other"
    _selectedCategory = widget.initialCategory ?? ExpenseCategory.other;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionDialogIfNeeded();
    });
  }

  // --- COSTRUZIONE UI ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = context.select<ExpenseProvider, bool>((p) => p.isLoading);

    final header = widget.headerBuilder?.call(isTappedDown);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.editPageBackgroundDark
          : AppColors.editPageBackgroundLight,

      body: Stack(
        children: [
          InkWell(
            onLongPress: isLoading ? null : onSubmit,
            onHighlightChanged: (highlighted) {
              if (!isLoading) setState(() => isTappedDown = highlighted);
            },
            splashColor: isDark
                ? AppColors.editPageBackgroundDark
                : AppColors.editPageBackgroundLight,
            focusColor: Colors.transparent,
            highlightColor: AppColors.primary,
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (header != null) ...[header, SizedBox(height: 20.h)],

                inputPrice(isDark),
                inputDescription(),
                SizedBox(height: 20.h),
                inputDate(),
                SizedBox(height: 24.h),
                inputCategory(isDark), // NUOVO
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: AppColors.backgroundDark.withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),

      floatingActionButton:
          (widget.floatingActionButtonIcon == null || isLoading)
              ? null
              : floatingActionButton(context, isDark),
    );
  }

  // --- INPUT PREZZO E VALUTA ---
  Widget inputPrice(bool isDark) {
    final String hintText =
        _selectedCurrency == ExpenseCurrency.jpy ? "0" : "0.00";
    final textColor =
        isTappedDown ? AppColors.textLight : AppColors.textTappedDown;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _showCurrencyPicker(isDark),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              color: Colors.transparent,
              child: Text(
                _selectedCurrency.symbol,
                style: TextStyle(
                  fontSize: 50.sp,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: IntrinsicWidth(
                child: TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  cursorColor: textColor,
                  style: TextStyle(
                    fontSize: 50.sp,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text.replaceAll(',', '.');
                      return newValue.copyWith(
                        text: text,
                        selection: newValue.selection,
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: AppColors.secondaryDark,
                      fontSize: 50.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SELETTORE VALUTA ---
  Future<void> _showCurrencyPicker(bool isDark) async {
    final options = ExpenseCurrency.values
        .map((c) => {"title": "${c.name} (${c.symbol})", "criteria": c.code})
        .toList();

    final result = await DialogUtils.showSortSheet(
      context,
      isDark: isDark,
      options: options,
      title: AppLocalizations.of(context)!.selectCurrencyTitle,
    );

    if (result != null) {
      setState(() {
        _selectedCurrency = ExpenseCurrency.fromCode(result);
      });
    }
  }

  // --- INPUT DESCRIZIONE ---
  Widget inputDescription() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: TextField(
          keyboardType: TextInputType.text,
          maxLines: null,
          controller: descriptionController,
          cursorColor: isTappedDown
              ? AppColors.textLight
              : AppColors.textTappedDown,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(
            fontSize: 20.sp,
            color: isTappedDown
                ? AppColors.textLight
                : AppColors.textTappedDown,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.descriptionHint,
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: AppColors.secondaryDark,
              fontSize: 18.sp,
            ),
          ),
        ),
      );

  // --- INPUT DATA ---
  Widget inputDate() {
    final locale = Localizations.localeOf(context).toString();
    final formattedDate =
        DateFormat("d MMMM y", locale).format(selectedDate);
    final displayDate = capitalizeMonth(formattedDate);

    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            color: isTappedDown
                ? AppColors.textLight
                : AppColors.textTappedDown,
            size: 24.sp,
          ),
          SizedBox(width: 10.w),
          Text(
            displayDate,
            style: TextStyle(
              fontSize: 18.sp,
              color: isTappedDown
                  ? AppColors.textLight
                  : AppColors.textTappedDown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- SELETTORE CATEGORIA (NUOVO) ---
  // Mostra una griglia scrollabile di chip per selezionare la categoria.
  // Il chip selezionato è evidenziato con il colore primario dell'app.
  Widget inputCategory(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.w,
        runSpacing: 8.h,
        children: ExpenseCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          final loc = AppLocalizations.of(context)!;

          // Recupera la label localizzata dalla chiave l10n della categoria.
          // Usa un metodo helper per non dipendere da generated code direttamente.
          final label = _localizedCategoryLabel(loc, category);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.07)),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16.sp,
                    color: isSelected
                        ? Colors.white
                        : (isTappedDown
                            ? AppColors.textLight
                            : AppColors.textTappedDown),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isTappedDown
                              ? AppColors.textLight
                              : AppColors.textTappedDown),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- HELPER: LABEL LOCALIZZATA CATEGORIA ---
  // Mappa il labelKey dell'enum alla stringa tradotta corrispondente nel file l10n.
  // Centralizzato qui per non duplicare la logica in più widget.
  String _localizedCategoryLabel(AppLocalizations loc, ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.food:
        return loc.categoryFood;
      case ExpenseCategory.transport:
        return loc.categoryTransport;
      case ExpenseCategory.home:
        return loc.categoryHome;
      case ExpenseCategory.health:
        return loc.categoryHealth;
      case ExpenseCategory.entertainment:
        return loc.categoryEntertainment;
      case ExpenseCategory.shopping:
        return loc.categoryShopping;
      case ExpenseCategory.education:
        return loc.categoryEducation;
      case ExpenseCategory.travel:
        return loc.categoryTravel;
      case ExpenseCategory.other:
        return loc.categoryOther;
    }
  }

  // --- GESTIONE ELIMINAZIONE ---
  Widget floatingActionButton(BuildContext context, bool isDark) {
    final expenseProvider = context.read<ExpenseProvider>();
    final loc = AppLocalizations.of(context)!;

    return FloatingActionButton(
      heroTag: null,
      backgroundColor: AppColors.delete.withValues(alpha: 0.3),
      foregroundColor: AppColors.delete,
      onPressed: () async {
        final confirm = await DialogUtils.showConfirmDialog(
          context,
          title: loc.deleteConfirmTitle,
          content: loc.deleteConfirmMessageSwipe,
          confirmText: loc.delete,
          cancelText: loc.cancel,
        );

        if (confirm == true && widget.onFloatingActionButtonPressed != null) {
          final deletedExpense =
              await widget.onFloatingActionButtonPressed!();

          if (!context.mounted) return;

          if (expenseProvider.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(expenseProvider.errorMessage!),
                backgroundColor: AppColors.snackBar,
              ),
            );
            return;
          }

          if (deletedExpense != null) {
            SnackbarUtils.show(
              context: context,
              title: loc.deletedTitleSingle,
              message: loc.deleteSuccessMessageSwipe,
              deletedItem: deletedExpense,
              onDelete: (_) {},
              onRestore: (exp) async {
                await expenseProvider.restoreExpenses(
                  [exp],
                  loc,
                );
              },
            );
            Navigator.pop(context);
          }
        }
      },
      child: Icon(widget.floatingActionButtonIcon, size: 28.sp),
    );
  }

  // --- SALVATAGGIO (ON SUBMIT) ---
  Future<void> onSubmit() async {
    final loc = AppLocalizations.of(context)!;
    final value = double.tryParse(priceController.text.trim()) ?? 0.0;
    final description = descriptionController.text.trim();

    if (value == 0) {
      SnackbarUtils.show(
        context: context,
        title: loc.errorTitle,
        message: loc.zeroValueError,
      );
      return;
    }

    final expenseProvider = context.read<ExpenseProvider>();

    await widget.onSubmit(
      value: value,
      description: description.isEmpty ? null : description,
      date: selectedDate,
      currencyCode: _selectedCurrency,
      category: _selectedCategory, // NUOVO
      l10n: loc,
    );

    if (!mounted) return;

    // 1. GESTIONE ERRORE BLOCCANTE
    if (expenseProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(expenseProvider.errorMessage!),
          backgroundColor: AppColors.snackBar,
        ),
      );
      return;
    }

    // 2. GESTIONE WARNING vs SUCCESSO
    if (expenseProvider.warningMessage != null) {
      SnackbarUtils.show(
        context: context,
        title: loc.warningTitle,
        message: expenseProvider.warningMessage!,
      );
    } else {
      SnackbarUtils.show(
        context: context,
        title:
            widget.initialValue == null ? loc.createdTitle : loc.editedTitle,
        message: widget.initialValue == null
            ? loc.expenseCreated
            : loc.expenseEdited,
      );
    }

    Navigator.pop(context);
  }

  // --- SELETTORE DATA ---
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await DialogUtils.showDatePickerAdaptive(
      context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (!mounted) return;
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // --- UTILITY FORMATTAZIONE ---
  String capitalizeMonth(String date) {
    final parts = date.split(' ');
    if (parts.length < 3) return date;
    final day = parts[0];
    final month = parts[1][0].toUpperCase() + parts[1].substring(1);
    final year = parts[2];
    return "$day $month $year";
  }

  // --- ISTRUZIONI UTENTE ---
  Future<void> _showInstructionDialogIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "guest";
    final shouldShow = prefs.getBool('showExpenseEditHint_$uid') ?? true;

    if (shouldShow && mounted) {
      final loc = AppLocalizations.of(context)!;
      final dontShowAgain = await DialogUtils.showInstructionDialog(
        context,
        title: loc.expenseInstructionTitle,
        message: loc.expenseInstructionMessage,
      );

      if (dontShowAgain) {
        await prefs.setBool('showExpenseEditHint_$uid', false);
      }
    }
  }
}