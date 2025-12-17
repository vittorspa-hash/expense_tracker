// new_expense_page.dart

import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/components/expense/expense_edit.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
// Aggiunto Provider
import 'package:provider/provider.dart';

class NewExpensePage extends StatefulWidget {
  static const route = "/expense/new";

  const NewExpensePage({super.key});

  @override
  State<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends State<NewExpensePage>
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

  // Funzione chiamata dal widget ExpenseEdit quando si invia la spesa
  void onSubmit({
    required double value,
    required String? description,
    required DateTime date,
  }) {
    // RECUPERO DELLO STORE tramite Provider (usiamo read perché è un'azione)
    context.read<ExpenseProvider>().createExpense(
      value: value,
      description: description,
      date: date,
    );

    // Chiude la pagina e torna alla precedente
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Restituisce il widget ExpenseEdit con il callback onSubmit
    return buildWithFadeAnimation(ExpenseEdit(onSubmit: onSubmit));
  }
}
