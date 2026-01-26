import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:flutter/foundation.dart';

/// FILE: expense_provider.dart
/// DESCRIZIONE: State Manager per le spese (ChangeNotifier).
/// Gestisce ESCLUSIVAMENTE lo stato UI e orchestra le chiamate al service.
/// TUTTA la business logic (calcoli, ordinamenti, validazioni) è delegata a ExpenseService.
/// Questo provider si occupa solo di: coordinare le operazioni, gestire loading/errori,
/// e notificare i listener quando lo stato cambia.

class ExpenseProvider extends ChangeNotifier {
  // --- STATO E DIPENDENZE ---
  // Iniezione delle dipendenze per orchestrare operazioni tra expense e notifiche.
  
  final NotificationProvider _notificationProvider;
  final ExpenseService _expenseService;

  ExpenseProvider({
    required NotificationProvider notificationProvider,
    required ExpenseService expenseService,
  }) : _notificationProvider = notificationProvider,
       _expenseService = expenseService;

  // --- STATO ---
  // Lista delle spese e stato UI (loading, errori, warning).
  // Le spese sono esposte come lista immutabile per prevenire modifiche esterne.
  
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _warningMessage;
  String? get warningMessage => _warningMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _appCurrency = 'EUR';

  // Cache totali (calcolati dal service) per performance.
  // Evita ricalcoli ripetuti e garantisce che i totali siano sempre sincronizzati.
  ExpenseTotals _totals = ExpenseTotals(today: 0, week: 0, month: 0, year: 0);
  double get totalExpenseToday => _totals.today;
  double get totalExpenseWeek => _totals.week;
  double get totalExpenseMonth => _totals.month;
  double get totalExpenseYear => _totals.year;

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
  void updateAppCurrency(String newCurrencyCode) {
    if (_appCurrency != newCurrencyCode) {
      _appCurrency = newCurrencyCode;
      _refreshTotals();
      notifyListeners();
    }
  }

  // --- INIZIALIZZAZIONE ---
  // Carica le spese dell'utente all'avvio dell'app.
  // Gestisce errori di repository e generici, impostando messaggi appropriati.
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

  // Resetta completamente lo stato del provider.
  // Utile durante logout o reset dell'applicazione.
  void clear() {
    _expenses = [];
    _errorMessage = null;
    _refreshTotals();
    notifyListeners();
  }

  // --- CREAZIONE (delega al service) ---
  // Crea una nuova spesa delegando validazione e persistenza al service.
  // Gestisce warning per conversioni offline e orchestra la verifica budget.
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

      // Gestisce eventuali warning (es. conversione offline)
      if (result.warning != null) {
        _warningMessage = l10n.warningOfflineCurrencyCreate;
      }

      _expenses.add(result.expense);

      // RICEVI lista ordinata dal service (non muta più _expenses direttamente)
      _expenses = _expenseService.sortExpenses(_expenses, "date_desc", null);
      _refreshTotals();

      // Orchestrazione: verifica se il budget mensile è stato superato
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
  // Modifica una spesa esistente delegando validazione e persistenza al service.
  // Sostituisce l'istanza modificata nella lista locale per garantire immutabilità.
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
  // Elimina un gruppo di spese in modo concorrente per performance.
  // Rimuove le spese dalla lista locale e aggiorna i totali.
  Future<void> deleteExpenses(List<ExpenseModel> expensesToDelete) async {
    if (expensesToDelete.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Elimina tutte le spese in parallelo per performance
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

  // Ripristina un gruppo di spese eliminate in modo concorrente.
  // Aggiunge le spese ripristinate, riordina la lista e verifica il budget.
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
      // Ripristina tutte le spese in parallelo per performance
      await Future.wait(
        expensesToRestore.map((e) => _expenseService.restoreExpense(e)),
      );

      _expenses.addAll(expensesToRestore);

      // RICEVI lista ordinata dal service
      _expenses = _expenseService.sortExpenses(_expenses, "date_desc", null);
      _refreshTotals();

      // Orchestrazione: verifica budget per le spese ripristinate
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
  // Orchestrazione: Delega la decisione al service, poi notifica se necessario.
  // Il service determina se il budget è stato superato, il provider notifica l'utente.
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

  // Orchestrazione: Verifica budget per un gruppo di spese ripristinate.
  // Utile quando si ripristinano più spese contemporaneamente.
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
}
