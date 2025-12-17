// edit_expense_page.dart

import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/components/expense/expense_edit.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
// Aggiunto Provider
import 'package:provider/provider.dart';

class EditExpensePage extends StatefulWidget {
  static const route = "/expense/edit";

  final ExpenseModel expenseModel;

  const EditExpensePage(this.expenseModel, {super.key});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
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

  // Callback chiamato dal widget ExpenseEdit quando si inviano le modifiche
  void onSubmit({
    required double value,
    required String? description,
    required DateTime date,
  }) {
    // Aggiorna la spesa nello store tramite Provider
    context.read<ExpenseProvider>().editExpense(
      widget.expenseModel,
      value: value,
      description: description,
      date: date,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Recuperiamo lo store una volta per usarlo nelle varie callback
    final expense = context.read<ExpenseProvider>();

    return buildWithFadeAnimation(
      ExpenseEdit(
        initialValue: widget.expenseModel.value,
        initialDescription: widget.expenseModel.description,
        initialDate: widget.expenseModel.createdOn,

        floatingActionButtonIcon: Icons.delete,
        onFloatingActionButtonPressed: () {
          // Elimina la spesa tramite store
          expense.deleteExpense(widget.expenseModel);
          Navigator.pop(context);

          // Ritorna il modello al componente ExpenseEdit per permettere l'Undo nella snackbar
          return widget.expenseModel;
        },

        onSubmit: onSubmit,
      ),
    );
  }
}
