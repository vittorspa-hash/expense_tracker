import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// FILE: expense_provider.dart
/// DESCRIZIONE: State Manager per le spese (ChangeNotifier).
/// Gestisce ESCLUSIVAMENTE lo stato UI e orchestra le chiamate al service.
/// TUTTA la business logic (calcoli, ordinamenti, validazioni) è delegata a ExpenseService.
/// Questo provider si occupa solo di: coordinare le operazioni, gestire loading/errori,
/// e notificare i listener quando lo stato cambia.

enum ExpenseInitStatus { initial, loading, initialized, error }

class ExpenseProvider extends ChangeNotifier {
  // --- STATO E DIPENDENZE ---
  // Iniezione delle dipendenze per orchestrare operazioni tra expense e notifiche.

  final FirebaseAuth _firebaseAuth;
  final NotificationProvider _notificationProvider;
  final ExpenseService _expenseService;

  ExpenseProvider({
    required FirebaseAuth firebaseAuth,
    required NotificationProvider notificationProvider,
    required ExpenseService expenseService,
  }) : _firebaseAuth = firebaseAuth,
       _notificationProvider = notificationProvider,
       _expenseService = expenseService;

  // --- STATO ---
  // Lista delle spese e stato UI (loading, errori, warning).
  // Le spese sono esposte come lista immutabile per prevenire modifiche esterne.

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  // Gestione stato di inizializzazione
  ExpenseInitStatus _initStatus = ExpenseInitStatus.initial;
  ExpenseInitStatus get initStatus => _initStatus;

  // Errore specifico per la fase di inizializzazione
  Object? _initError;
  Object? get initError => _initError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _warningMessage;
  String? get warningMessage => _warningMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ExpenseCurrency _appCurrency = ExpenseCurrency.euro;
  ExpenseCurrency get appCurrency => _appCurrency;

  // Cache totali (calcolati dal service) per performance.
  // Evita ricalcoli ripetuti e garantisce che i totali siano sempre sincronizzati.
  ExpenseTotals _totals = ExpenseTotals(today: 0, week: 0, month: 0, year: 0);
  double get totalExpenseToday => _totals.today;
  double get totalExpenseWeek => _totals.week;
  double get totalExpenseMonth => _totals.month;
  double get totalExpenseYear => _totals.year;

  // --- INIZIALIZZAZIONE ---
  // Avvia il caricamento iniziale dei dati.
  // Gestisce internamente gli stati per aggiornare la UI in modo reattivo.
  Future<void> initialise() async {
    // Evitiamo chiamate multiple se è già in corso o completato
    if (_initStatus == ExpenseInitStatus.loading ||
        _initStatus == ExpenseInitStatus.initialized) {
      return;
    }

    _initStatus = ExpenseInitStatus.loading;
    _initError = null;
    notifyListeners();

    final user = _firebaseAuth.currentUser;

    try {
      _expenses = await _expenseService.loadUserExpenses(user: user);
      _refreshTotals();

      _initStatus = ExpenseInitStatus.initialized;
    } on RepositoryFailure catch (e) {
      _initError = e;
      _initStatus = ExpenseInitStatus.error;
    } catch (e) {
      _initError = "Unknown error during startup: $e";
      _initStatus = ExpenseInitStatus.error;
    } finally {
      notifyListeners();
    }
  }

  // Resetta completamente lo stato del provider.
  void clear() {
    _expenses = [];
    _errorMessage = null;
    _warningMessage = null;
    _initStatus = ExpenseInitStatus.initial;
    _initError = null;
    _refreshTotals();
    notifyListeners();
  }

  // Resetta messaggi di errore e warning.
  // Utile prima di operazioni nuove per mostrare solo errori recenti.
  void clearError() {
    _errorMessage = null;
    _warningMessage = null;
    notifyListeners();
  }

  // --- CALCOLO TOTALI (delega al service) ---
  // Aggiorna la cache dei totali delegando il calcolo al service.
  // Chiamato dopo ogni operazione che modifica la lista spese.
  void _refreshTotals() {
    _totals = _expenseService.calculateTotals(_expenses, _appCurrency);
  }

  // --- AGGIORNAMENTO VALUTA ---
  // Aggiorna la valuta dell'app e ricalcola i totali nella nuova valuta.
  // Evita notifiche superflue se la valuta non è cambiata.
  void updateAppCurrency(ExpenseCurrency newCurrency) {
    if (_appCurrency != newCurrency) {
      _appCurrency = newCurrency;
      _refreshTotals();
      notifyListeners();
    }
  }

  // --- CREAZIONE (delega al service) ---
  // Crea una nuova spesa delegando validazione e persistenza al service.
  // Gestisce warning per conversioni offline e orchestra la verifica budget.
  Future<void> createExpense({
    required double value,
    required String? description,
    required DateTime date,
    required AppLocalizations l10n,
    required ExpenseCurrency currencyCode,
    required ExpenseCategory category,
  }) async {
    _errorMessage = null;
    _warningMessage = null;
    _isLoading = true;
    notifyListeners();

    final user = _firebaseAuth.currentUser;

    try {
      // DELEGA LA BUSINESS LOGIC AL SERVICE
      final result = await _expenseService.createExpense(
        value: value,
        description: description,
        date: date,
        currency: currencyCode,
        category: category,
        user: user,
      );

      // Gestisce eventuali warning (es. conversione offline)
      if (result.warning != null) {
        _warningMessage = l10n.warningOfflineCurrencyCreate;
      }

      _expenses.add(result.expense);

      // RICEVI lista ordinata dal service (non muta più _expenses direttamente)
      _expenses = _expenseService.sortExpenses(_expenses, "date_desc", null);
      _refreshTotals();

      // Orchestrazione: verifica se il budget mensile è stato superato
      await _checkBudget(dateToCheck: date, l10n: l10n);
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
  // Modifica una spesa esistente delegando validazione e persistenza al service.
  // Sostituisce l'istanza modificata nella lista locale per garantire immutabilità.
  Future<void> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
    required ExpenseCurrency currencyCode,
    required AppLocalizations l10n,
    required ExpenseCategory category,
  }) async {
    _errorMessage = null;
    _warningMessage = null;
    _isLoading = true;
    notifyListeners();

    final user = _firebaseAuth.currentUser;

    try {
      // DELEGA LA BUSINESS LOGIC AL SERVICE
      final result = await _expenseService.editExpense(
        expenseModel,
        value: value,
        description: description,
        date: date,
        currency: currencyCode,
        category: category,
        user: user,
      );

      if (result.warning != null) {
        _warningMessage = l10n.warningOfflineCurrencyEdit;
      }

      // Sostituisce la vecchia istanza con quella aggiornata per garantire immutabilità
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

      // Orchestrazione: verifica budget dopo la modifica
      await _checkBudget(dateToCheck: date, l10n: l10n);
    } on RepositoryFailure catch (e) {
      _errorMessage = "Edit failed: ${e.message}";
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ELIMINAZIONE ---
  Future<void> deleteExpenses(List<ExpenseModel> expensesToDelete) async {
    if (expensesToDelete.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = _firebaseAuth.currentUser;

    try {
      // Raccogliamo i risultati di ogni singola operazione, senza interrompere al primo errore
      final results = await Future.wait(
        expensesToDelete.map(
          (e) => _expenseService
              .deleteExpense(e, user: user)
              .then((_) => (expense: e, error: null as Object?))
              .catchError((err) => (expense: e, error: err as Object?)),
        ),
        eagerError: false,
      );

      // Separiamo i successi dai fallimenti
      final succeeded = results
          .where((r) => r.error == null)
          .map((r) => r.expense)
          .toList();
      final failed = results.where((r) => r.error != null).toList();

      // Rimuoviamo dalla lista locale SOLO le spese effettivamente eliminate
      if (succeeded.isNotEmpty) {
        final idsRemoved = succeeded.map((e) => e.uuid).toSet();
        _expenses.removeWhere((e) => idsRemoved.contains(e.uuid));
        _refreshTotals();
      }

      // Notifichiamo l'utente degli eventuali fallimenti parziali
      if (failed.isNotEmpty) {
        _errorMessage =
            "Deletion failed for ${failed.length} of ${expensesToDelete.length} expenses.";
      }
    } catch (e) {
      // Catch residuale per errori imprevisti fuori da Future.wait
      _errorMessage = "Unexpected error during deletion: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- RIPRISTINO ---
  Future<void> restoreExpenses(
    List<ExpenseModel> expensesToRestore,
    AppLocalizations l10n,
  ) async {
    if (expensesToRestore.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = _firebaseAuth.currentUser;

    try {
      final results = await Future.wait(
        expensesToRestore.map(
          (e) => _expenseService
              .restoreExpense(e, user: user)
              .then((_) => (expense: e, error: null as Object?))
              .catchError((err) => (expense: e, error: err as Object?)),
        ),
        eagerError: false,
      );

      final succeeded = results
          .where((r) => r.error == null)
          .map((r) => r.expense)
          .toList();
      final failed = results.where((r) => r.error != null).toList();

      // Aggiungiamo alla lista locale SOLO le spese effettivamente ripristinate
      if (succeeded.isNotEmpty) {
        _expenses.addAll(succeeded);
        _expenses = _expenseService.sortExpenses(_expenses, "date_desc", null);
        _refreshTotals();

        await _checkBudgetForList(succeeded, l10n);
      }

      if (failed.isNotEmpty) {
        _errorMessage =
            "Restore failed for ${failed.length} of ${expensesToRestore.length} expenses.";
      }
    } catch (e) {
      _errorMessage = "Unexpected error during restore: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- VERIFICA BUDGET (orchestrazione pura, business logic nel service) ---
  // Orchestrazione: Delega la decisione al service, poi notifica se necessario.
  // Il service determina se il budget è stato superato, il provider notifica l'utente.
  Future<void> _checkBudget({
    required DateTime dateToCheck,
    required AppLocalizations l10n,
  }) async {
    // CORRETTO
    final currencySymbol = _appCurrency.symbol;
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

  // Orchestrazione: Verifica budget per un gruppo di spese ripristinate.
  // Utile quando si ripristinano più spese contemporaneamente.
  Future<void> _checkBudgetForList(
    List<ExpenseModel> expenses,
    AppLocalizations l10n,
  ) async {
    // CORRETTO
    final currencySymbol = _appCurrency.symbol;
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
  // Orchestrazione: Riceve lista ordinata dal service e aggiorna lo stato.
  // Il criterio può essere per data, importo, o descrizione.
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
  // Fornisce aggregazioni delle spese per i grafici della UI.
  // Tutti i calcoli sono delegati al service per mantenere la separazione di responsabilità.

  // Restituisce le spese aggregate per mese (anno corrente).
  Map<String, double> get expensesByMonth =>
      _expenseService.getExpensesByMonth(_expenses, _appCurrency);

  // Restituisce le spese aggregate per giorno di un mese specifico.
  Map<String, double> expensesByDay(int year, int month) =>
      _expenseService.getExpensesByDay(_expenses, year, month, _appCurrency);

  // Restituisce tutte le spese di un giorno specifico.
  List<ExpenseModel> expensesOfDay(int year, int month, int day) =>
      _expenseService.getExpensesOfDay(_expenses, year, month, day);

  // Restituisce le spese aggregate per categoria per un anno specifico.
  Map<ExpenseCategory, double> expensesByCategoryForYear(String year) =>
      _expenseService.getExpensesByCategoryForYear(
        _expenses,
        year,
        _appCurrency,
      );
}
