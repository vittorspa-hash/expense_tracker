import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/currency_model.dart';
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
/// Gestisce l'input dell'utente e funge da "Hub" per il feedback visivo delle operazioni.
/// Centralizza la logica di visualizzazione delle Snackbar (Successo vs Warning)
/// basandosi sullo stato del Provider dopo il tentativo di salvataggio.

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
  // Configura i controller e imposta la valuta iniziale.
  // Gestisce anche la visualizzazione "una tantum" del tutorial gestures.
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
  // Layout principale con GestureDetector globale per le interazioni.
  // Sovrappone un indicatore di caricamento quando il Provider è occupato.
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
  // Gestisce l'inserimento dell'importo e la selezione della valuta tramite modale.
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
  // FloatingActionButton per l'eliminazione.
  // Gestisce il flusso completo: Dialog Conferma -> Chiamata Provider -> Snackbar Feedback.
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
          
          // Se c'è un errore bloccante, lo mostriamo e ci fermiamo.
          if (expenseProvider.errorMessage != null){
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
                  currencySymbol,
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
  // Punto cruciale per la gestione del feedback utente.
  // 1. Valida e chiama la funzione di salvataggio (delegata al genitore/provider).
  // 2. Controlla lo stato del Provider per decidere quale Snackbar mostrare:
  //    - ERRORE: Operazione fallita (es. DB rotto). Non chiude la pagina.
  //    - WARNING: "Soft Fail" (es. salvataggio OK ma tassi mancanti). Chiude la pagina.
  //    - SUCCESSO: Operazione completata perfettamente. Chiude la pagina.
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

    // 1. GESTIONE ERRORE BLOCCANTE
    if (expenseProvider.errorMessage != null){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(expenseProvider.errorMessage!),
          backgroundColor: AppColors.snackBar,
        ),
      );
      return; // Stop, l'utente deve poter riprovare
    }

    // 2. GESTIONE WARNING vs SUCCESSO
    // Se c'è un warningMessage (es. tassi non scaricati in creazione o riparazione fallita),
    // mostriamo quello. Altrimenti, successo standard.
    if (expenseProvider.warningMessage != null) {
      SnackbarUtils.show(
        context: context,
        title: loc.warningTitle,
        message: expenseProvider.warningMessage!,
      );
    } 
    else {
      SnackbarUtils.show(
        context: context,
        title: widget.initialValue == null ? loc.createdTitle : loc.editedTitle,
        message: widget.initialValue == null
            ? loc.expenseCreated
            : loc.expenseEdited,
      );
    }
    
    // Chiudiamo la pagina in caso di Successo o Warning
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