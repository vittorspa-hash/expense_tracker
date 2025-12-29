import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/components/expense/expense_edit.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:provider/provider.dart';

/// FILE: edit_expense_page.dart
/// DESCRIZIONE: Schermata per la modifica di una spesa esistente.
/// Riceve il modello della spesa come parametro, pre-compila i campi del form `ExpenseEdit`
/// e gestisce le operazioni di aggiornamento (Update) ed eliminazione (Delete) tramite il Provider.

class EditExpensePage extends StatefulWidget {
  static const route = "/expense/edit";

  final ExpenseModel expenseModel;

  const EditExpensePage(this.expenseModel, {super.key});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  
  // --- CONFIGURAZIONE ANIMAZIONE ---
  // Setup del mixin per l'effetto fade-in all'ingresso della pagina.
  @override
  TickerProvider get vsync => this;

  @override
  Duration get fadeAnimationDuration => const Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    initFadeAnimation();
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  // --- LOGICA DI AGGIORNAMENTO ---
  // Callback invocata al salvataggio (Long Press).
  // Chiama il metodo `editExpense` del Provider per aggiornare lo stato persistente
  // e chiude la schermata corrente.
  // 
  void onSubmit({
    required double value,
    required String? description,
    required DateTime date,
  }) {
    context.read<ExpenseProvider>().editExpense(
      widget.expenseModel,
      value: value,
      description: description,
      date: date,
    );

    Navigator.pop(context);
  }

  // --- BUILD UI & ELIMINAZIONE ---
  // Costruisce l'interfaccia riutilizzando `ExpenseEdit`.
  // 1. Popola i campi con i dati iniziali (`initialValue`, etc.).
  // 2. Configura il FAB per l'eliminazione della spesa.
  // 
  @override
  Widget build(BuildContext context) {
    final expense = context.read<ExpenseProvider>();

    return buildWithFadeAnimation(
      ExpenseEdit(
        initialValue: widget.expenseModel.value,
        initialDescription: widget.expenseModel.description,
        initialDate: widget.expenseModel.createdOn,

        floatingActionButtonIcon: Icons.delete,
        onFloatingActionButtonPressed: () {
          // Elimina la spesa tramite store
          expense.deleteExpenses([widget.expenseModel]);
          Navigator.pop(context);

          // Ritorna il modello al componente ExpenseEdit per permettere l'Undo nella snackbar
          return widget.expenseModel;
        },

        onSubmit: onSubmit,
      ),
    );
  }
}