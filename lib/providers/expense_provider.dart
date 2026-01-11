import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:flutter/foundation.dart';

/// FILE: expense_provider.dart
/// DESCRIZIONE: State Manager per la gestione delle spese (ChangeNotifier).
/// Centralizza la logica di business per il CRUD delle spese, il calcolo dei totali
/// e l'integrazione con il sistema di notifiche per i limiti di budget.

class ExpenseProvider extends ChangeNotifier {
  // --- STATO E DIPENDENZE ---
  // Iniezione dei servizi necessari (Notifiche e API) e inizializzazione.
  final NotificationProvider _notificationProvider;
  final ExpenseService _expenseService;

  ExpenseProvider({
    required NotificationProvider notificationProvider,
    required ExpenseService expenseService,
  }) : _notificationProvider = notificationProvider,
       _expenseService = expenseService;

  // --- STATO DATI ---
  // Lista principale delle spese e getter protetto per evitare modifiche dirette dall'esterno.
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  // --- STATO ERRORI ---
  // Gestione centralizzata degli errori per mostrarli nella UI (es. SnackBar).
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Resetta lo stato di errore, utile quando l'utente chiude un avviso o riprova un'azione.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // --- CACHE TOTALI ---
  // Variabili per memorizzare i totali calcolati e ottimizzare le performance
  // evitando ricalcoli on-demand ad ogni accesso.
  double _todayTotal = 0.0;
  double _weekTotal = 0.0;
  double _monthTotal = 0.0;
  double _yearTotal = 0.0;

  double get totalExpenseToday => _todayTotal;
  double get totalExpenseWeek => _weekTotal;
  double get totalExpenseMonth => _monthTotal;
  double get totalExpenseYear => _yearTotal;

  // --- HELPER INTERNI ---
  // Ricalcola tutti i totali basandosi sulla lista corrente delle spese.
  void _refreshTotals() {
    _todayTotal = ExpenseCalculator.totalExpenseToday(_expenses);
    _weekTotal = ExpenseCalculator.totalExpenseWeek(_expenses);
    _monthTotal = ExpenseCalculator.totalExpenseMonth(_expenses);
    _yearTotal = ExpenseCalculator.totalExpenseYear(_expenses);
  }
  
  // Ordina la lista interna per data decrescente (comportamento di default).
  void _sortByDateDesc() {
    ExpenseCalculator.sortInPlace(_expenses, "date_desc");
  }

  // --- INIZIALIZZAZIONE ---
  // Carica le spese dell'utente all'avvio dell'applicazione.
  // Intercetta errori specifici (RepositoryFailure) rilanciandoli per la gestione nel wrapper.
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

  // Pulisce lo stato locale (es. al logout) per evitare dati residui.
  void clear() {
    _expenses = [];
    _errorMessage = null;
    _refreshTotals();
    notifyListeners();
  }

  // --- CREAZIONE & MODIFICA ---
  // Crea una nuova spesa gestendo persistenza remota, aggiornamento locale e verifica budget.
  // In caso di errore remoto, lo stato locale non viene alterato.
  Future<void> createExpense({
    required double value,
    required String? description,
    required DateTime date,
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
      
      _checkBudget(dateToCheck: date);

    } on RepositoryFailure catch (e) {
      _errorMessage = "Save failed: ${e.message}";
    } catch (e) {
      _errorMessage = e.toString(); 
    } finally {
      notifyListeners();
    }
  }

  // Modifica una spesa esistente, aggiornando ordinamento e totali dopo il successo del backend.
  Future<void> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
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
      _checkBudget(dateToCheck: date);

    } on RepositoryFailure catch (e) {
      _errorMessage = "Edit failed: ${e.message}";
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // --- ELIMINAZIONE UNIFICATA ---
  // Elimina una lista di spese (batch). Esegue le chiamate remote in parallelo
  // e aggiorna la UI solo se tutte le operazioni hanno successo.
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
  // Ripristina spese precedentemente eliminate (es. tasto "Annulla"), aggiornando remoto e locale.
  Future<void> restoreExpenses(List<ExpenseModel> expensesToRestore) async {
    if (expensesToRestore.isEmpty) return;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait(expensesToRestore.map((e) => _expenseService.restoreExpense(e)));

      _expenses.addAll(expensesToRestore);
      _sortByDateDesc(); 
      _refreshTotals();
      _checkBudgetForList(expensesToRestore);

    } on RepositoryFailure catch (e) {
      _errorMessage = "Unable to restore expenses: ${e.message}";
    } catch (e) {
      _errorMessage = "Restore error: $e";
    } finally {
      notifyListeners();
    }
  }

  // --- HELPER BUDGET & ORDINAMENTO ---
  // Verifica se una singola spesa impatta il budget del mese corrente e notifica se necessario.
  Future<void> _checkBudget({required DateTime dateToCheck}) async {
    final now = DateTime.now();
    if (dateToCheck.month != now.month || dateToCheck.year != now.year) return;

    if (_notificationProvider.limitAlertEnabled) {
      await _notificationProvider.checkBudgetLimit(_monthTotal);
    }
  }

  // Verifica se una lista di spese (es. ripristinate) impatta il budget del mese corrente.
  Future<void> _checkBudgetForList(List<ExpenseModel> expenses) async {
    final now = DateTime.now();
    bool hasCurrentMonthExpense = expenses.any((e) => 
      e.createdOn.month == now.month && e.createdOn.year == now.year
    );

    if (hasCurrentMonthExpense && _notificationProvider.limitAlertEnabled) {
      await _notificationProvider.checkBudgetLimit(_monthTotal);
    }
  }
  
  // Applica un criterio di ordinamento alla lista spese e notifica la UI.
  void sortBy(String criteria) {
    ExpenseCalculator.sortInPlace(_expenses, criteria);
    notifyListeners();
  }

  // Getter delegati al calcolatore per raggruppare le spese (per grafici o liste).
  Map<String, double> get expensesByMonth => ExpenseCalculator.expensesByMonth(_expenses);
  
  Map<String, double> expensesByDay(int year, int month) => 
      ExpenseCalculator.expensesByDay(_expenses, year, month);
  
  List<ExpenseModel> expensesOfDay(int year, int month, int day) => 
      ExpenseCalculator.expensesOfDay(_expenses, year, month, day);
}