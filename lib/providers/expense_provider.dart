import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:flutter/foundation.dart';

/// FILE: expense_provider.dart
/// DESCRIZIONE: Gestore di stato principale (ChangeNotifier) per le spese.
/// Centralizza la logica di business collegando i servizi (Database, Valuta) alla UI.
/// Gestisce il ciclo di vita dei dati (CRUD), il calcolo dinamico dei totali
/// convertiti nella valuta dell'app e la verifica delle soglie di budget.

class ExpenseProvider extends ChangeNotifier {
  // --- DIPENDENZE ---
  final NotificationProvider _notificationProvider;
  final ExpenseService _expenseService;
  final CurrencyService _currencyService;

  ExpenseProvider({
    required NotificationProvider notificationProvider,
    required ExpenseService expenseService,
    required CurrencyService currencyService,
  }) : _notificationProvider = notificationProvider,
       _expenseService = expenseService,
       _currencyService = currencyService;

  // --- STATO DATI ---
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  // --- STATO UI (ERRORI & WARNING) ---
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _warningMessage;
  String? get warningMessage => _warningMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- STATO VALUTA ---
  // Mantiene la valuta di visualizzazione corrente ('EUR', 'USD', ecc.).
  // Fondamentale per convertire i totali visualizzati nella dashboard
  // indipendentemente dalla valuta originale delle singole transazioni.
  String _appCurrency = 'EUR';

  void clearError() {
    _errorMessage = null;
    _warningMessage = null;
    notifyListeners();
  }

  // --- CACHE TOTALI ---
  // Valori aggregati per prestazioni ottimali nella dashboard.
  double _todayTotal = 0.0;
  double _weekTotal = 0.0;
  double _monthTotal = 0.0;
  double _yearTotal = 0.0;

  double get totalExpenseToday => _todayTotal;
  double get totalExpenseWeek => _weekTotal;
  double get totalExpenseMonth => _monthTotal;
  double get totalExpenseYear => _yearTotal;

  // --- CALCOLO TOTALI ---
  // Ricalcola i totali aggregati delegando al calcolatore la conversione
  // nella valuta corrente dell'app (_appCurrency).
  void _refreshTotals() {
    _todayTotal = ExpenseCalculator.totalExpenseToday(_expenses, _appCurrency);
    _weekTotal = ExpenseCalculator.totalExpenseWeek(_expenses, _appCurrency);
    _monthTotal = ExpenseCalculator.totalExpenseMonth(_expenses, _appCurrency);
    _yearTotal = ExpenseCalculator.totalExpenseYear(_expenses, _appCurrency);
  }

  void _sortByDateDesc() {
    ExpenseCalculator.sortInPlace(_expenses, "date_desc");
  }

  // --- AGGIORNAMENTO VALUTA APP ---
  // Da chiamare quando l'utente cambia la valuta nelle impostazioni.
  // Forza un ricalcolo immediato di tutti i totali visualizzati.
  void updateAppCurrency(String newCurrencyCode) {
    if (_appCurrency != newCurrencyCode) {
      _appCurrency = newCurrencyCode;
      _refreshTotals();
      notifyListeners();
    }
  }

  // --- INIZIALIZZAZIONE ---
  // Carica le spese dal repository persistente all'avvio e calcola i totali iniziali.
  Future<void> initialise() async {
    _errorMessage = null;
    try {
      _expenses = await _expenseService.loadUserExpenses();

      // Nota: La valuta iniziale viene impostata esternamente o è di default.
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

  // --- CREAZIONE NUOVA SPESA ---
  // Implementa la strategia "Soft Fail" per la valuta:
  // 1. Tenta di scaricare i tassi di cambio.
  // 2. Se fallisce (offline/errore), usa il fallback 1:1 e imposta un warning.
  // 3. Salva comunque la spesa nel database.
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
      Map<String, double> exchangeRates;

      // BLOCCO RECUPERO TASSI (SOFT FAIL)
      try {
        exchangeRates = await _currencyService.getExchangeRates(currencyCode);
      } on CurrencyFetchException {
        // Se il recupero fallisce, non blocchiamo l'utente.
        // Usiamo tassi 1:1 e avvisiamo che la conversione non è disponibile.
        debugPrint("Currency fetch failed. Using fallback 1:1.");
        exchangeRates = {currencyCode: 1.0};
        _warningMessage = l10n.warningOfflineCurrencyCreate;
      }

      // Procediamo al salvataggio (con tassi reali o fallback)
      final expense = await _expenseService.createExpense(
        value: value,
        description: description,
        date: date,
        currency: currencyCode,
        exchangeRates: exchangeRates,
      );

      _expenses.add(expense);
      _sortByDateDesc();
      _refreshTotals();

      _checkBudget(
        dateToCheck: date,
        l10n: l10n,
        currencySymbol: currencySymbol,
      );
    } on RepositoryFailure catch (e) {
      // Gli errori del DB rimangono bloccanti (mostrano snackbar rossa)
      _errorMessage = "Save failed: ${e.message}";
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MODIFICA SPESA ---
  // Implementa la strategia "Smart Update":
  // 1. Se la spesa è "sana" (ha tutti i tassi), usa i dati storici (nessuna chiamata rete).
  // 2. Se la spesa è "rotta" (creata offline), tenta di scaricare i tassi per ripararla.
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
      // 1. Partiamo dai tassi che abbiamo già in memoria (Storici)
      Map<String, double> exchangeRates = expenseModel.exchangeRates;
      
      // 2. LOGICA DI RIPARAZIONE (Smart Update)
      // Scarichiamo nuovi tassi SOLO se quelli attuali sono incompleti (<= 1 elemento).
      bool areRatesBroken = expenseModel.exchangeRates.length <= 1;

      if (areRatesBroken) {
        try {
          debugPrint("Rates are broken (offline creation). Fetching new rates to repair...");
          
          // Tentativo di riparazione: scarichiamo la mappa completa
          exchangeRates = await _currencyService.getExchangeRates(currencyCode);
          
          debugPrint("Rates repaired successfully.");
          
        } on CurrencyFetchException {
          debugPrint("Repair failed. Still offline.");
          
          // Se la riparazione fallisce (ancora offline), manteniamo lo stato rotto.
          // Assicuriamo almeno il tasso 1:1 per la valuta corrente.
          if (exchangeRates.isEmpty || !exchangeRates.containsKey(currencyCode)) {
             exchangeRates = {currencyCode: 1.0};
          }
          
          // Reimpostiamo il warning (il triangolino rimarrà visibile)
          _warningMessage = l10n.warningOfflineCurrencyEdit;
        }
      }

      // 3. SALVATAGGIO
      await _expenseService.editExpense(
        expenseModel,
        value: value,
        description: description,
        date: date,
        currency: currencyCode, 
        exchangeRates: exchangeRates, // Mappa vecchia, nuova o riparata
      );

      _sortByDateDesc();
      _refreshTotals();
      
      _checkBudget(dateToCheck: date, l10n: l10n, currencySymbol: currencySymbol);

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
  // Rimuove le spese selezionate e aggiorna i totali.
  Future<void> deleteExpenses(List<ExpenseModel> expensesToDelete) async {
    if (expensesToDelete.isEmpty) return;
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
      _errorMessage = "Deletion failed. Data restored. (${e.message})";
    } catch (e) {
      _errorMessage = "Error deleting: $e";
    } finally {
      notifyListeners();
    }
  }

  // --- RIPRISTINO ---
  // Annulla l'eliminazione ripristinando le spese precedentemente rimosse.
  Future<void> restoreExpenses(
    List<ExpenseModel> expensesToRestore,
    AppLocalizations l10n,
    String currencySymbol,
  ) async {
    if (expensesToRestore.isEmpty) return;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait(
        expensesToRestore.map((e) => _expenseService.restoreExpense(e)),
      );

      _expenses.addAll(expensesToRestore);
      _sortByDateDesc();
      _refreshTotals();

      _checkBudgetForList(expensesToRestore, l10n, currencySymbol);
    } on RepositoryFailure catch (e) {
      _errorMessage = "Unable to restore expenses: ${e.message}";
    } catch (e) {
      _errorMessage = "Restore error: $e";
    } finally {
      notifyListeners();
    }
  }

  // --- VERIFICA BUDGET ---
  // Controlla se il totale mensile supera la soglia impostata nelle notifiche.
  // Utilizza il totale mensile convertito (_monthTotal).
  Future<void> _checkBudget({
    required DateTime dateToCheck,
    required AppLocalizations l10n,
    required String currencySymbol,
  }) async {
    final now = DateTime.now();
    if (dateToCheck.month != now.month || dateToCheck.year != now.year) return;

    if (_notificationProvider.limitAlertEnabled) {
      await _notificationProvider.checkBudgetLimit(
        _monthTotal,
        l10n,
        currencySymbol,
      );
    }
  }

  Future<void> _checkBudgetForList(
    List<ExpenseModel> expenses,
    AppLocalizations l10n,
    String currencySymbol,
  ) async {
    final now = DateTime.now();
    bool hasCurrentMonthExpense = expenses.any(
      (e) => e.createdOn.month == now.month && e.createdOn.year == now.year,
    );

    if (hasCurrentMonthExpense && _notificationProvider.limitAlertEnabled) {
      await _notificationProvider.checkBudgetLimit(
        _monthTotal,
        l10n,
        currencySymbol,
      );
    }
  }

  // --- ORDINAMENTO ---
  // Ordina la lista in memoria. Se l'ordinamento è per importo,
  // utilizza la valuta target (_appCurrency) per ordinare per valore reale.
  void sortBy(String criteria) {
    if (criteria.contains("amount")) {
      ExpenseCalculator.sortInPlace(
        _expenses,
        criteria,
        targetCurrency: _appCurrency,
      );
    } else {
      ExpenseCalculator.sortInPlace(_expenses, criteria);
    }
    notifyListeners();
  }

  // --- DATI PER GRAFICI ---
  // Espone i dati aggregati già normalizzati nella valuta dell'app
  // pronti per essere consumati dai widget dei grafici.

  Map<String, double> get expensesByMonth =>
      ExpenseCalculator.expensesByMonth(_expenses, _appCurrency);

  Map<String, double> expensesByDay(int year, int month) =>
      ExpenseCalculator.expensesByDay(_expenses, year, month, _appCurrency);

  List<ExpenseModel> expensesOfDay(int year, int month, int day) =>
      ExpenseCalculator.expensesOfDay(_expenses, year, month, day);
}