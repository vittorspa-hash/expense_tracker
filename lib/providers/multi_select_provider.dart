// multi_select_provider.dart
// Provider responsabile della gestione della selezione multipla delle spese.
// Utilizzato nella HomePage e DaysPage per selezionare, deselezionare ed eliminare più voci.
// Funziona tramite ChangeNotifier per mantenere lo stato reattivo dell'interfaccia.

import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/utils/dialog_utils.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:get_it/get_it.dart';

class MultiSelectProvider extends ChangeNotifier {
  // --- STATO ---

  // Indica se la modalità selezione è attiva
  bool _isSelectionMode = false;

  // Insieme degli ID delle spese selezionate
  final Set<String> _selectedIds = {};

  // --- GETTERS ---

  bool get isSelectionMode => _isSelectionMode;

  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  int get selectedCount => _selectedIds.length;

  // --- ATTIVA SELEZIONE ---

  /// Attiva la modalità selezione al primo long press
  /// e aggiunge la prima spesa selezionata.
  void onLongPress(ExpenseModel expense) {
    _isSelectionMode = true;
    _selectedIds.add(expense.uuid);
    notifyListeners();
  }

  // --- TOGGLE SELEZIONE ---

  /// Aggiunge o rimuove una spesa dall'elenco selezionato.
  /// Se l'ultimo elemento viene deselezionato, la modalità di selezione si disattiva.
  void onToggleSelect(ExpenseModel expense) {
    if (_selectedIds.contains(expense.uuid)) {
      _selectedIds.remove(expense.uuid);
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedIds.add(expense.uuid);
    }
    notifyListeners();
  }

  // --- SELEZIONA TUTTO ---

  /// Seleziona tutte le spese disponibili nella lista fornita.
  /// Utile per selezionare tutte le spese in una volta sola.
  void selectAll(List<ExpenseModel> expenses) {
    for (var expense in expenses) {
      _selectedIds.add(expense.uuid);
    }
    notifyListeners();
  }

  // --- DESELEZIONA TUTTO ---

  /// Deseleziona tutte le spese e disattiva la modalità selezione.
  void deselectAll() {
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  // --- ANNULLA SELEZIONE ---

  /// Disattiva la modalità di selezione e svuota l'elenco.
  void cancelSelection() {
    _isSelectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  // --- ELIMINAZIONE MASSIVA ---

  /// Elimina tutte le spese selezionate, previa conferma dell'utente.
  /// Mostra una snackbar che permette anche di annullare l'eliminazione.
  Future<void> deleteSelected(BuildContext context) async {
    final count = _selectedIds.length;

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

    // Recupera ExpenseStore da GetIt
    final expenseProvider = GetIt.instance<ExpenseProvider>();

    // Recupera le spese selezionate
    final deletedExpenses = expenseProvider.expenses
        .where((e) => _selectedIds.contains(e.uuid))
        .toList();

    // Elimina le spese da ExpenseStore
    for (var expense in deletedExpenses) {
      await expenseProvider.deleteExpense(expense);
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
          expenseProvider.deleteExpense(expense);
        }
      },
      // 🔻 Ripristino premendo "Annulla"
      onRestore: (_) {
        for (var expense in deletedExpenses) {
          expenseProvider.restoreExpense(expense);
        }
      },
    );

    // Pulisce la selezione dopo l'eliminazione
    cancelSelection();
  }

  // --- UTILITY ---

  /// Verifica se una spesa specifica è selezionata
  bool isSelected(String uuid) => _selectedIds.contains(uuid);
}
