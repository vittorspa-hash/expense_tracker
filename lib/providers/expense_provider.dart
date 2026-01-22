import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:flutter/foundation.dart';

/// FILE: expense_provider.dart
/// DESCRIZIONE: State Manager per le spese.
/// Gestisce SOLO lo stato UI e orchestra le chiamate al service.
/// TUTTA la business logic è delegata a ExpenseService.

class ExpenseProvider extends ChangeNotifier {
  final NotificationProvider _notificationProvider;
  final ExpenseService _expenseService;

  ExpenseProvider({
    required NotificationProvider notificationProvider,
    required ExpenseService expenseService,
  }) : _notificationProvider = notificationProvider,
       _expenseService = expenseService;

  // --- STATO ---
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _warningMessage;
  String? get warningMessage => _warningMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _appCurrency = 'EUR';

  // Cache totali (calcolati dal service)
  ExpenseTotals _totals = ExpenseTotals(today: 0, week: 0, month: 0, year: 0);

  double get totalExpenseToday => _totals.today;
  double get totalExpenseWeek => _totals.week;
  double get totalExpenseMonth => _totals.month;
  double get totalExpenseYear => _totals.year;

  void clearError() {
    _errorMessage = null;
    _warningMessage = null;
    notifyListeners();
  }

  // --- CALCOLO TOTALI (delega al service) ---
  void _refreshTotals() {
    _totals = _expenseService.calculateTotals(_expenses, _appCurrency);
  }

  // --- AGGIORNAMENTO VALUTA ---
  void updateAppCurrency(String newCurrencyCode) {
    if (_appCurrency != newCurrencyCode) {
      _appCurrency = newCurrencyCode;
      _refreshTotals();
      notifyListeners();
    }
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

  // --- CREAZIONE (delega al service) ---
  Future<void> createExpense({
    required double value,
    required String? description,
    required DateTime date,
    required AppLocalizations l10n,
    required String currencySymbol,
    required String currencyCode,
  }) async {
    _errorMessage = null;
    _warningMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      // DELEGA LA BUSINESS LOGIC AL SERVICE
      final result = await _expenseService.createExpense(
        value: value,
        description: description,
        date: date,
        currency: currencyCode,
      );

      // Gestisci il risultato
      if (result.warning != null) {
        _warningMessage = l10n.warningOfflineCurrencyCreate;
      }

      _expenses.add(result.expense);

      // RICEVI lista ordinata dal service (non muta più _expenses direttamente)
      _expenses = _expenseService.sortExpenses(_expenses, "date_desc", null);
      _refreshTotals();

      // Orchestrazione: verifica budget
      await _checkBudget(
        dateToCheck: date,
        l10n: l10n,
        currencySymbol: currencySymbol,
      );
    } on RepositoryFailure catch (e) {
      _errorMessage = "Save failed: ${e.message}";
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MODIFICA (delega al service) ---
  Future<void> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
    required String currencyCode,
    required AppLocalizations l10n,
    required String currencySymbol,
  }) async {
    _errorMessage = null;
    _warningMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      // DELEGA LA BUSINESS LOGIC AL SERVICE
      final result = await _expenseService.editExpense(
        expenseModel,
        value: value,
        description: description,
        date: date,
        currency: currencyCode,
      );

      if (result.warning != null) {
        _warningMessage = l10n.warningOfflineCurrencyEdit;
      }

      // ✅ FIX: Sostituisci la vecchia istanza con quella aggiornata
      final index = _expenses.indexWhere((e) => e.uuid == expenseModel.uuid);
      if (index != -1) {
        _expenses[index] = result.expense;
      } else {
        // Safety: Se non trovato, aggiungi (non dovrebbe mai succedere)
        debugPrint(
          '⚠️ Warning: Expense ${expenseModel.uuid} not found in list',
        );
        _expenses.add(result.expense);
      }

      // Ordina con la nuova istanza
      _expenses = _expenseService.sortExpenses(_expenses, "date_desc", null);
      _refreshTotals();

      // Orchestrazione: verifica budget
      await _checkBudget(
        dateToCheck: date,
        l10n: l10n,
        currencySymbol: currencySymbol,
      );
    } on RepositoryFailure catch (e) {
      _errorMessage = "Edit failed: ${e.message}";
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ELIMINAZIONE E RIPRISTINO ---
  Future<void> deleteExpenses(List<ExpenseModel> expensesToDelete) async {
    if (expensesToDelete.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.wait(
        expensesToDelete.map((e) => _expenseService.deleteExpense(e)),
      );

      final idsToRemove = expensesToDelete.map((e) => e.uuid).toSet();
      _expenses.removeWhere((element) => idsToRemove.contains(element.uuid));
      _refreshTotals();
    } on RepositoryFailure catch (e) {
      _errorMessage = "Deletion failed: ${e.message}";
    } catch (e) {
      _errorMessage = "Error deleting: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreExpenses(
    List<ExpenseModel> expensesToRestore,
    AppLocalizations l10n,
    String currencySymbol,
  ) async {
    if (expensesToRestore.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait(
        expensesToRestore.map((e) => _expenseService.restoreExpense(e)),
      );

      _expenses.addAll(expensesToRestore);

      // RICEVI lista ordinata dal service
      _expenses = _expenseService.sortExpenses(_expenses, "date_desc", null);
      _refreshTotals();

      // Orchestrazione: verifica budget per lista
      await _checkBudgetForList(expensesToRestore, l10n, currencySymbol);
    } on RepositoryFailure catch (e) {
      _errorMessage = "Unable to restore: ${e.message}";
    } catch (e) {
      _errorMessage = "Restore error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- VERIFICA BUDGET (orchestrazione pura, business logic nel service) ---

  /// Orchestrazione: Delega la decisione al service, poi notifica se necessario
  Future<void> _checkBudget({
    required DateTime dateToCheck,
    required AppLocalizations l10n,
    required String currencySymbol,
  }) async {
    // DELEGA TUTTA LA DECISIONE AL SERVICE
    final result = _expenseService.checkBudgetStatus(
      expenses: _expenses,
      expenseDate: dateToCheck,
      targetCurrency: _appCurrency,
      budgetLimit: _notificationProvider.monthlyLimit,
      alertEnabled: _notificationProvider.limitAlertEnabled,
    );

    // ORCHESTRAZIONE: se il service dice di notificare, notifica
    if (result.shouldNotify) {
      await _notificationProvider.checkBudgetLimit(
        result.currentTotal,
        l10n,
        currencySymbol,
      );
    }
  }

  /// Orchestrazione: Verifica budget per un gruppo di spese ripristinate
  Future<void> _checkBudgetForList(
    List<ExpenseModel> expenses,
    AppLocalizations l10n,
    String currencySymbol,
  ) async {
    // DELEGA TUTTA LA DECISIONE AL SERVICE
    final result = _expenseService.checkBudgetStatusForList(
      allExpenses: _expenses,
      newExpenses: expenses,
      targetCurrency: _appCurrency,
      budgetLimit: _notificationProvider.monthlyLimit,
      alertEnabled: _notificationProvider.limitAlertEnabled,
    );

    // ORCHESTRAZIONE: se il service dice di notificare, notifica
    if (result.shouldNotify) {
      await _notificationProvider.checkBudgetLimit(
        result.currentTotal,
        l10n,
        currencySymbol,
      );
    }
  }

  // --- ORDINAMENTO (delega al service) ---

  /// Orchestrazione: Riceve lista ordinata dal service e aggiorna lo stato
  void sortBy(String criteria) {
    final targetCurrency = criteria.contains("amount") ? _appCurrency : null;

    // RICEVI nuova lista ordinata (non muta più _expenses direttamente)
    _expenses = _expenseService.sortExpenses(
      _expenses,
      criteria,
      targetCurrency,
    );
    notifyListeners();
  }

  // --- DATI PER GRAFICI (delega al service) ---

  Map<String, double> get expensesByMonth =>
      _expenseService.getExpensesByMonth(_expenses, _appCurrency);

  Map<String, double> expensesByDay(int year, int month) =>
      _expenseService.getExpensesByDay(_expenses, year, month, _appCurrency);

  List<ExpenseModel> expensesOfDay(int year, int month, int day) =>
      _expenseService.getExpensesOfDay(_expenses, year, month, day);
}
