import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// FILE: expense_edit.dart
/// DESCRIZIONE: Widget riutilizzabile per la creazione e la modifica di una spesa.
/// Gestisce l'input dell'importo, della descrizione e della data.
/// Caratteristica peculiare: utilizza un'interazione "Long Press" (pressione prolungata)
/// sullo sfondo per confermare e salvare i dati, invece di un classico bottone "Salva".

class ExpenseEdit extends StatefulWidget {
  final double? initialValue;
  final String? initialDescription;
  final DateTime? initialDate;
  final IconData? floatingActionButtonIcon;
  final ExpenseModel? Function()? onFloatingActionButtonPressed;
  final void Function({
    required double value,
    required String? description,
    required DateTime date,
  })
  onSubmit;

  const ExpenseEdit({
    super.key,
    this.initialValue,
    this.initialDescription,
    this.initialDate,
    this.floatingActionButtonIcon,
    this.onFloatingActionButtonPressed,
    required this.onSubmit,
  });

  @override
  State<ExpenseEdit> createState() => _ExpenseEditState();
}

class _ExpenseEditState extends State<ExpenseEdit> {
  // --- STATO E INIZIALIZZAZIONE ---
  // Controller per i campi di testo e variabili per gestire lo stato visivo
  // (es. cambio colore alla pressione) e i dati temporanei (data selezionata).
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isTappedDown = false;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    // Pre-popolamento dati in caso di modifica
    priceController.text = widget.initialValue?.toString() ?? "";
    descriptionController.text = widget.initialDescription ?? "";
    selectedDate = widget.initialDate ?? DateTime.now();

    // Controllo tutorial "Long Press" al primo avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionDialogIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- UI PRINCIPALE ---
    // Struttura a tutto schermo sensibile al tocco.
    // L'InkWell gestisce il "Long Press" per il submit e cambia colore (highlight)
    // per dare feedback visivo all'utente mentre preme.
    // 
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.editPageBackgroundDark
          : AppColors.editPageBackgroundLight,
      body: InkWell(
        onLongPress: onSubmit,
        onHighlightChanged: (highlighted) =>
            setState(() => isTappedDown = highlighted),
        splashColor: isDark
            ? AppColors.editPageBackgroundDark
            : AppColors.editPageBackgroundLight,
        focusColor: Colors.transparent,
        highlightColor: AppColors.primary,
        onTap: () {
          // Chiude la tastiera se si tocca fuori dai campi
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            inputPrice(),
            inputDescription(),
            SizedBox(height: 20.h),
            inputDate(),
          ],
        ),
      ),
      // FAB opzionale (usato principalmente per eliminare la spesa in fase di edit)
      floatingActionButton: widget.floatingActionButtonIcon == null
          ? null
          : floatingActionButton(context, isDark), 
    );
  }

  // --- COMPONENTI DI INPUT ---
  // Widget modulari per l'inserimento di Prezzo (Text), Descrizione (Text) e Data (Picker).
  // I colori del testo cambiano dinamicamente se l'utente sta premendo lo sfondo (isTappedDown).
  // 
  Widget inputPrice() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 24.w),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "€",
          style: TextStyle(
            fontSize: 50.sp,
            color: isTappedDown
                ? AppColors.textLight
                : AppColors.textTappedDown,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 20.w),
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
                cursorColor: isTappedDown
                    ? AppColors.textLight
                    : AppColors.textTappedDown,
                style: TextStyle(
                  fontSize: 50.sp,
                  color: isTappedDown
                      ? AppColors.textLight
                      : AppColors.textTappedDown,
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
                  hintText: "0.00",
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: AppColors.textEditPage,
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
        hintText: "Descrizione (opzionale)",
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.textEditPage, fontSize: 18.sp),
      ),
    ),
  );

  Widget inputDate() {
    final formattedDate = DateFormat("d MMMM y", "it_IT").format(selectedDate);
    final displayDate = capitalizeMonth(formattedDate);

    // 
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

  // --- AZIONI SUPPLEMENTARI (DELETE) ---
  // Bottone flottante per gestire l'eliminazione della spesa (se presente).
  // Include logica di conferma e feedback undo tramite SnackBar.
  Widget floatingActionButton(BuildContext context, bool isDark) {
    // Recuperiamo lo store tramite context.read (essendo un'azione non serve watch)
    final expense = context.read<ExpenseProvider>();

    return FloatingActionButton(
      heroTag: null,
      backgroundColor: AppColors.delete.withValues(alpha: 0.3),
      foregroundColor: AppColors.delete,
      onPressed: () async {
        final confirm = await DialogUtils.showConfirmDialog(
          context,
          title: "Conferma eliminazione",
          content: "Vuoi eliminare la spesa selezionata?",
          confirmText: "Elimina",
          cancelText: "Annulla",
        );

        if (confirm == true) {
          if (widget.onFloatingActionButtonPressed != null) {
            final deletedExpense = await Future.sync(
              () => widget.onFloatingActionButtonPressed!(),
            );

            if (!context.mounted) return;

            if (deletedExpense != null) {
              SnackbarUtils.show(
                context: context,
                title: "Eliminata!",
                message: "Spesa eliminata con successo.",
                deletedItem: deletedExpense,
                // Chiamate allo store tramite l'istanza ottenuta con Provider
                onDelete: (exp) => expense.deleteExpense(exp),
                onRestore: (exp) => expense.restoreExpense(exp),
              );
            }
          }
        }
      },
      child: Icon(widget.floatingActionButtonIcon, size: 28.sp),
    );
  }

  // --- LOGICA DI SALVATAGGIO E UTILITY ---
  // Validazione input, esecuzione del submit tramite callback padre,
  // apertura del date picker e gestione del tutorial iniziale.
  void onSubmit() {
    final value = double.tryParse(priceController.text.trim()) ?? 0.0;
    final description = descriptionController.text.trim();

    if (value == 0) {
      SnackbarUtils.show(
        context: context,
        title: "Nope!",
        message: "Non puoi creare una spesa con un valore uguale a 0.",
      );
      return;
    }

    widget.onSubmit(
      value: value,
      description: description.isEmpty ? null : description,
      date: selectedDate,
    );

    SnackbarUtils.show(
      context: context,
      title: widget.initialValue == null ? "Creata!" : "Modificata!",
      message: widget.initialValue == null
          ? "Spesa creata con successo."
          : "Spesa modificata con successo.",
    );
  }

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

  String capitalizeMonth(String date) {
    final parts = date.split(' ');
    if (parts.length < 3) return date;
    final day = parts[0];
    final month = parts[1][0].toUpperCase() + parts[1].substring(1);
    final year = parts[2];
    return "$day $month $year";
  }

  Future<void> _showInstructionDialogIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "guest";
    final shouldShow = prefs.getBool('showExpenseEditHint_$uid') ?? true;

    if (shouldShow && mounted) {
      final dontShowAgain = await DialogUtils.showInstructionDialog(
        context,
        title: "Creazione o modifica di una spesa",
        message:
            "Per confermare la creazione o la modifica di una spesa, tieni premuto sullo schermo.",
      );

      if (dontShowAgain) {
        await prefs.setBool('showExpenseEditHint_$uid', false);
      }
    }
  }
}