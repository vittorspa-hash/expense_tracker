import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  static Future<void> handleDeleteSelected(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final multiSelectState = ref.read(multiSelectNotifierProvider);
    final multiSelect = ref.read(multiSelectNotifierProvider.notifier);
    final expenseState = ref.read(expenseNotifierProvider);
    final expense = ref.read(expenseNotifierProvider.notifier);
    final count = multiSelectState.selectedCount;
    final loc = AppLocalizations.of(context)!;

    if (count == 0) return;

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

    final expensesToDelete = expenseState.expenses
        .where((e) => multiSelectState.selectedIds.contains(e.uuid))
        .toList();

    multiSelect.deselectAll();

    await expense.deleteExpenses(expensesToDelete);

    if (!context.mounted) return;

    if (ref.read(expenseNotifierProvider).errorMessage != null) return;

    // Salva loc di nuovo dopo il check mounted, è ancora valido qui
    // perché abbiamo verificato context.mounted appena sopra
    final locAfter = AppLocalizations.of(context)!;

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
        // expense è già salvato prima di qualsiasi await, è sicuro usarlo qui
        await expense.restoreExpenses(expensesToDelete, locAfter);
      },
    );
  }
}
