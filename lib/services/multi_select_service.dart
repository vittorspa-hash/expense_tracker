import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/services/expense_service.dart';

/// FILE: multi_select_service.dart
/// DESCRIZIONE: Servizio di backend per le operazioni di massa (batch operations).
/// Si occupa di processare liste di spese da eliminare o ripristinare,
/// iterando le chiamate CRUD verso il servizio di persistenza (ExpenseService).

class MultiSelectService {
  // --- DIPENDENZE ---
  // Riferimento al servizio principale per eseguire le singole operazioni sul database.
  final ExpenseService _expenseService;

  MultiSelectService({required ExpenseService expenseService})
      : _expenseService = expenseService;

  // --- ELIMINAZIONE DI MASSA ---
  // Filtra la lista completa delle spese per trovare quelle corrispondenti agli ID selezionati.
  // Esegue l'eliminazione per ogni singola spesa trovata.
  // Restituisce la lista degli oggetti eliminati per consentire un eventuale "Undo".
  Future<List<ExpenseModel>> deleteExpenses(Set<String> selectedIds, List<ExpenseModel> allExpenses) async {
    final expensesToDelete = allExpenses
        .where((e) => selectedIds.contains(e.uuid))
        .toList();

    for (var expense in expensesToDelete) {
      await _expenseService.deleteExpense(expense);
    }

    return expensesToDelete;
  }

  // --- RIPRISTINO DI MASSA ---
  // Accetta una lista di spese (tipicamente quelle appena cancellate)
  // e le reinserisce nel database una ad una. Utile per la funzionalità "Annulla".
  Future<void> restoreExpenses(List<ExpenseModel> expenses) async {
    for (var expense in expenses) {
      await _expenseService.restoreExpense(expense);
    }
  }
}