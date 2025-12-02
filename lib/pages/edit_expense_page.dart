// edit_expense_page.dart
// Pagina per la modifica di una spesa esistente.
// Mostra il widget ExpenseEdit con i valori iniziali della spesa.
// Permette di modificare importo, descrizione e data.
// Include un pulsante per eliminare la spesa.

import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/components/expense/expense_edit.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/stores/expense_store.dart';

class EditExpensePage extends StatefulWidget {
  static const route = "/expense/edit";

  // La spesa da modificare
  final ExpenseModel expenseModel;

  const EditExpensePage(this.expenseModel, {super.key});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage>
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

  // Callback chiamato dal widget ExpenseEdit quando si inviano le modifiche
  void onSubmit({
    required double value,
    required String? description,
    required DateTime date,
  }) {
    // Aggiorna la spesa nello store
    expenseStore.value.editExpense(
      widget.expenseModel,
      value: value,
      description: description,
      date: date,
    );

    // Torna alla pagina precedente
    Navigator.pop(context);
  }

  // Funzione chiamata quando si preme il pulsante di eliminazione
  void onDelete() {
    // Elimina la spesa dallo store
    expenseStore.value.deleteExpense(widget.expenseModel);

    // Torna alla pagina precedente
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return buildWithFadeAnimation(
      ExpenseEdit(
        // Valori iniziali della spesa da modificare
        initialValue: widget.expenseModel.value,
        initialDescription: widget.expenseModel.description,
        initialDate: widget.expenseModel.createdOn,

        // Pulsante flottante per eliminare la spesa
        floatingActionButtonIcon: Icons.delete,
        onFloatingActionButtonPressed: () {
          // Rimuove la spesa e la ritorna per la snackbar
          expenseStore.value.deleteExpense(widget.expenseModel);
          Navigator.pop(context);
          return widget.expenseModel;
        },

        // Callback per salvare le modifiche
        onSubmit: onSubmit,
      ),
    );
  }
}
