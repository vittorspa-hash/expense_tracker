import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/notifiers/notification_notifier.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// FILE: expense_notifier.dart
// DESCRIZIONE: Gestore dello stato globale (Notifier) per i movimenti di spesa.
// Si occupa della sincronizzazione con ExpenseService, del ricalcolo dei
// totali convertiti in valuta corrente e del trigger degli avvisi di budget.

enum ExpenseInitStatus { initial, loading, initialized, error }

// --- STATO IMMUTABILE ---
class ExpenseState {
  final List<ExpenseModel> expenses;
  final ExpenseInitStatus initStatus;
  final Object? initError;
  final String? errorMessage;
  final String? warningMessage;
  final bool isLoading;
  final ExpenseCurrency appCurrency;
  final ExpenseTotals totals;

  ExpenseState({
    this.expenses = const [],
    this.initStatus = ExpenseInitStatus.initial,
    this.initError,
    this.errorMessage,
    this.warningMessage,
    this.isLoading = false,
    this.appCurrency = ExpenseCurrency.euro,
    ExpenseTotals? totals,
  }) : totals = totals ?? ExpenseTotals(today: 0, week: 0, month: 0, year: 0);

  // Getters di convenienza per rendere la UI snella e leggibile
  double get totalExpenseToday => totals.today;
  double get totalExpenseWeek => totals.week;
  double get totalExpenseMonth => totals.month;
  double get totalExpenseYear => totals.year;
  List<ExpenseModel> get expensesUnmodifiable => List.unmodifiable(expenses);

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    ExpenseInitStatus? initStatus,
    Object? initError,
    String? errorMessage,
    String? warningMessage,
    bool? isLoading,
    ExpenseCurrency? appCurrency,
    ExpenseTotals? totals,
    bool clearError = false,
    bool clearWarning = false,
    bool clearInitError = false,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      initStatus: initStatus ?? this.initStatus,
      initError: clearInitError ? null : (initError ?? this.initError),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      warningMessage: clearWarning ? null : (warningMessage ?? this.warningMessage),
      isLoading: isLoading ?? this.isLoading,
      appCurrency: appCurrency ?? this.appCurrency,
      totals: totals ?? this.totals,
    );
  }
}

// --- NOTIFIER (RIVERPOD) ---
class ExpenseNotifier extends Notifier<ExpenseState> {
  @override
  ExpenseState build() {
    return ExpenseState();
  }

  // Dipendenze lette a runtime tramite il BuildContext del container di Riverpod (ref)
  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);
  ExpenseService get _expenseService => ref.read(expenseServiceProvider);
  NotificationNotifier get _notificationNotifier => ref.read(notificationNotifierProvider.notifier);
  NotificationState get _notificationState => ref.read(notificationNotifierProvider);

  // --- HELPERS PRIVATI ---
  ExpenseTotals _refreshTotals(List<ExpenseModel> expenses, ExpenseCurrency currency) {
    return _expenseService.calculateTotals(expenses, currency);
  }

  // --- INIZIALIZZAZIONE ---
  Future<void> initialise() async {
    if (state.initStatus == ExpenseInitStatus.loading ||
        state.initStatus == ExpenseInitStatus.initialized) {
      return;
    }

    state = state.copyWith(
      initStatus: ExpenseInitStatus.loading,
      clearInitError: true,
    );

    try {
      final expenses = await _expenseService.loadUserExpenses(user: _auth.currentUser);
      final totals = _refreshTotals(expenses, state.appCurrency);
      
      state = state.copyWith(
        expenses: expenses,
        totals: totals,
        initStatus: ExpenseInitStatus.initialized,
      );
    } on RepositoryFailure catch (e) {
      state = state.copyWith(initError: e, initStatus: ExpenseInitStatus.error);
    } catch (e) {
      state = state.copyWith(
        initError: "Unknown error during startup: $e",
        initStatus: ExpenseInitStatus.error,
      );
    }
  }

  void clear() {
    state = ExpenseState();
  }

  void clearError() {
    state = state.copyWith(clearError: true, clearWarning: true);
  }

  // --- AGGIORNAMENTO VALUTA ---
  void updateAppCurrency(ExpenseCurrency newCurrency) {
    if (state.appCurrency == newCurrency) return;
    final totals = _refreshTotals(state.expenses, newCurrency);
    state = state.copyWith(appCurrency: newCurrency, totals: totals);
  }

  // --- SCRITTURA / CREAZIONE ---
  Future<void> createExpense({
    required double value,
    required String? description,
    required DateTime date,
    required AppLocalizations l10n,
    required ExpenseCurrency currencyCode,
    required ExpenseCategory category,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearWarning: true,
    );

    try {
      final result = await _expenseService.createExpense(
        value: value,
        description: description,
        date: date,
        currency: currencyCode,
        category: category,
        user: _auth.currentUser,
      );

      final updatedExpenses = _expenseService.sortExpenses(
        [...state.expenses, result.expense],
        "date_desc",
        null,
      );
      final totals = _refreshTotals(updatedExpenses, state.appCurrency);

      state = state.copyWith(
        expenses: updatedExpenses,
        totals: totals,
        warningMessage: result.warning != null ? l10n.warningOfflineCurrencyCreate : null,
      );

      await _checkBudget(dateToCheck: date, l10n: l10n);
    } on RepositoryFailure catch (e) {
      state = state.copyWith(errorMessage: "Save failed: ${e.message}");
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // --- AGGIORNAMENTO / MODIFICA ---
  Future<void> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
    required ExpenseCurrency currencyCode,
    required AppLocalizations l10n,
    required ExpenseCategory category,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearWarning: true,
    );

    try {
      final result = await _expenseService.editExpense(
        expenseModel,
        value: value,
        description: description,
        date: date,
        currency: currencyCode,
        category: category,
        user: _auth.currentUser,
      );

      final updatedExpenses = List<ExpenseModel>.from(state.expenses);
      final index = updatedExpenses.indexWhere((e) => e.uuid == expenseModel.uuid);
      
      if (index != -1) {
        updatedExpenses[index] = result.expense;
      } else {
        debugPrint('⚠️ Warning: Expense ${expenseModel.uuid} not found in list');
        updatedExpenses.add(result.expense);
      }

      final sorted = _expenseService.sortExpenses(updatedExpenses, "date_desc", null);
      final totals = _refreshTotals(sorted, state.appCurrency);

      state = state.copyWith(
        expenses: sorted,
        totals: totals,
        warningMessage: result.warning != null ? l10n.warningOfflineCurrencyEdit : null,
      );

      await _checkBudget(dateToCheck: date, l10n: l10n);
    } on RepositoryFailure catch (e) {
      state = state.copyWith(errorMessage: "Edit failed: ${e.message}");
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // --- RIMOZIONE BATCH / SINGOLA ---
  Future<void> deleteExpenses(List<ExpenseModel> expensesToDelete) async {
    if (expensesToDelete.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    final user = _auth.currentUser;

    try {
      final results = await Future.wait(
        expensesToDelete.map(
          (e) => _expenseService
              .deleteExpense(e, user: user)
              .then((_) => (expense: e, error: null as Object?))
              .catchError((err) => (expense: e, error: err as Object?)),
        ),
        eagerError: false,
      );

      final succeeded = results.where((r) => r.error == null).map((r) => r.expense).toList();
      final failed = results.where((r) => r.error != null).toList();

      if (succeeded.isNotEmpty) {
        final idsRemoved = succeeded.map((e) => e.uuid).toSet();
        final updatedExpenses = state.expenses.where((e) => !idsRemoved.contains(e.uuid)).toList();
        final totals = _refreshTotals(updatedExpenses, state.appCurrency);
        
        state = state.copyWith(expenses: updatedExpenses, totals: totals);
      }

      if (failed.isNotEmpty) {
        state = state.copyWith(
          errorMessage: "Deletion failed for ${failed.length} of ${expensesToDelete.length} expenses.",
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: "Unexpected error during deletion: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // --- RIPRISTINO BATCH / SINGOLO ---
  Future<void> restoreExpenses(List<ExpenseModel> expensesToRestore, AppLocalizations l10n) async {
    if (expensesToRestore.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    final user = _auth.currentUser;

    try {
      final results = await Future.wait(
        expensesToRestore.map(
          (e) => _expenseService
              .restoreExpense(e, user: user)
              .then((restored) => (expense: restored, error: null as Object?))
              .catchError((err) => (expense: e, error: err as Object?)),
        ),
        eagerError: false,
      );

      final succeeded = results.where((r) => r.error == null).map((r) => r.expense).toList();
      final failed = results.where((r) => r.error != null).toList();

      if (succeeded.isNotEmpty) {
        final updatedExpenses = _expenseService.sortExpenses(
          [...state.expenses, ...succeeded],
          "date_desc",
          null,
        );
        final totals = _refreshTotals(updatedExpenses, state.appCurrency);
        
        state = state.copyWith(expenses: updatedExpenses, totals: totals);
        await _checkBudgetForList(succeeded, l10n);
      }

      if (failed.isNotEmpty) {
        state = state.copyWith(
          errorMessage: "Restore failed for ${failed.length} of ${expensesToRestore.length} expenses.",
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: "Unexpected error during restore: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // --- VERIFICA SOGLIE BUDGET ---
  Future<void> _checkBudget({
    required DateTime dateToCheck,
    required AppLocalizations l10n,
  }) async {
    final result = _expenseService.checkBudgetStatus(
      expenses: state.expenses,
      expenseDate: dateToCheck,
      targetCurrency: state.appCurrency,
      budgetLimit: _notificationState.monthlyLimit,
      alertEnabled: _notificationState.limitAlertEnabled,
    );

    if (result.shouldNotify) {
      await _notificationNotifier.checkBudgetLimit(
        currentMonthlySpent: result.currentTotal,
        l10n: l10n,
        currencySymbol: state.appCurrency.symbol,
      );
    }
  }

  Future<void> _checkBudgetForList(List<ExpenseModel> expenses, AppLocalizations l10n) async {
    final result = _expenseService.checkBudgetStatusForList(
      allExpenses: state.expenses,
      newExpenses: expenses,
      targetCurrency: state.appCurrency,
      budgetLimit: _notificationState.monthlyLimit,
      alertEnabled: _notificationState.limitAlertEnabled,
    );

    if (result.shouldNotify) {
      await _notificationNotifier.checkBudgetLimit(
        currentMonthlySpent: result.currentTotal,
        l10n: l10n,
        currencySymbol: state.appCurrency.symbol,
      );
    }
  }

  // --- ORDINAMENTO ELEMENTI ---
  void sortBy(String criteria) {
    final targetCurrency = criteria.contains("amount") ? state.appCurrency : null;
    final sorted = _expenseService.sortExpenses(state.expenses, criteria, targetCurrency);
    state = state.copyWith(expenses: sorted);
  }
}