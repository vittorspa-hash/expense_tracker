import 'dart:async';
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

/// FILE: expense_notifier.dart
/// DESCRIZIONE: Gestore dello stato delle spese (ExpenseState).
/// Utilizza AsyncNotifier perché la build() esegue operazioni asincrone (caricamento
/// spese e calcolo totali). Osserva l'utente corrente tramite authNotifierProvider:
/// al cambio di autenticazione la build() viene rieseguita automaticamente da Riverpod.
/// Le operazioni CRUD preservano lo stato esistente tramite AsyncData(state.value!.copyWith(...))
/// per evitare che la UI mostri uno stato di caricamento globale durante le modifiche locali.

// --- STATO IMMUTABILE ---
class ExpenseState {
  final List<ExpenseModel> expenses;
  final String? errorMessage;
  final String? warningMessage;
  final bool isLoading; // Gestisce i caricamenti locali delle operazioni CRUD
  final ExpenseCurrency appCurrency;
  final ExpenseTotals totals;

  ExpenseState({
    this.expenses = const [],
    this.errorMessage,
    this.warningMessage,
    this.isLoading = false,
    this.appCurrency = ExpenseCurrency.euro,
    ExpenseTotals? totals,
  }) : totals = totals ?? ExpenseTotals(today: 0, week: 0, month: 0, year: 0);

  double get totalExpenseToday => totals.today;
  double get totalExpenseWeek => totals.week;
  double get totalExpenseMonth => totals.month;
  double get totalExpenseYear => totals.year;

  List<ExpenseModel> get expensesUnmodifiable => List.unmodifiable(expenses);

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    String? errorMessage,
    String? warningMessage,
    bool? isLoading,
    ExpenseCurrency? appCurrency,
    ExpenseTotals? totals,
    bool clearError = false,
    bool clearWarning = false,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      warningMessage: clearWarning ? null : (warningMessage ?? this.warningMessage),
      isLoading: isLoading ?? this.isLoading,
      appCurrency: appCurrency ?? this.appCurrency,
      totals: totals ?? this.totals,
    );
  }
}

// --- NOTIFIER ---
/// AsyncNotifier che si riscrive automaticamente al cambio di utente autenticato.
/// Le dipendenze sono lette tramite getter che usano ref.read, in quanto vengono
/// accedute esclusivamente nelle azioni, mai durante il ciclo di build.
class ExpenseNotifier extends AsyncNotifier<ExpenseState> {
  @override
  Future<ExpenseState> build() async {
    // Osserva l'uid corrente: se cambia, build() viene rieseguito automaticamente
    final user = ref.watch(authNotifierProvider.select((s) => s.value?.user));
    final appCurrency = ref.read(currencyNotifierProvider).currentCurrency;
    final expenses = await _expenseService.loadUserExpenses(user: user);
    final totals = await _refreshTotals(expenses, appCurrency);
    return ExpenseState(
      expenses: expenses,
      totals: totals,
      appCurrency: appCurrency,
    );
  }

  // --- DIPENDENZE ---
  User? get _currentUser => ref.read(authNotifierProvider).value?.user;
  ExpenseService get _expenseService => ref.read(expenseServiceProvider);
  NotificationNotifier get _notificationNotifier =>
      ref.read(notificationNotifierProvider.notifier);
  NotificationState get _notificationState => ref.read(notificationNotifierProvider);

  // --- HELPERS PRIVATI ---
  /// Ricalcola i totali delle spese nella valuta specificata tramite ExpenseService.
  Future<ExpenseTotals> _refreshTotals(
    List<ExpenseModel> expenses,
    ExpenseCurrency currency,
  ) async {
    final service = _expenseService;
    return service.calculateTotals(expenses, currency);
  }

  /// Azzera i messaggi di errore e warning dallo stato corrente.
  void clearError() {
    if (state.hasValue) {
      state = AsyncData(
        state.value!.copyWith(clearError: true, clearWarning: true),
      );
    }
  }

  // --- AGGIORNAMENTO VALUTA ---
  /// Ricalcola i totali nella nuova valuta e aggiorna lo stato senza ricaricare le spese.
  Future<void> updateAppCurrency(ExpenseCurrency newCurrency) async {
    if (!state.hasValue) return;
    final currentState = state.value!;
    if (currentState.appCurrency == newCurrency) return;
    final totals = await _refreshTotals(currentState.expenses, newCurrency);
    state = AsyncData(
      currentState.copyWith(appCurrency: newCurrency, totals: totals),
    );
  }

  // --- CREAZIONE ---
  /// Crea una nuova spesa, aggiorna la lista ordinata e i totali, poi verifica
  /// il superamento del budget per il mese della data inserita.
  Future<void> createExpense({
    required double value,
    required String? description,
    required DateTime date,
    required AppLocalizations l10n,
    required ExpenseCurrency currencyCode,
    required ExpenseCategory category,
  }) async {
    if (!state.hasValue) return;
    final currentState = state.value!;
    state = AsyncData(
      currentState.copyWith(
        isLoading: true,
        clearError: true,
        clearWarning: true,
      ),
    );
    try {
      final service = _expenseService;
      final result = await service.createExpense(
        value: value,
        description: description,
        date: date,
        currency: currencyCode,
        category: category,
        user: _currentUser,
      );
      final updatedExpenses = service.sortExpenses(
        [...currentState.expenses, result.expense],
        "date_desc",
        null,
      );
      final totals = await _refreshTotals(updatedExpenses, currentState.appCurrency);
      state = AsyncData(
        currentState.copyWith(
          expenses: updatedExpenses,
          totals: totals,
          isLoading: false,
          warningMessage: result.warning != null ? l10n.warningOfflineCurrencyCreate : null,
        ),
      );
      await _checkBudget(dateToCheck: date, l10n: l10n);
    } on RepositoryFailure catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          errorMessage: "Save failed: ${e.message}",
          isLoading: false,
        ),
      );
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(errorMessage: e.toString(), isLoading: false),
      );
    }
  }

  // --- MODIFICA ---
  /// Aggiorna una spesa esistente in lista (con fallback ad append se non trovata),
  /// ricalcola i totali e verifica il budget per il mese della nuova data.
  Future<void> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
    required ExpenseCurrency currencyCode,
    required AppLocalizations l10n,
    required ExpenseCategory category,
  }) async {
    if (!state.hasValue) return;
    final currentState = state.value!;
    state = AsyncData(
      currentState.copyWith(
        isLoading: true,
        clearError: true,
        clearWarning: true,
      ),
    );
    try {
      final service = _expenseService;
      final result = await service.editExpense(
        expenseModel,
        value: value,
        description: description,
        date: date,
        currency: currencyCode,
        category: category,
        user: _currentUser,
      );
      final updatedExpenses = List<ExpenseModel>.from(currentState.expenses);
      final index = updatedExpenses.indexWhere((e) => e.uuid == expenseModel.uuid);
      if (index != -1) {
        updatedExpenses[index] = result.expense;
      } else {
        debugPrint('⚠️ Warning: Expense ${expenseModel.uuid} not found in list');
        updatedExpenses.add(result.expense);
      }
      final sorted = service.sortExpenses(updatedExpenses, "date_desc", null);
      final totals = await _refreshTotals(sorted, currentState.appCurrency);
      state = AsyncData(
        currentState.copyWith(
          expenses: sorted,
          totals: totals,
          isLoading: false,
          warningMessage: result.warning != null ? l10n.warningOfflineCurrencyEdit : null,
        ),
      );
      await _checkBudget(dateToCheck: date, l10n: l10n);
    } on RepositoryFailure catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          errorMessage: "Edit failed: ${e.message}",
          isLoading: false,
        ),
      );
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(errorMessage: e.toString(), isLoading: false),
      );
    }
  }

  // --- ELIMINAZIONE ---
  /// Elimina in parallelo le spese selezionate tramite Future.wait con eagerError: false,
  /// aggiornando lo stato con i soli successi e segnalando i fallimenti parziali.
  Future<void> deleteExpenses(List<ExpenseModel> expensesToDelete) async {
    if (expensesToDelete.isEmpty || !state.hasValue) return;
    final currentState = state.value!;
    state = AsyncData(currentState.copyWith(isLoading: true, clearError: true));
    final user = _currentUser;
    final service = _expenseService;
    try {
      final results = await Future.wait(
        expensesToDelete.map(
          (e) => service
              .deleteExpense(e, user: user)
              .then((_) => (expense: e, error: null as Object?))
              .catchError((err) => (expense: e, error: err as Object?)),
        ),
        eagerError: false,
      );
      final succeeded = results.where((r) => r.error == null).map((r) => r.expense).toList();
      final failed = results.where((r) => r.error != null).toList();
      var updatedState = state.value!;
      if (succeeded.isNotEmpty) {
        final idsRemoved = succeeded.map((e) => e.uuid).toSet();
        final updatedExpenses = updatedState.expenses
            .where((e) => !idsRemoved.contains(e.uuid))
            .toList();
        final totals = await _refreshTotals(updatedExpenses, updatedState.appCurrency);
        updatedState = updatedState.copyWith(expenses: updatedExpenses, totals: totals);
      }
      if (failed.isNotEmpty) {
        updatedState = updatedState.copyWith(
          errorMessage: "Deletion failed for ${failed.length} of ${expensesToDelete.length} expenses.",
        );
      }
      state = AsyncData(updatedState.copyWith(isLoading: false));
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          errorMessage: "Unexpected error during deletion: $e",
          isLoading: false,
        ),
      );
    }
  }

  // --- RIPRISTINO ---
  /// Ripristina in parallelo le spese eliminate tramite Future.wait con eagerError: false,
  /// aggiornando lo stato con i soli successi, ricalcolando i totali e verificando il budget.
  Future<void> restoreExpenses(
    List<ExpenseModel> expensesToRestore,
    AppLocalizations l10n,
  ) async {
    if (expensesToRestore.isEmpty || !state.hasValue) return;
    final currentState = state.value!;
    state = AsyncData(currentState.copyWith(isLoading: true, clearError: true));
    final user = _currentUser;
    final service = _expenseService;
    try {
      final results = await Future.wait(
        expensesToRestore.map(
          (e) => service
              .restoreExpense(e, user: user)
              .then((restored) => (expense: restored, error: null as Object?))
              .catchError((err) => (expense: e, error: err as Object?)),
        ),
        eagerError: false,
      );
      final succeeded = results.where((r) => r.error == null).map((r) => r.expense).toList();
      final failed = results.where((r) => r.error != null).toList();
      var updatedState = state.value!;
      if (succeeded.isNotEmpty) {
        final updatedExpenses = service.sortExpenses(
          [...updatedState.expenses, ...succeeded],
          "date_desc",
          null,
        );
        final totals = await _refreshTotals(updatedExpenses, updatedState.appCurrency);
        updatedState = updatedState.copyWith(expenses: updatedExpenses, totals: totals);
        state = AsyncData(updatedState);
        await _checkBudgetForList(succeeded, l10n);
      }
      if (failed.isNotEmpty) {
        state = AsyncData(
          updatedState.copyWith(
            errorMessage: "Restore failed for ${failed.length} of ${expensesToRestore.length} expenses.",
            isLoading: false,
          ),
        );
      } else {
        state = AsyncData(updatedState.copyWith(isLoading: false));
      }
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          errorMessage: "Unexpected error during restore: $e",
          isLoading: false,
        ),
      );
    }
  }

  // --- VERIFICA BUDGET ---
  /// Controlla se la spesa del mese della data indicata supera il limite impostato
  /// e, se necessario, delega la notifica a NotificationNotifier.
  Future<void> _checkBudget({
    required DateTime dateToCheck,
    required AppLocalizations l10n,
  }) async {
    if (!state.hasValue) return;
    final service = _expenseService;
    final notifState = _notificationState;
    final result = service.checkBudgetStatus(
      expenses: state.value!.expenses,
      expenseDate: dateToCheck,
      targetCurrency: state.value!.appCurrency,
      budgetLimit: notifState.monthlyLimit,
      alertEnabled: notifState.limitAlertEnabled,
    );
    if (result.shouldNotify) {
      await _notificationNotifier.checkBudgetLimit(
        currentMonthlySpent: result.currentTotal,
        l10n: l10n,
        currencySymbol: state.value!.appCurrency.symbol,
      );
    }
  }

  /// Variante di _checkBudget per operazioni su liste di spese (es. restore multiplo):
  /// verifica il budget considerando l'insieme delle spese appena ripristinate.
  Future<void> _checkBudgetForList(
    List<ExpenseModel> expenses,
    AppLocalizations l10n,
  ) async {
    if (!state.hasValue) return;
    final service = _expenseService;
    final notifState = _notificationState;
    final result = service.checkBudgetStatusForList(
      allExpenses: state.value!.expenses,
      newExpenses: expenses,
      targetCurrency: state.value!.appCurrency,
      budgetLimit: notifState.monthlyLimit,
      alertEnabled: notifState.limitAlertEnabled,
    );
    if (result.shouldNotify) {
      await _notificationNotifier.checkBudgetLimit(
        currentMonthlySpent: result.currentTotal,
        l10n: l10n,
        currencySymbol: state.value!.appCurrency.symbol,
      );
    }
  }

  // --- ORDINAMENTO ---
  /// Riordina la lista in memoria secondo il criterio specificato, passando la valuta
  /// corrente solo per i criteri basati sull'importo.
  Future<void> sortBy(String criteria) async {
    if (!state.hasValue) return;
    final currentState = state.value!;
    final service = _expenseService;
    final targetCurrency = criteria.contains("amount") ? currentState.appCurrency : null;
    final sorted = service.sortExpenses(currentState.expenses, criteria, targetCurrency);
    state = AsyncData(currentState.copyWith(expenses: sorted));
  }
}