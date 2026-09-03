import 'package:expense_tracker/components/expense/currency_amount_input.dart';
import 'package:expense_tracker/components/expense/delete_expense_fab.dart';
import 'package:expense_tracker/components/expense/expense_category_selector.dart';
import 'package:expense_tracker/components/expense/expense_date_selector.dart';
import 'package:expense_tracker/components/expense/expense_description_input.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/notifiers/expense_notifier.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: expense_edit.dart
/// DESCRIZIONE: Schermata generica per la creazione o la modifica di una spesa.
/// Assembla gli input del form (CurrencyAmountInput, ExpenseDescriptionInput,
/// ExpenseDateSelector, ExpenseCategorySelector) e funge da "Hub" per il
/// feedback visivo delle operazioni, basandosi sullo stato del Provider dopo
/// il tentativo di salvataggio.

class ExpenseEdit extends ConsumerStatefulWidget {
  // --- PARAMETRI ---
  final double? initialValue;
  final String? initialDescription;
  final DateTime? initialDate;
  final String? initialCurrencyCode;
  final ExpenseCategory? initialCategory;

  final Widget? Function(bool isHovered)? headerBuilder;

  final IconData? floatingActionButtonIcon;
  final Future<ExpenseModel?> Function()? onFloatingActionButtonPressed;

  final Future<void> Function({
    required double value,
    required String? description,
    required DateTime date,
    required ExpenseCurrency currencyCode,
    required ExpenseCategory category,
    required AppLocalizations l10n,
  })
  onSubmit;

  const ExpenseEdit({
    super.key,
    this.initialValue,
    this.initialDescription,
    this.initialDate,
    this.initialCurrencyCode,
    this.initialCategory,
    this.headerBuilder,
    this.floatingActionButtonIcon,
    this.onFloatingActionButtonPressed,
    required this.onSubmit,
  });

  @override
  ConsumerState<ExpenseEdit> createState() => _ExpenseEditState();
}

class _ExpenseEditState extends ConsumerState<ExpenseEdit> {
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isTappedDown = false;
  late DateTime selectedDate;
  late ExpenseCurrency _selectedCurrency;
  late ExpenseCategory _selectedCategory;

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
      _selectedCurrency = ref.read(currencyNotifierProvider).currentCurrency;
    }

    // Configurazione iniziale della categoria (Fallback su 'other' se non specificata)
    _selectedCategory = widget.initialCategory ?? ExpenseCategory.other;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionDialogIfNeeded();
    });
  }

  // --- DISPOSE DEI CONTROLLER ---
  @override
  void dispose() {
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // --- COSTRUZIONE UI ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(
      expenseNotifierProvider.select((p) => p.value?.isLoading ?? false),
    );

    final header = widget.headerBuilder?.call(isTappedDown);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.editPageBackgroundDark
          : AppColors.editPageBackgroundLight,
      body: Stack(
        children: [
          // Area interattiva di sfondo per la rimozione del focus dai campi di testo al tap
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
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (header != null) ...[header, SizedBox(height: 20.h)],

                CurrencyAmountInput(
                  controller: priceController,
                  selectedCurrency: _selectedCurrency,
                  isTappedDown: isTappedDown,
                  onCurrencyChanged: (currency) =>
                      setState(() => _selectedCurrency = currency),
                ),
                ExpenseDescriptionInput(
                  controller: descriptionController,
                  isTappedDown: isTappedDown,
                ),
                SizedBox(height: 20.h),
                ExpenseDateSelector(
                  selectedDate: selectedDate,
                  isTappedDown: isTappedDown,
                  onTap: () => _pickDate(context),
                ),
                SizedBox(height: 24.h),
                ExpenseCategorySelector(
                  selectedCategory: _selectedCategory,
                  isTappedDown: isTappedDown,
                  onCategorySelected: (category) =>
                      setState(() => _selectedCategory = category),
                ),
              ],
            ),
          ),

          // Overlay di caricamento bloccante durante le operazioni asincrone
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
          : DeleteExpenseFab(
              icon: widget.floatingActionButtonIcon!,
              onDeletePressed: widget.onFloatingActionButtonPressed!,
            ),
    );
  }

  // --- SALVATAGGIO (ON SUBMIT) ---
  /// Sottomette le modifiche o la nuova istanza validando i vincoli di business logic
  /// (es. impedire il salvataggio di transazioni con valore nullo).
  Future<void> onSubmit() async {
    final loc = AppLocalizations.of(context)!;
    final value = double.tryParse(priceController.text.trim()) ?? 0.0;
    final description = descriptionController.text.trim();

    // Validazione preliminare: l'importo deve essere strettamente positivo
    if (value == 0) {
      SnackbarUtils.show(
        context: context,
        title: loc.errorTitle,
        message: loc.zeroValueError,
        navBar: true,
      );
      return;
    }

    await widget.onSubmit(
      value: value,
      description: description.isEmpty ? null : description,
      date: selectedDate,
      currencyCode: _selectedCurrency,
      category: _selectedCategory,
      l10n: loc,
    );

    if (!mounted) return;

    final currentState =
        ref.read(expenseNotifierProvider).value ?? ExpenseState();

    // 1. GESTIONE ERRORE BLOCCANTE SUL SALVATAGGIO
    if (currentState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentState.errorMessage!),
          backgroundColor: AppColors.snackBar,
        ),
      );
      return;
    }

    // 2. DISPATCH FEEDBACK VISIVO: WARNING (es. Offline) vs SUCCESSO STANDARD
    if (currentState.warningMessage != null) {
      SnackbarUtils.show(
        context: context,
        title: loc.warningTitle,
        message: currentState.warningMessage!,
        navBar: true,
      );
    } else {
      SnackbarUtils.show(
        context: context,
        title: widget.initialValue == null ? loc.createdTitle : loc.editedTitle,
        message: widget.initialValue == null
            ? loc.expenseCreated
            : loc.expenseEdited,
        navBar: true,
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

  // --- ISTRUZIONI UTENTE ONBOARDING ---
  Future<void> _showInstructionDialogIfNeeded() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? "guest";
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
