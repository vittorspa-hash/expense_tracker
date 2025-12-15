// multi_select_controller.dart
// Controller responsabile della gestione della selezione multipla delle spese.
// Utilizzato nella HomePage e DaysPage per selezionare, deselezionare ed eliminare più voci.
// Funziona tramite GetX per mantenere lo stato reattivo dell'interfaccia.

import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expense_tracker/utils/dialog_utils.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/stores/expense_store.dart';

class MultiSelectController extends GetxController {
  // --- STATO ---
  // Indica se la modalità selezione è attiva
  final RxBool isSelectionMode = false.obs;

  // Insieme degli ID delle spese selezionate
  final RxSet<String> selectedIds = <String>{}.obs;

  // --- ATTIVA SELEZIONE ---
  /// Attiva la modalità selezione al primo long press
  /// e aggiunge la prima spesa selezionata.
  void onLongPress(ExpenseModel expense) {
    isSelectionMode.value = true;
    selectedIds.add(expense.uuid);
  }

  // --- TOGGLE SELEZIONE ---
  /// Aggiunge o rimuove una spesa dall'elenco selezionato.
  /// Se l'ultimo elemento viene deselezionato, la modalità di selezione si disattiva.
  void onToggleSelect(ExpenseModel expense) {
    if (selectedIds.contains(expense.uuid)) {
      selectedIds.remove(expense.uuid);
      if (selectedIds.isEmpty) isSelectionMode.value = false;
    } else {
      selectedIds.add(expense.uuid);
    }
  }

  // --- SELEZIONA TUTTO ---
  /// Seleziona tutte le spese disponibili nella lista fornita.
  /// Utile per selezionare tutte le spese in una volta sola.
  void selectAll(List<ExpenseModel> expenses) {
    for (var expense in expenses) {
      selectedIds.add(expense.uuid);
    }
  }

  // --- DESELEZIONA TUTTO ---
  /// Deseleziona tutte le spese e disattiva la modalità selezione.
  void deselectAll() {
    selectedIds.clear();
    isSelectionMode.value = false;
  }

  // --- ANNULLA SELEZIONE ---
  /// Disattiva la modalità di selezione e svuota l'elenco.
  void cancelSelection() {
    isSelectionMode.value = false;
    selectedIds.clear();
  }

  // --- ELIMINAZIONE MASSIVA ---
  /// Elimina tutte le spese selezionate, previa conferma dell'utente.
  /// Mostra una snackbar che permette anche di annullare l'eliminazione.
  Future<void> deleteSelected(BuildContext context) async {
    final count = selectedIds.length;

    // Conferma eliminazione
    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: "Eliminazione ${count == 1 ? 'singola' : 'multipla'}",
      content:
          "Vuoi eliminare $count ${count == 1 ? 'spesa selezionata' : 'spese selezionate'}?",
      confirmText: "Elimina",
      cancelText: "Annulla",
    );

    // Se annullato → stop
    if (confirm != true) return;

    // Controllo che il contesto sia ancora valido
    if (!context.mounted) return;

    // Recupera le spese selezionate
    final deletedExpenses = expenseStore.value.expenses
        .where((e) => selectedIds.contains(e.uuid))
        .toList();

    // Elimina le spese da StoreModel
    for (var expense in deletedExpenses) {
      expenseStore.value.deleteExpense(expense);
    }

    // Snackbar con supporto al ripristino
    SnackbarUtils.show(
      context: context,
      title: count == 1 ? "Eliminata!" : "Eliminate!",
      message:
          "$count ${count == 1 ? 'spesa eliminata' : 'spese eliminate'} con successo.",
      deletedItem: deletedExpenses,
      // 🔻 Delete immediato (viene eseguito PRIMA dello snackbar)
      onDelete: (_) {
        for (var expense in deletedExpenses) {
          expenseStore.value.deleteExpense(expense);
        }
      },
      // 🔻 Ripristino premendo "Annulla"
      onRestore: (_) {
        for (var expense in deletedExpenses) {
          expenseStore.value.restoreExpense(expense);
        }
      },
    );

    // Pulisce la selezione dopo l'eliminazione
    cancelSelection();
  }
}
