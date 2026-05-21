import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';

/// FILE: expense_action_handler.dart
/// DESCRIZIONE: Helper statico per centralizzare le azioni complesse sulle spese.
/// Gestisce i flussi operativi che coinvolgono l'interazione coordinata di più provider
/// (multiSelectNotifierProvider ed expenseNotifierProvider) e componenti della UI (Dialog, SnackBar),
/// liberando i widget delle pagine dalla logica di orchestrazione.

class ExpenseActionHandler {
  
  // --- ELIMINAZIONE BATCH E COORDiNAZIONE PROVIDER ---
  
  /// Gestisce il flusso atomico di rimozione di massa delle spese selezionate.
  /// Mostra il prompt di conferma, svuota lo stato di selezione, esegue l'eliminazione 
  /// su Firestore e offre un'azione di "Undo" tramite SnackBar per l'eventuale ripristino.
  static Future<void> handleDeleteSelected(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Recupero dei controller e degli stati correnti dai provider di Riverpod
    final multiSelectState = ref.read(multiSelectNotifierProvider);
    final multiSelect = ref.read(multiSelectNotifierProvider.notifier);
    final expenseState = ref.read(expenseNotifierProvider);
    final expense = ref.read(expenseNotifierProvider.notifier);
    final count = multiSelectState.selectedCount;
    final loc = AppLocalizations.of(context)!;

    // Clausola di salvaguardia se non ci sono elementi marcati per l'eliminazione
    if (count == 0) return;

    // INTERFACCIA: Dialogo di conferma adattivo (singolo o multiplo)
    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: count == 1
          ? loc.deleteDialogTitleSingle
          : loc.deleteDialogTitleMultiple,
      content: loc.deleteConfirmMessage(count),
      confirmText: loc.delete,
      cancelText: loc.cancel,
    );

    if (confirm != true) return;

    // Estrazione delle spese da rimuovere confrontando gli UUID selezionati
    final expensesToDelete = expenseState.expenses
        .where((e) => multiSelectState.selectedIds.contains(e.uuid))
        .toList();

    // Reset immediato della UI di selezione prima dell'operazione asincrona
    multiSelect.deselectAll();

    // Esecuzione della rimozione fisica o logica tramite il notifier delle spese
    await expense.deleteExpenses(expensesToDelete);

    // Controllo di sicurezza per evitare operazioni su contesti non più validi
    if (!context.mounted) return;

    // Interruzione in caso di fallimento registrato nello stato globale delle spese
    if (ref.read(expenseNotifierProvider).errorMessage != null) return;

    final locAfter = AppLocalizations.of(context)!;

    // INTERFACCIA: Feedback finale di successo con opzione di ripristino (Undo)
    SnackbarUtils.show(
      context: context,
      title: count == 1
          ? locAfter.deletedTitleSingle
          : locAfter.deletedTitleMultiple,
      message: locAfter.deleteSuccessMessage(count),
      undo: locAfter.undo,
      deletedItem: expensesToDelete,
      onDelete: (_) {},
      onRestore: (_) async {
        // Invoca l'operazione contraria sul notifier reinserendo il blocco di spese rimosse
        await expense.restoreExpenses(expensesToDelete, locAfter);
      },
    );
  }
}