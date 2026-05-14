import 'package:expense_tracker/models/expense_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- STATO ---
class MultiSelectState {
  final bool isSelectionMode;
  final Set<String> selectedIds;

  const MultiSelectState({
    this.isSelectionMode = false,
    this.selectedIds = const {},
  });

  int get selectedCount => selectedIds.length;
  bool isSelected(String uuid) => selectedIds.contains(uuid);

  MultiSelectState copyWith({bool? isSelectionMode, Set<String>? selectedIds}) {
    return MultiSelectState(
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

// --- NOTIFIER ---
class MultiSelectNotifier extends Notifier<MultiSelectState> {
  @override
  MultiSelectState build() {
    return const MultiSelectState();
  }

  void onLongPress(ExpenseModel expense) {
    state = state.copyWith(
      isSelectionMode: true,
      selectedIds: {...state.selectedIds, expense.uuid},
    );
  }

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

  void selectAll(List<ExpenseModel> expenses) {
    state = state.copyWith(
      selectedIds: {...state.selectedIds, ...expenses.map((e) => e.uuid)},
    );
  }

  void deselectAll() {
    state = const MultiSelectState();
  }

  bool isSelected(String uuid) => state.selectedIds.contains(uuid);
}