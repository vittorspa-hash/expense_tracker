//new_expense_page.dart
// Pagina per la creazione di una nuova spesa.
// Utilizza il widget ExpenseEdit per gestire input di importo, descrizione e data.
// Alla conferma, la spesa viene salvata nello store e si torna alla pagina precedente.

import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/components/expense/expense_edit.dart';
import 'package:expense_tracker/stores/expense_store.dart';

class NewExpensePage extends StatefulWidget {
  static const route = "/expense/new";

  const NewExpensePage({super.key});

  @override
  State<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends State<NewExpensePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  // Getter per il vsync richiesto dal mixin
  @override
  TickerProvider get vsync => this;

  // Durata dell'animazione fade-in sovrascritta
  @override
  Duration get fadeAnimationDuration => const Duration(milliseconds: 400);

  // Inizializza l'animazione fade-in
  @override
  void initState() {
    super.initState();
    initFadeAnimation();
  }

  // Rilascia le risorse dell'animazione
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
    // Creazione della nuova spesa nello store
    expenseStore.value.createExpense(
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
