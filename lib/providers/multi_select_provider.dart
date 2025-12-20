// multi_select_provider.dart
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/expense_provider.dart';

class MultiSelectProvider extends ChangeNotifier {
  final ExpenseProvider _expenseProvider;

  MultiSelectProvider({required ExpenseProvider expenseProvider})
      : _expenseProvider = expenseProvider;

  // --- STATO ---
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // --- GETTERS ---
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  int get selectedCount => _selectedIds.length;

  // --- ATTIVA SELEZIONE ---
  void onLongPress(ExpenseModel expense) {
    _isSelectionMode = true;
    _selectedIds.add(expense.uuid);
    notifyListeners();
  }

  // --- TOGGLE SELEZIONE ---
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
  void selectAll(List<ExpenseModel> expenses) {
    for (var expense in expenses) {
      _selectedIds.add(expense.uuid);
    }
    notifyListeners();
  }

  // --- DESELEZIONA TUTTO ---
  void deselectAll() {
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  // --- ANNULLA SELEZIONE ---
  void cancelSelection() {
    _isSelectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  // --- ELIMINAZIONE MASSIVA (Logica Pura) ---

  /// Elimina le spese selezionate e ritorna la lista degli elementi eliminati.
  /// La lista di ritorno serve alla UI per implementare la funzione "Annulla/Undo".
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

  // --- RIPRISTINO (Per funzione Undo) ---
  Future<void> restoreExpenses(List<ExpenseModel> expenses) async {
    for (var expense in expenses) {
      await _expenseProvider.restoreExpense(expense);
    }
    // Opzionale: se vuoi riselezionarli dopo il ripristino, puoi farlo qui
  }

  // --- UTILITY ---
  bool isSelected(String uuid) => _selectedIds.contains(uuid);
}