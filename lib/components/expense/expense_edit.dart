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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// FILE: expense_edit.dart
/// DESCRIZIONE: Schermata generica per la creazione o la modifica di una spesa.
/// Gestisce l'input dell'utente e funge da "Hub" per il feedback visivo delle operazioni.
/// Centralizza la logica di visualizzazione delle Snackbar (Successo vs Warning)
/// basandosi sullo stato del Provider dopo il tentativo di salvataggio.

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
  }) onSubmit;

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

  // --- COSTRUZIONE UI ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(expenseNotifierProvider.select((p) => p.value?.isLoading ?? false));

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

                inputPrice(isDark),
                inputDescription(),
                SizedBox(height: 20.h),
                inputDate(),
                SizedBox(height: 24.h),
                inputCategory(isDark),
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
      floatingActionButton: (widget.floatingActionButtonIcon == null || isLoading)
          ? null
          : floatingActionButton(context, isDark),
    );
  }

  // --- INPUT PREZZO E VALUTA ---
  Widget inputPrice(bool isDark) {
    final String hintText = _selectedCurrency == ExpenseCurrency.jpy ? "0" : "0.00";
    final textColor = isTappedDown ? AppColors.textLight : AppColors.textTappedDown;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Selettore della valuta (Codice monetario e simbolo)
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
          
          // Campo di input numerico per l'ammontare speso
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: IntrinsicWidth(
                child: TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: textColor,
                  style: TextStyle(
                    fontSize: 50.sp,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    // Normalizzazione automatica della virgola in punto decimale
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
          cursorColor: isTappedDown ? AppColors.textLight : AppColors.textTappedDown,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(
            fontSize: 20.sp,
            color: isTappedDown ? AppColors.textLight : AppColors.textTappedDown,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.descriptionHint,
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.secondaryDark, fontSize: 18.sp),
          ),
        ),
      );

  // --- INPUT DATA ---
  Widget inputDate() {
    final locale = Localizations.localeOf(context).toString();
    final formattedDate = DateFormat("d MMMM y", locale).format(selectedDate);
    final displayDate = capitalizeMonth(formattedDate);

    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            color: isTappedDown ? AppColors.textLight : AppColors.textTappedDown,
            size: 24.sp,
          ),
          SizedBox(width: 10.w),
          Text(
            displayDate,
            style: TextStyle(
              fontSize: 18.sp,
              color: isTappedDown ? AppColors.textLight : AppColors.textTappedDown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- SELETTORE CATEGORIA ---
  /// Renderizza una griglia adattiva di chip per la selezione della categoria merceologica.
  /// Il chip attivo riflette lo stato evidenziandosi con il colore primario del brand.
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
          final label = category.label(loc);

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
                  color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
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
                        ? AppColors.textLight
                        : (isTappedDown ? AppColors.textLight : AppColors.textTappedDown),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.textLight
                          : (isTappedDown ? AppColors.textLight : AppColors.textTappedDown),
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

  // --- GESTIONE ELIMINAZIONE DIRETTATE ---
  Widget floatingActionButton(BuildContext context, bool isDark) {
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
          final deletedExpense = await widget.onFloatingActionButtonPressed!();

          if (!context.mounted) return;

          final currentState = ref.read(expenseNotifierProvider).value ?? ExpenseState();

          // Gestione degli errori derivati dal tentativo di cancellazione
          if (currentState.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(currentState.errorMessage!),
                backgroundColor: AppColors.snackBar,
              ),
            );
            return;
          }

          if (deletedExpense != null) {
            final expenseNotifier = ref.read(expenseNotifierProvider.notifier);
            final locCopy = loc;
            
            SnackbarUtils.show(
              context: context,
              title: loc.deletedTitleSingle,
              message: loc.deleteSuccessMessageSwipe,
              deletedItem: deletedExpense,
              undo: loc.undo,
              navBar: true,
              onDelete: (_) {},
              onRestore: (exp) async {
                await expenseNotifier.restoreExpenses([exp], locCopy);
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

    final currentState = ref.read(expenseNotifierProvider).value ?? ExpenseState();

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
        message: widget.initialValue == null ? loc.expenseCreated : loc.expenseEdited,
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

  // --- UTILITY FORMATTAZIONE ---
  /// Capitalizza forzatamente la prima lettera del mese (es. da "19 maggio 2026" a "19 Maggio 2026")
  /// per mantenere l'uniformità con la visualizzazione standard del resto dell'applicazione.
  String capitalizeMonth(String date) {
    final parts = date.split(' ');
    if (parts.length < 3) return date;
    final day = parts[0];
    final month = parts[1][0].toUpperCase() + parts[1].substring(1);
    final year = parts[2];
    return "$day $month $year";
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