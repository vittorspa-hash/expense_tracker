// expense_provider.dart
// Provider per gestire lo stato delle spese nell'applicazione.
// Delega la logica di business al service e i calcoli al calculator.

import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/settings_provider.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:flutter/foundation.dart';

class ExpenseProvider extends ChangeNotifier {
  final SettingsProvider _settingsProvider;
  final ExpenseService _expenseService;

  ExpenseProvider({
    required SettingsProvider settingsProvider,
    required ExpenseService expenseService,
  }) : _settingsProvider = settingsProvider,
       _expenseService = expenseService;

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  // --- CACHE DEI TOTALI (Performance Boost) ---
  // I getter ora sono istantanei (O(1)) invece che calcolati (O(N))
  double _todayTotal = 0.0;
  double _weekTotal = 0.0;
  double _monthTotal = 0.0;
  double _yearTotal = 0.0;

  double get totalExpenseToday => _todayTotal;
  double get totalExpenseWeek => _weekTotal;
  double get totalExpenseMonth => _monthTotal;
  double get totalExpenseYear => _yearTotal;

  // Funzione privata per aggiornare tutti i totali in un colpo solo
  void _refreshTotals() {
    _todayTotal = ExpenseCalculator.totalExpenseToday(_expenses);
    _weekTotal = ExpenseCalculator.totalExpenseWeek(_expenses);
    _monthTotal = ExpenseCalculator.totalExpenseMonth(_expenses);
    _yearTotal = ExpenseCalculator.totalExpenseYear(_expenses);
  }

  // Helper privato per ordinare per data decrescente (usato internamente)
  void _sortByDateDesc() {
    ExpenseCalculator.sortInPlace(_expenses, "date_desc");
  }

  Future<void> initialise() async {
    _expenses = await _expenseService.loadUserExpenses();
    _refreshTotals();
    notifyListeners();
  }

  void clear() {
    _expenses = [];
    _refreshTotals();
    notifyListeners();
  }

  Future<void> createExpense({
    required double value,
    required String? description,
    required DateTime date,
  }) async {
    final expense = await _expenseService.createExpense(
      value: value,
      description: description,
      date: date,
    );

    _expenses.add(expense);
    _sortByDateDesc(); // ✅ Sort in-place, nessuna allocazione

    _refreshTotals();
    notifyListeners();

    if (_settingsProvider.limitAlertEnabled) {
      await _settingsProvider.checkBudgetLimit(_monthTotal);
    }
  }

  Future<void> restoreExpense(ExpenseModel expenseModel) async {
    final expense = await _expenseService.restoreExpense(expenseModel);

    _expenses.add(expense);
    _sortByDateDesc(); // ✅ Sort in-place

    _refreshTotals();
    notifyListeners();

    if (_settingsProvider.limitAlertEnabled) {
      await _settingsProvider.checkBudgetLimit(_monthTotal);
    }
  }

  Future<void> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
  }) async {
    await _expenseService.editExpense(
      expenseModel,
      value: value,
      description: description,
      date: date,
    );

    _sortByDateDesc(); // ✅ Sort in-place

    _refreshTotals();
    notifyListeners();

    if (_settingsProvider.limitAlertEnabled) {
      await _settingsProvider.checkBudgetLimit(_monthTotal);
    }
  }

  Future<void> deleteExpense(ExpenseModel expenseModel) async {
    await _expenseService.deleteExpense(expenseModel);

    _expenses.remove(expenseModel);

    _refreshTotals();
    notifyListeners();

    if (_settingsProvider.limitAlertEnabled) {
      await _settingsProvider.checkBudgetLimit(_monthTotal);
    }
  }

  // Metodo pubblico per ordinare secondo diversi criteri
  void sortBy(String criteria) {
    ExpenseCalculator.sortInPlace(_expenses, criteria); // ✅ Sort in-place
    notifyListeners();
  }

  // Questi metodi ritornano Map o List filtrate, quindi va bene lasciarli dinamici
  // perché non vengono chiamati ad ogni frame come i totali semplici.
  Map<String, double> get expensesByMonth {
    return ExpenseCalculator.expensesByMonth(_expenses);
  }

  Map<String, double> expensesByDay(int year, int month) {
    return ExpenseCalculator.expensesByDay(_expenses, year, month);
  }

  List<ExpenseModel> expensesOfDay(int year, int month, int day) {
    return ExpenseCalculator.expensesOfDay(_expenses, year, month, day);
  }
}
