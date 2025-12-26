import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/services/multi_select_service.dart';
import 'package:flutter/material.dart';

/// FILE: multi_select_provider.dart
/// DESCRIZIONE: Gestore di stato per la funzionalità di selezione multipla.
/// Controlla l'attivazione della modalità di selezione (es. dopo long press),
/// tiene traccia degli ID selezionati e coordina le operazioni di eliminazione
/// di massa tramite il servizio dedicato.

class MultiSelectProvider extends ChangeNotifier {
  // --- DIPENDENZE ---
  final MultiSelectService _multiSelectService;

  MultiSelectProvider({required MultiSelectService multiSelectService})
      : _multiSelectService = multiSelectService;

  // --- STATO INTERNO ---
  // _isSelectionMode: Indica se la UI deve mostrare checkbox o app bar contestuale.
  // _selectedIds: Insieme univoco degli UUID delle spese attualmente selezionate.
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // --- GETTERS ---
  // Espone lo stato in sola lettura. Restituisce una copia non modificabile del Set
  // per prevenire modifiche dirette dall'esterno senza passare per i metodi del provider.
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  int get selectedCount => _selectedIds.length;

  // --- GESTIONE INPUT UTENTE ---
  // Attivato alla pressione prolungata su una spesa.
  // Abilita la modalità selezione e aggiunge l'elemento corrente.
  void onLongPress(ExpenseModel expense) {
    _isSelectionMode = true;
    _selectedIds.add(expense.uuid);
    notifyListeners();
  }

  // Gestisce il tap su una spesa quando la modalità selezione è già attiva.
  // Aggiunge o rimuove l'ID. Se la lista si svuota, esce dalla modalità selezione.
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

  // --- AZIONI DI SELEZIONE GLOBALE ---
  // Seleziona tutte le spese presenti nella lista passata (utile per "Seleziona tutto").
  void selectAll(List<ExpenseModel> expenses) {
    for (var expense in expenses) {
      _selectedIds.add(expense.uuid);
    }
    notifyListeners();
  }

  // Deseleziona tutto e disattiva la modalità selezione (es. pulsante "Annulla" o back).
  void deselectAll() {
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  // Alias funzionale per la pulizia della selezione.
  void cancelSelection() {
    _isSelectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  // --- OPERAZIONI CRUD BATCH ---
  // Esegue l'eliminazione fisica tramite il servizio.
  // Restituisce la lista degli oggetti eliminati per permettere un'eventuale Undo (Snackbar).
  // Al termine, resetta la modalità di selezione.
  Future<List<ExpenseModel>> deleteSelectedExpenses(List<ExpenseModel> allExpenses) async {
    final deletedExpenses = await _multiSelectService.deleteExpenses(_selectedIds, allExpenses);
    cancelSelection();
    return deletedExpenses;
  }

  // Ripristina una lista di spese precedentemente eliminate (logica Undo).
  Future<void> restoreExpenses(List<ExpenseModel> expenses) async {
    await _multiSelectService.restoreExpenses(expenses);
  }

  // --- HELPER UI ---
  // Metodo di utilità per verificare rapidamente se una specifica spesa è selezionata.
  bool isSelected(String uuid) => _selectedIds.contains(uuid);
}