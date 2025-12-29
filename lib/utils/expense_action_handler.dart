import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';

/// FILE: expense_action_handler.dart
/// Classe helper per centralizzare le azioni complesse sulle spese
/// che coinvolgono UI (Dialoghi/Snackbar) e Logica (Provider).
class ExpenseActionHandler {
  static Future<void> handleDeleteSelected(BuildContext context) async {
    final multiSelect = context.read<MultiSelectProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final count = multiSelect.selectedCount;

    if (count == 0) return;

    // 1. Dialogo di conferma
    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: "Eliminazione ${count == 1 ? 'singola' : 'multipla'}",
      content:
          "Vuoi eliminare $count ${count == 1 ? 'spesa selezionata' : 'spese selezionate'}?",
      confirmText: "Elimina",
      cancelText: "Annulla",
    );

    if (confirm != true) return;

    // 2. PREPARAZIONE DATI
    // Identifichiamo gli oggetti da eliminare filtrando la lista attuale
    final expensesToDelete = expenseProvider.expenses
        .where((e) => multiSelect.selectedIds.contains(e.uuid))
        .toList();

    // 3. PULIZIA UI
    // Chiudiamo la modalità selezione PRIMA di eliminare per un effetto visivo migliore
    multiSelect.deselectAll();

    // 4. ESECUZIONE (DB + STATE)
    await expenseProvider.deleteExpenses(expensesToDelete);

    // Verifica se il contesto è ancora valido dopo l'await
    if (!context.mounted) return;

    // 5. FEEDBACK E UNDO
    SnackbarUtils.show(
      context: context,
      title: count == 1 ? "Eliminata!" : "Eliminate!",
      message:
          "$count ${count == 1 ? 'spesa eliminata' : 'spese eliminate'} con successo.",
      deletedItem: expensesToDelete,
      onDelete: (_) {},
      // onRestore delegato al provider
      onRestore: (_) async {
        await expenseProvider.restoreExpenses(expensesToDelete);
      },
    );
  }
}