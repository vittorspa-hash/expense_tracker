import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// FILE: expense_edit.dart
/// DESCRIZIONE: Schermata generica per la creazione o la modifica di una spesa.
/// Gestisce l'input dell'utente (importo, descrizione, data, valuta), la validazione
/// e delega il salvataggio o l'eliminazione tramite callback esterne.

class ExpenseEdit extends StatefulWidget {
  // --- PARAMETRI ---
  final double? initialValue;
  final String? initialDescription;
  final DateTime? initialDate;

  final String? initialCurrencyCode;

  final Widget? Function(bool isHovered)? headerBuilder;

  final IconData? floatingActionButtonIcon;
  final Future<ExpenseModel?> Function()? onFloatingActionButtonPressed;

  final Future<void> Function({
    required double value,
    required String? description,
    required DateTime date,
    required String currencyCode,
    required AppLocalizations l10n,
  })
  onSubmit;

  const ExpenseEdit({
    super.key,
    this.initialValue,
    this.initialDescription,
    this.initialDate,
    this.initialCurrencyCode,
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

  late Currency _selectedCurrency;

  // --- INIZIALIZZAZIONE ---
  // Configura i controller con i valori iniziali (se presenti) o di default.
  // Imposta la valuta iniziale e pianifica il controllo per mostrare
  // il dialog delle istruzioni dopo il rendering del frame.
  @override
  void initState() {
    super.initState();
    priceController.text = widget.initialValue?.toString() ?? "";
    descriptionController.text = widget.initialDescription ?? "";
    selectedDate = widget.initialDate ?? DateTime.now();

    if (widget.initialCurrencyCode != null) {
      _selectedCurrency = Currency.fromCode(widget.initialCurrencyCode!);
    } else {
      _selectedCurrency = context.read<CurrencyProvider>().currentCurrency;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionDialogIfNeeded();
    });
  }

  // --- COSTRUZIONE UI ---
  // Definisce il layout principale. Include un GestureDetector globale (InkWell)
  // per gestire il "Long Press" per il salvataggio rapido e la gestione del focus.
  // Visualizza anche un overlay di caricamento quando necessario.
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
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
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
  // Widget composto che permette di inserire l'importo numerico e selezionare la valuta.
  // Gestisce la formattazione dell'input (virgola/punto) e lo stile del testo.
  Widget inputPrice(bool isDark) {
    final String hintText = _selectedCurrency == Currency.jpy ? "0" : "0.00";
    final textColor = isTappedDown
        ? AppColors.textLight
        : AppColors.textTappedDown;

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
  // Mostra un foglio modale per permettere all'utente di cambiare la valuta della transazione.
  Future<void> _showCurrencyPicker(bool isDark) async {
    final options = Currency.values
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
        _selectedCurrency = Currency.fromCode(result);
      });
    }
  }

  // --- INPUT DESCRIZIONE ---
  // Campo di testo semplice per aggiungere dettagli alla spesa.
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
  // Visualizza la data corrente formattata e apre il date picker al tocco.
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

  // --- GESTIONE ELIMINAZIONE ---
  // Costruisce il FloatingActionButton (solitamente per eliminare la spesa esistente).
  // Gestisce il dialog di conferma e l'eventuale ripristino tramite Snackbar.
  Widget floatingActionButton(BuildContext context, bool isDark) {
    final expenseProvider = context.read<ExpenseProvider>();
    final loc = AppLocalizations.of(context)!;
    final currencySymbol = context.read<CurrencyProvider>().currencySymbol;

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
          if (expenseProvider.errorMessage != null) return;

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
                  currencySymbol,
                );
              },
            );
          }
        }
      },
      child: Icon(widget.floatingActionButtonIcon, size: 28.sp),
    );
  }

  // --- SALVATAGGIO ---
  // Valida i dati (importo non nullo) e chiama la funzione di submit passata come parametro.
  // Fornisce feedback all'utente tramite Snackbar.
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
      currencyCode: _selectedCurrency.code,
      l10n: loc,
    );

    if (!mounted) return;
    if (expenseProvider.errorMessage != null) return;

    SnackbarUtils.show(
      context: context,
      title: widget.initialValue == null ? loc.createdTitle : loc.editedTitle,
      message: widget.initialValue == null
          ? loc.expenseCreated
          : loc.expenseEdited,
    );
  }

  // --- SELETTORE DATA ---
  // Apre il date picker nativo adattivo per selezionare una data passata o odierna.
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
  // Helper per capitalizzare la prima lettera del mese nella stringa della data.
  String capitalizeMonth(String date) {
    final parts = date.split(' ');
    if (parts.length < 3) return date;
    final day = parts[0];
    final month = parts[1][0].toUpperCase() + parts[1].substring(1);
    final year = parts[2];
    return "$day $month $year";
  }

  // --- ISTRUZIONI UTENTE ---
  // Controlla nelle SharedPreferences se è necessario mostrare il tutorial
  // per l'utilizzo della schermata (es. gestures) e lo visualizza una tantum.
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