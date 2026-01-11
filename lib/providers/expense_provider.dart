import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:flutter/foundation.dart';

/// FILE: expense_provider.dart
class ExpenseProvider extends ChangeNotifier {
  // --- STATO E DIPENDENZE ---
  final NotificationProvider _notificationProvider;
  final ExpenseService _expenseService;

  ExpenseProvider({
    required NotificationProvider notificationProvider,
    required ExpenseService expenseService,
  }) : _notificationProvider = notificationProvider,
       _expenseService = expenseService;

  // --- STATO DATI ---
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  // --- STATO ERRORI ---
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // --- CACHE TOTALI ---
  double _todayTotal = 0.0;
  double _weekTotal = 0.0;
  double _monthTotal = 0.0;
  double _yearTotal = 0.0;

  double get totalExpenseToday => _todayTotal;
  double get totalExpenseWeek => _weekTotal;
  double get totalExpenseMonth => _monthTotal;
  double get totalExpenseYear => _yearTotal;

  // --- HELPER INTERNI ---
  void _refreshTotals() {
    _todayTotal = ExpenseCalculator.totalExpenseToday(_expenses);
    _weekTotal = ExpenseCalculator.totalExpenseWeek(_expenses);
    _monthTotal = ExpenseCalculator.totalExpenseMonth(_expenses);
    _yearTotal = ExpenseCalculator.totalExpenseYear(_expenses);
  }
  
  void _sortByDateDesc() {
    ExpenseCalculator.sortInPlace(_expenses, "date_desc");
  }

  // --- INIZIALIZZAZIONE ---
  Future<void> initialise() async {
    _errorMessage = null;
    try {
      _expenses = await _expenseService.loadUserExpenses();
      _refreshTotals();
    } on RepositoryFailure catch (e) {
      _errorMessage = "Error loading data: ${e.message}";
      rethrow; 
    } catch (e) {
      _errorMessage = "Unknown error during startup.";
      rethrow; 
    }
    notifyListeners();
  }

  void clear() {
    _expenses = [];
    _errorMessage = null;
    _refreshTotals();
    notifyListeners();
  }

  // --- CREAZIONE & MODIFICA ---
  
  /// MODIFICATO: Aggiunto parametro l10n
  Future<void> createExpense({
    required double value,
    required String? description,
    required DateTime date,
    required AppLocalizations l10n, // NECESSARIO per la notifica
  }) async {
    _errorMessage = null;
    notifyListeners(); 

    try {
      final expense = await _expenseService.createExpense(
        value: value,
        description: description,
        date: date,
      );

      _expenses.add(expense);
      _sortByDateDesc(); 
      _refreshTotals();
      
      // Passiamo l10n al controllo budget
      _checkBudget(dateToCheck: date, l10n: l10n);

    } on RepositoryFailure catch (e) {
      _errorMessage = "Save failed: ${e.message}";
    } catch (e) {
      _errorMessage = e.toString(); 
    } finally {
      notifyListeners();
    }
  }

  /// MODIFICATO: Aggiunto parametro l10n
  Future<void> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
    required AppLocalizations l10n, // NECESSARIO per la notifica
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _expenseService.editExpense(
        expenseModel,
        value: value,
        description: description,
        date: date,
      );
      _sortByDateDesc();
      _refreshTotals();
      
      // Passiamo l10n al controllo budget
      _checkBudget(dateToCheck: date, l10n: l10n);

    } on RepositoryFailure catch (e) {
      _errorMessage = "Edit failed: ${e.message}";
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // --- ELIMINAZIONE UNIFICATA ---
  // Nota: Delete non richiede l10n perché cancellando le spese 
  // non si rischia di superare il budget (si scende).
  Future<void> deleteExpenses(List<ExpenseModel> expensesToDelete) async {
    if (expensesToDelete.isEmpty) return;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait(expensesToDelete.map((e) => _expenseService.deleteExpense(e)));

      final idsToRemove = expensesToDelete.map((e) => e.uuid).toSet();
      _expenses.removeWhere((element) => idsToRemove.contains(element.uuid));

      _refreshTotals();

    } on RepositoryFailure catch (e) {
      _errorMessage = "Deletion failed. Data restored. (${e.message})";
    } catch (e) {
      _errorMessage = "Error deleting: $e";
    } finally {
      notifyListeners();
    }
  }

  // --- RIPRISTINO UNIFICATO ---
  /// MODIFICATO: Aggiunto parametro l10n (il ripristino può far superare il budget)
  Future<void> restoreExpenses(
    List<ExpenseModel> expensesToRestore, 
    AppLocalizations l10n, 
  ) async {
    if (expensesToRestore.isEmpty) return;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait(expensesToRestore.map((e) => _expenseService.restoreExpense(e)));

      _expenses.addAll(expensesToRestore);
      _sortByDateDesc(); 
      _refreshTotals();
      
      // Passiamo l10n
      _checkBudgetForList(expensesToRestore, l10n);

    } on RepositoryFailure catch (e) {
      _errorMessage = "Unable to restore expenses: ${e.message}";
    } catch (e) {
      _errorMessage = "Restore error: $e";
    } finally {
      notifyListeners();
    }
  }

  // --- HELPER BUDGET & ORDINAMENTO ---
  
  /// MODIFICATO: Accetta l10n e lo passa al NotificationProvider
  Future<void> _checkBudget({
    required DateTime dateToCheck,
    required AppLocalizations l10n,
  }) async {
    final now = DateTime.now();
    if (dateToCheck.month != now.month || dateToCheck.year != now.year) return;

    if (_notificationProvider.limitAlertEnabled) {
      // Qui avviene il passaggio chiave
      await _notificationProvider.checkBudgetLimit(_monthTotal, l10n);
    }
  }

  /// MODIFICATO: Accetta l10n
  Future<void> _checkBudgetForList(
    List<ExpenseModel> expenses, 
    AppLocalizations l10n,
  ) async {
    final now = DateTime.now();
    bool hasCurrentMonthExpense = expenses.any((e) => 
      e.createdOn.month == now.month && e.createdOn.year == now.year
    );

    if (hasCurrentMonthExpense && _notificationProvider.limitAlertEnabled) {
      await _notificationProvider.checkBudgetLimit(_monthTotal, l10n);
    }
  }
  
  void sortBy(String criteria) {
    ExpenseCalculator.sortInPlace(_expenses, criteria);
    notifyListeners();
  }

  Map<String, double> get expensesByMonth => ExpenseCalculator.expensesByMonth(_expenses);
  
  Map<String, double> expensesByDay(int year, int month) => 
      ExpenseCalculator.expensesByDay(_expenses, year, month);
  
  List<ExpenseModel> expensesOfDay(int year, int month, int day) => 
      ExpenseCalculator.expensesOfDay(_expenses, year, month, day);
}