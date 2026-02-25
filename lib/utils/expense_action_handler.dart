import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/multi_select_provider.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';

/// FILE: expense_action_handler.dart
/// DESCRIZIONE: Helper statico per centralizzare le azioni complesse sulle spese.
/// Gestisce flussi che coinvolgono più provider e interazioni UI (Dialoghi, Snackbar),
/// come l'eliminazione multipla, mantenendo i widget della vista più puliti.

class ExpenseActionHandler {
  
  // --- ELIMINAZIONE BATCH ---
  // Gestisce il flusso completo per l'eliminazione di uno o più elementi selezionati:
  // Dialogo Conferma -> Reset Selezione -> Chiamata al Provider -> Feedback/Undo.
  static Future<void> handleDeleteSelected(BuildContext context) async {
    final multiSelect = context.read<MultiSelectProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final count = multiSelect.selectedCount;
    final loc = AppLocalizations.of(context)!;

    if (count == 0) return;

    // 1. Chiede conferma all'utente prima di procedere con l'azione distruttiva.
    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: count == 1 ? loc.deleteDialogTitleSingle : loc.deleteDialogTitleMultiple,
      content: loc.deleteConfirmMessage(count),
      confirmText: loc.delete,
      cancelText: loc.cancel,
    );

    if (confirm != true) return;

    // 2. Identifica gli oggetti da eliminare basandosi sugli ID selezionati.
    final expensesToDelete = expenseProvider.expenses
        .where((e) => multiSelect.selectedIds.contains(e.uuid))
        .toList();

    // 3. Pulisce la UI uscendo dalla modalità di selezione.
    multiSelect.deselectAll();

    // 4. Esegue la cancellazione effettiva (DB + Stato Locale).
    // Se fallisce, il provider gestirà l'eccezione popolando il campo 'errorMessage'.
    await expenseProvider.deleteExpenses(expensesToDelete);

    if (!context.mounted) return;

    // 5. CHECK ERRORI
    // Verifica se l'operazione ha generato errori. Se sì, interrompe il flusso locale:
    // sarà la vista principale (es. HomePage) a rilevare il cambio di stato e mostrare l'errore.
    if (expenseProvider.errorMessage != null) {
      return; 
    }

    // 6. FEEDBACK & UNDO
    // Se non ci sono errori, mostra una notifica di successo con l'opzione per annullare.
    SnackbarUtils.show(
      context: context,
      title: count == 1 ? loc.deletedTitleSingle : loc.deletedTitleMultiple,
      message: loc.deleteSuccessMessage(count),
      deletedItem: expensesToDelete,
      onDelete: (_) {},
      onRestore: (_) async {
        await expenseProvider.restoreExpenses(expensesToDelete, loc);
      },
    );
  }
}