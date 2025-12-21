import 'package:flutter/foundation.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/expense_provider.dart';

/// FILE: multi_select_provider.dart
/// DESCRIZIONE: Provider dedicato alla gestione della selezione multipla degli elementi.
/// Mantiene lo stato degli ID selezionati e coordina le operazioni massive (come l'eliminazione di gruppo)
/// delegando la logica di persistenza all'ExpenseProvider.

class MultiSelectProvider extends ChangeNotifier {
  final ExpenseProvider _expenseProvider;

  MultiSelectProvider({required ExpenseProvider expenseProvider})
      : _expenseProvider = expenseProvider;

  // --- STATO E GETTERS ---
  // Gestisce il flag della modalità selezione e il Set di ID univoci selezionati.
  // I getter espongono lo stato in sola lettura per la UI.
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  int get selectedCount => _selectedIds.length;

  // --- LOGICA DI SELEZIONE ---
  // Metodi per gestire le transizioni di stato: attivazione tramite long-press,
  // toggle di singoli elementi, selezione globale e annullamento.
  // 
  void onLongPress(ExpenseModel expense) {
    _isSelectionMode = true;
    _selectedIds.add(expense.uuid);
    notifyListeners();
  }

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

  void selectAll(List<ExpenseModel> expenses) {
    for (var expense in expenses) {
      _selectedIds.add(expense.uuid);
    }
    notifyListeners();
  }

  void deselectAll() {
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  void cancelSelection() {
    _isSelectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  // --- OPERAZIONI MASSIVE (DELETE & UNDO) ---
  // Esegue l'eliminazione fisica tramite l'ExpenseProvider e restituisce
  // la lista degli oggetti cancellati per permettere alla UI di gestire
  // il ripristino (Undo) tramite SnackBar.
  Future<List<ExpenseModel>> deleteSelectedExpenses() async {
    // 1. Identifica le spese da eliminare
    final deletedExpenses = _expenseProvider.expenses
        .where((e) => _selectedIds.contains(e.uuid))
        .toList();

    // 2. Elimina dal DB/Store
    for (var expense in deletedExpenses) {
      await _expenseProvider.deleteExpense(expense);
    }

    // 3. Pulisce la selezione
    cancelSelection();

    // 4. Ritorna gli elementi per eventuale ripristino
    return deletedExpenses;
  }

  Future<void> restoreExpenses(List<ExpenseModel> expenses) async {
    for (var expense in expenses) {
      await _expenseProvider.restoreExpense(expense);
    }
    // Opzionale: se vuoi riselezionarli dopo il ripristino, puoi farlo qui
  }

  // --- UTILITY ---
  // Helper rapido per verificare se un elemento specifico è selezionato.
  bool isSelected(String uuid) => _selectedIds.contains(uuid);
}