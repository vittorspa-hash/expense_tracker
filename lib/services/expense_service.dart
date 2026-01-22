import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// FILE: expense_service.dart
/// DESCRIZIONE: Business Logic Layer per la gestione delle spese.
/// Contiene TUTTA la logica applicativa: calcoli, conversioni valuta,
/// strategie soft-fail, aggregazioni, ordinamento e decisioni di business.

class ExpenseService {
  final FirebaseRepository _firebaseRepository;
  final FirebaseAuth _firebaseAuth;
  final CurrencyService _currencyService;

  ExpenseService({
    required FirebaseRepository firebaseRepository,
    required FirebaseAuth firebaseAuth,
    required CurrencyService currencyService,
  }) : _firebaseRepository = firebaseRepository,
       _firebaseAuth = firebaseAuth,
       _currencyService = currencyService;

  // --- LETTURA DATI ---
  Future<List<ExpenseModel>> loadUserExpenses() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return [];

    final expenses = await _firebaseRepository.allExpensesForUser(user.uid);
    expenses.sort((a, b) => b.createdOn.compareTo(a.createdOn));
    return expenses;
  }

  // --- CREAZIONE CON SOFT-FAIL STRATEGY ---
  /// Business Logic: Gestisce il recupero dei tassi con fallback 1:1
  Future<CreateExpenseResult> createExpense({
    required double value,
    required String? description,
    required DateTime date,
    required String currency,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw RepositoryFailure("User not authenticated.");

    Map<String, double> exchangeRates;
    String? warning;

    // SOFT-FAIL STRATEGY (BUSINESS LOGIC!)
    try {
      exchangeRates = await _currencyService.getExchangeRates(currency);
    } on CurrencyFetchException {
      debugPrint("Currency fetch failed. Using fallback 1:1.");
      exchangeRates = {currency: 1.0};
      warning = 'offline_currency_create'; // Codice per l10n
    }

    final expense = ExpenseModel(
      uuid: const Uuid().v4(),
      value: value,
      description: description,
      createdOn: date,
      userId: user.uid,
      currency: currency,
      exchangeRates: exchangeRates,
    );

    await _firebaseRepository.createExpense(expense);

    return CreateExpenseResult(expense: expense, warning: warning);
  }

  // --- MODIFICA CON SMART-UPDATE STRATEGY ---
  /// Business Logic: Ripara tassi rotti se necessario
  Future<EditExpenseResult> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
    required String currency,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || expenseModel.userId != user.uid) {
      throw RepositoryFailure("Permission denied");
    }

    Map<String, double> exchangeRates = expenseModel.exchangeRates;
    String? warning;

    // SMART-UPDATE STRATEGY (BUSINESS LOGIC!)
    bool areRatesBroken = expenseModel.exchangeRates.length <= 1;

    if (areRatesBroken) {
      try {
        debugPrint("Repairing broken rates...");
        exchangeRates = await _currencyService.getExchangeRates(currency);
        debugPrint("Rates repaired successfully.");
      } on CurrencyFetchException {
        debugPrint("Repair failed. Still offline.");
        if (exchangeRates.isEmpty || !exchangeRates.containsKey(currency)) {
          exchangeRates = {currency: 1.0};
        }
        warning = 'offline_currency_edit';
      }
    }

    final updatedExpense = expenseModel.copyWith(
      value: value,
      description: description,
      createdOn: date,
      currency: currency,
      exchangeRates: exchangeRates,
    );

    await _firebaseRepository.updateExpense(updatedExpense);

    return EditExpenseResult(expense: updatedExpense, warning: warning);
  }

  // --- ELIMINAZIONE E RIPRISTINO ---

  Future<ExpenseModel> restoreExpense(ExpenseModel expenseModel) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw RepositoryFailure("User not authenticated.");

    if (expenseModel.userId != user.uid) {
      throw RepositoryFailure("Cannot restore another user's expense");
    }

    await _firebaseRepository.createExpense(expenseModel);
    return expenseModel;
  }

  Future<void> deleteExpense(ExpenseModel expenseModel) async {
    final user = _firebaseAuth.currentUser;

    if (user == null || expenseModel.userId != user.uid) {
      throw RepositoryFailure(
        "You do not have permission to delete this expense.",
      );
    }

    await _firebaseRepository.deleteExpense(expenseModel);
  }

  // --- BUSINESS LOGIC: CALCOLI E AGGREGAZIONI ---

  /// Calcola i totali convertiti nella valuta target
  ExpenseTotals calculateTotals(
    List<ExpenseModel> expenses,
    String targetCurrency,
  ) {
    return ExpenseTotals(
      today: ExpenseCalculator.totalExpenseToday(expenses, targetCurrency),
      week: ExpenseCalculator.totalExpenseWeek(expenses, targetCurrency),
      month: ExpenseCalculator.totalExpenseMonth(expenses, targetCurrency),
      year: ExpenseCalculator.totalExpenseYear(expenses, targetCurrency),
    );
  }

  // --- BUSINESS LOGIC: VERIFICA BUDGET ---

  /// Verifica se il budget deve generare un alert per una singola spesa
  /// BUSINESS LOGIC: include controlli temporali, limite e stato abilitazione
  BudgetCheckResult checkBudgetStatus({
    required List<ExpenseModel> expenses,
    required DateTime expenseDate,
    required String targetCurrency,
    required double budgetLimit,
    required bool alertEnabled,
  }) {
    // Regola 1: Se alert disabilitato, non notificare
    if (!alertEnabled) {
      return BudgetCheckResult(shouldNotify: false, currentTotal: 0);
    }

    final now = DateTime.now();

    // Regola 2: Notifica solo se la spesa è del mese corrente
    if (expenseDate.month != now.month || expenseDate.year != now.year) {
      return BudgetCheckResult(shouldNotify: false, currentTotal: 0);
    }

    // Regola 3: Calcola totale e verifica superamento
    final monthTotal = ExpenseCalculator.totalExpenseMonth(
      expenses,
      targetCurrency,
    );

    return BudgetCheckResult(
      shouldNotify: monthTotal >= budgetLimit,
      currentTotal: monthTotal,
    );
  }

  /// Verifica se il budget deve generare un alert per un gruppo di spese
  /// BUSINESS LOGIC: usato per restore multiplo
  BudgetCheckResult checkBudgetStatusForList({
    required List<ExpenseModel> allExpenses,
    required List<ExpenseModel> newExpenses,
    required String targetCurrency,
    required double budgetLimit,
    required bool alertEnabled,
  }) {
    // Regola 1: Se alert disabilitato, non notificare
    if (!alertEnabled) {
      return BudgetCheckResult(shouldNotify: false, currentTotal: 0);
    }

    final now = DateTime.now();

    // Regola 2: Verifica se almeno una spesa è del mese corrente
    final hasCurrentMonthExpense = newExpenses.any(
      (e) => e.createdOn.month == now.month && e.createdOn.year == now.year,
    );

    if (!hasCurrentMonthExpense) {
      return BudgetCheckResult(shouldNotify: false, currentTotal: 0);
    }

    // Regola 3: Calcola totale e verifica superamento
    final monthTotal = ExpenseCalculator.totalExpenseMonth(
      allExpenses,
      targetCurrency,
    );

    return BudgetCheckResult(
      shouldNotify: monthTotal >= budgetLimit,
      currentTotal: monthTotal,
    );
  }

  // --- BUSINESS LOGIC: ORDINAMENTO ---

  /// Ordina le spese secondo il criterio specificato
  /// RESTITUISCE una nuova lista ordinata (non muta l'originale)
  List<ExpenseModel> sortExpenses(
    List<ExpenseModel> expenses,
    String criteria,
    String? targetCurrency,
  ) {
    // Crea una copia per non mutare l'originale
    final sorted = List<ExpenseModel>.from(expenses);

    if (criteria.contains("amount")) {
      ExpenseCalculator.sortInPlace(
        sorted,
        criteria,
        targetCurrency: targetCurrency,
      );
    } else {
      ExpenseCalculator.sortInPlace(sorted, criteria);
    }

    return sorted;
  }

  // --- BUSINESS LOGIC: AGGREGAZIONI PER GRAFICI ---

  /// Aggregazione per grafici mensili
  Map<String, double> getExpensesByMonth(
    List<ExpenseModel> expenses,
    String targetCurrency,
  ) {
    return ExpenseCalculator.expensesByMonth(expenses, targetCurrency);
  }

  /// Aggregazione per grafici giornalieri
  Map<String, double> getExpensesByDay(
    List<ExpenseModel> expenses,
    int year,
    int month,
    String targetCurrency,
  ) {
    return ExpenseCalculator.expensesByDay(
      expenses,
      year,
      month,
      targetCurrency,
    );
  }

  /// Filtra spese per giorno specifico
  List<ExpenseModel> getExpensesOfDay(
    List<ExpenseModel> expenses,
    int year,
    int month,
    int day,
  ) {
    return ExpenseCalculator.expensesOfDay(expenses, year, month, day);
  }
}

// --- RESULT OBJECTS ---

class CreateExpenseResult {
  final ExpenseModel expense;
  final String? warning; // null se tutto OK, codice stringa se offline

  CreateExpenseResult({required this.expense, this.warning});
}

class EditExpenseResult {
  final ExpenseModel expense;
  final String? warning;

  EditExpenseResult({required this.expense, this.warning});
}

class ExpenseTotals {
  final double today;
  final double week;
  final double month;
  final double year;

  ExpenseTotals({
    required this.today,
    required this.week,
    required this.month,
    required this.year,
  });
}

class BudgetCheckResult {
  final bool shouldNotify;
  final double currentTotal;

  BudgetCheckResult({required this.shouldNotify, required this.currentTotal});
}
