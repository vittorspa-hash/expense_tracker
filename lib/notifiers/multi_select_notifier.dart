import 'package:expense_tracker/models/expense_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: multi_select_notifier.dart
/// DESCRIZIONE: Gestisce lo stato della selezione multipla (batch) delle spese nella UI.
/// Mantiene traccia degli UUID selezionati e determina se l'applicazione si trova
/// in modalità selezione (isSelectionMode) per alterare l'Appbar e il comportamento dei widget.

// --- STATO ---
/// Rappresentazione immutabile dello stato di selezione degli elementi.
class MultiSelectState {
  final bool isSelectionMode;
  final Set<String> selectedIds;

  const MultiSelectState({
    this.isSelectionMode = false,
    this.selectedIds = const {},
  });

  /// Getter di utilità per ricavare il numero di elementi attualmente selezionati.
  int get selectedCount => selectedIds.length;
  
  /// Verifica se un singolo elemento è marcato come selezionato.
  bool isSelected(String uuid) => selectedIds.contains(uuid);

  /// Metodo per generare una nuova istanza dello stato modificandone selettivamente i parametri.
  MultiSelectState copyWith({bool? isSelectionMode, Set<String>? selectedIds}) {
    return MultiSelectState(
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

// --- NOTIFIER ---
/// Controller reattivo incaricato di orchestrare la logica di selezione di massa.
class MultiSelectNotifier extends Notifier<MultiSelectState> {
  
  @override
  MultiSelectState build() {
    return const MultiSelectState();
  }

  // --- LOGICA DI SELEZIONE ED EVENTI ---

  /// Attiva la modalità di selezione multipla al tocco prolungato su una tessera spesa.
  void onLongPress(ExpenseModel expense) {
    state = state.copyWith(
      isSelectionMode: true,
      selectedIds: {...state.selectedIds, expense.uuid},
    );
  }

  /// Inverte lo stato di selezione di un singolo elemento (seleziona/deseleziona).
  /// Se l'insieme degli ID si svuota, disattiva automaticamente la modalità di selezione.
  void onToggleSelect(ExpenseModel expense) {
    final updatedIds = Set<String>.from(state.selectedIds);
    
    if (updatedIds.contains(expense.uuid)) {
      updatedIds.remove(expense.uuid);
      state = state.copyWith(
        selectedIds: updatedIds,
        isSelectionMode: updatedIds.isNotEmpty,
      );
    } else {
      updatedIds.add(expense.uuid);
      state = state.copyWith(selectedIds: updatedIds);
    }
  }

  /// Seleziona massivamente tutte le spese visibili all'interno dell'elenco corrente.
  void selectAll(List<ExpenseModel> expenses) {
    state = state.copyWith(
      selectedIds: {...state.selectedIds, ...expenses.map((e) => e.uuid)},
    );
  }

  /// Resetta completamente lo stato disattivando la modalità di selezione e svuotando il set.
  void deselectAll() {
    state = const MultiSelectState();
  }

  /// Metodo di convenienza per esporre la verifica di selezione direttamente sul notifier.
  bool isSelected(String uuid) => state.selectedIds.contains(uuid);
}