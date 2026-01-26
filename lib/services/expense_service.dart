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
/// Questo servizio è completamente indipendente dalla UI e può essere testato isolatamente.

class ExpenseService {
  // --- STATO E DIPENDENZE ---
  // Iniezione delle dipendenze per accesso ai dati, autenticazione e gestione valute.
  
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
  // Carica tutte le spese dell'utente corrente dal repository.
  // Le spese vengono ordinate per data di creazione (più recenti prima).
  Future<List<ExpenseModel>> loadUserExpenses() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return [];

    final expenses = await _firebaseRepository.allExpensesForUser(user.uid);
    expenses.sort((a, b) => b.createdOn.compareTo(a.createdOn));
    return expenses;
  }

  // --- CREAZIONE CON SOFT-FAIL STRATEGY ---
  // Business Logic: Gestisce il recupero dei tassi di cambio con fallback 1:1.
  // Se il recupero dei tassi fallisce (es. offline), usa un tasso 1:1 e ritorna un warning.
  // Questo permette all'utente di creare spese anche senza connessione, con conversioni
  // che verranno corrette al prossimo edit quando la connessione sarà disponibile.
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
    // Tenta di recuperare i tassi reali, ma non blocca l'operazione se fallisce.
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
  // Business Logic: Ripara automaticamente i tassi di cambio "rotti" (fallback 1:1).
  // Durante la modifica, se i tassi erano fallback (lunghezza <= 1), tenta di recuperare
  // quelli reali. Questo permette di correggere spese create offline quando si torna online.
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
    // Rileva se i tassi sono "rotti" (creati offline) e tenta di ripararli.
    bool areRatesBroken = expenseModel.exchangeRates.length <= 1;

    if (areRatesBroken) {
      try {
        debugPrint("Repairing broken rates...");
        exchangeRates = await _currencyService.getExchangeRates(currency);
        debugPrint("Rates repaired successfully.");
      } on CurrencyFetchException {
        debugPrint("Repair failed. Still offline.");
        // Mantiene il fallback esistente se il repair fallisce
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
  // Ripristina una spesa precedentemente eliminata ricreandola nel repository.
  // Verifica i permessi per garantire che solo il proprietario possa ripristinare.
  Future<ExpenseModel> restoreExpense(ExpenseModel expenseModel) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw RepositoryFailure("User not authenticated.");

    if (expenseModel.userId != user.uid) {
      throw RepositoryFailure("Cannot restore another user's expense");
    }

    await _firebaseRepository.createExpense(expenseModel);
    return expenseModel;
  }

  // Elimina permanentemente una spesa dal repository.
  // Verifica i permessi per garantire che solo il proprietario possa eliminare.
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
  // Calcola i totali delle spese per diversi periodi temporali.
  // Tutti gli importi vengono convertiti nella valuta target per aggregazione corretta.
  // Delegato a ExpenseCalculator per separazione delle responsabilità.
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
  // Verifica se il budget mensile deve generare un alert per una singola spesa.
  // BUSINESS LOGIC: include controlli temporali (solo mese corrente),
  // verifica del limite e dello stato di abilitazione degli alert.
  BudgetCheckResult checkBudgetStatus({
    required List<ExpenseModel> expenses,
    required DateTime expenseDate,
    required String targetCurrency,
    required double budgetLimit,
    required bool alertEnabled,
  }) {
    // Regola 1: Se alert disabilitato, non notificare mai
    if (!alertEnabled) {
      return BudgetCheckResult(shouldNotify: false, currentTotal: 0);
    }

    final now = DateTime.now();

    // Regola 2: Notifica solo se la spesa appartiene al mese corrente
    // (spese passate/future non devono innescare notifiche)
    if (expenseDate.month != now.month || expenseDate.year != now.year) {
      return BudgetCheckResult(shouldNotify: false, currentTotal: 0);
    }

    // Regola 3: Calcola totale mensile e verifica se supera il limite
    final monthTotal = ExpenseCalculator.totalExpenseMonth(
      expenses,
      targetCurrency,
    );

    return BudgetCheckResult(
      shouldNotify: monthTotal >= budgetLimit,
      currentTotal: monthTotal,
    );
  }

  // Verifica se il budget mensile deve generare un alert per un gruppo di spese.
  // BUSINESS LOGIC: utilizzato durante il ripristino multiplo di spese.
  // Notifica solo se almeno una spesa ripristinata appartiene al mese corrente.
  BudgetCheckResult checkBudgetStatusForList({
    required List<ExpenseModel> allExpenses,
    required List<ExpenseModel> newExpenses,
    required String targetCurrency,
    required double budgetLimit,
    required bool alertEnabled,
  }) {
    // Regola 1: Se alert disabilitato, non notificare mai
    if (!alertEnabled) {
      return BudgetCheckResult(shouldNotify: false, currentTotal: 0);
    }

    final now = DateTime.now();

    // Regola 2: Verifica se almeno una spesa del gruppo è del mese corrente
    final hasCurrentMonthExpense = newExpenses.any(
      (e) => e.createdOn.month == now.month && e.createdOn.year == now.year,
    );

    if (!hasCurrentMonthExpense) {
      return BudgetCheckResult(shouldNotify: false, currentTotal: 0);
    }

    // Regola 3: Calcola totale mensile e verifica se supera il limite
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
  // Ordina le spese secondo il criterio specificato (data, importo, descrizione).
  // RESTITUISCE una nuova lista ordinata (non muta l'originale) per garantire immutabilità.
  // La targetCurrency è necessaria solo per ordinamento per importo (conversione).
  List<ExpenseModel> sortExpenses(
    List<ExpenseModel> expenses,
    String criteria,
    String? targetCurrency,
  ) {
    // Crea una copia per non mutare l'originale
    final sorted = List<ExpenseModel>.from(expenses);

    // Delega l'ordinamento effettivo a ExpenseCalculator
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
  // Le seguenti funzioni forniscono dati aggregati per la visualizzazione grafica.
  // Tutti i calcoli sono delegati a ExpenseCalculator per mantenere questo servizio
  // focalizzato sull'orchestrazione delle operazioni.

  // Aggregazione per grafici mensili (anno corrente).
  // Restituisce una mappa mese -> totale spese convertite nella valuta target.
  Map<String, double> getExpensesByMonth(
    List<ExpenseModel> expenses,
    String targetCurrency,
  ) {
    return ExpenseCalculator.expensesByMonth(expenses, targetCurrency);
  }

  // Aggregazione per grafici giornalieri di un mese specifico.
  // Restituisce una mappa giorno -> totale spese convertite nella valuta target.
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

  // Filtra e restituisce tutte le spese di un giorno specifico.
  // Utile per mostrare i dettagli quando l'utente clicca su una barra del grafico.
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
// Oggetti di risultato per comunicare sia il successo che eventuali warning
// dalle operazioni del servizio al provider/UI.

// Risultato dell'operazione di creazione spesa.
// Include la spesa creata e un eventuale warning se creata offline.
class CreateExpenseResult {
  final ExpenseModel expense;
  final String? warning; // null se tutto OK, codice stringa se offline

  CreateExpenseResult({required this.expense, this.warning});
}

// Risultato dell'operazione di modifica spesa.
// Include la spesa aggiornata e un eventuale warning se modificata offline.
class EditExpenseResult {
  final ExpenseModel expense;
  final String? warning;

  EditExpenseResult({required this.expense, this.warning});
}

// Oggetto contenente i totali delle spese per diversi periodi temporali.
// Utilizzato per evitare ricalcoli ripetuti e mantenere la cache sincronizzata.
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

// Risultato della verifica budget.
// Indica se deve essere mostrata una notifica e il totale corrente.
class BudgetCheckResult {
  final bool shouldNotify;
  final double currentTotal;

  BudgetCheckResult({required this.shouldNotify, required this.currentTotal});
}