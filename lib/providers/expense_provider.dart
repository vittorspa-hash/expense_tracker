import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:flutter/foundation.dart';

/// FILE: expense_provider.dart
/// DESCRIZIONE: Gestore di stato principale per le spese (State Management).
/// Agisce da "Brain" dell'applicazione collegando:
/// 1. UI (che ascolta i cambiamenti)
/// 2. Service (che parla con il Database/Firebase)
/// 3. Calculator (che esegue la matematica pura)
/// 4. NotificationProvider (per reagire ai cambiamenti di budget)

class ExpenseProvider extends ChangeNotifier {
  // --- DIPENDENZE ---
  // Iniezione delle dipendenze necessarie per la logica di business e le notifiche.
  final NotificationProvider _notificationProvider;
  final ExpenseService _expenseService;

  ExpenseProvider({
    required NotificationProvider notificationProvider,
    required ExpenseService expenseService,
  }) : _notificationProvider = notificationProvider,
       _expenseService = expenseService;

  // --- STATO ---
  // La lista principale delle spese (Private) e il getter pubblico immutabile.
  // 
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  // --- CACHE DEI TOTALI (Performance Boost) ---
  // Strategia di ottimizzazione: Invece di ricalcolare i totali (O(N)) ogni volta
  // che la UI li richiede, li calcoliamo una volta sola quando i dati cambiano
  // e li salviamo in variabili (O(1) in lettura).
  // 
  double _todayTotal = 0.0;
  double _weekTotal = 0.0;
  double _monthTotal = 0.0;
  double _yearTotal = 0.0;

  double get totalExpenseToday => _todayTotal;
  double get totalExpenseWeek => _weekTotal;
  double get totalExpenseMonth => _monthTotal;
  double get totalExpenseYear => _yearTotal;

  // Aggiorna tutti i totali in cache. Chiamato dopo ogni modifica (CRUD).
  void _refreshTotals() {
    _todayTotal = ExpenseCalculator.totalExpenseToday(_expenses);
    _weekTotal = ExpenseCalculator.totalExpenseWeek(_expenses);
    _monthTotal = ExpenseCalculator.totalExpenseMonth(_expenses);
    _yearTotal = ExpenseCalculator.totalExpenseYear(_expenses);
  }

  // --- INIZIALIZZAZIONE ---
  // Carica i dati dal servizio, calcola i totali iniziali e notifica la UI.
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

  // --- OPERAZIONI CRUD ---
  // Metodi per Creare, Ripristinare, Modificare ed Eliminare le spese.
  // Ogni operazione segue il pattern:
  // 1. Chiamata al Service (Async).
  // 2. Aggiornamento lista locale.
  // 3. Refresh Cache Totali.
  // 4. Notifica Listeners.
  // 5. Controllo Budget (Interazione con NotificationProvider).
  // 

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
    _sortByDateDesc(); 

    _refreshTotals();
    notifyListeners();

    if (_notificationProvider.limitAlertEnabled) {
      await _notificationProvider.checkBudgetLimit(_monthTotal);
    }
  }

  Future<void> restoreExpense(ExpenseModel expenseModel) async {
    final expense = await _expenseService.restoreExpense(expenseModel);

    _expenses.add(expense);
    _sortByDateDesc();

    _refreshTotals();
    notifyListeners();

    if (_notificationProvider.limitAlertEnabled) {
      await _notificationProvider.checkBudgetLimit(_monthTotal);
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

    _sortByDateDesc(); // Mantiene l'ordine corretto se la data cambia

    _refreshTotals();
    notifyListeners();

    if (_notificationProvider.limitAlertEnabled) {
      await _notificationProvider.checkBudgetLimit(_monthTotal);
    }
  }

  Future<void> deleteExpense(ExpenseModel expenseModel) async {
    await _expenseService.deleteExpense(expenseModel);

    _expenses.remove(expenseModel);

    _refreshTotals();
    notifyListeners();

    if (_notificationProvider.limitAlertEnabled) {
      await _notificationProvider.checkBudgetLimit(_monthTotal);
    }
  }

  // --- ORDINAMENTO ---
  // Helper privato e metodo pubblico per ordinare la lista in-place.
  void _sortByDateDesc() {
    ExpenseCalculator.sortInPlace(_expenses, "date_desc");
  }

  void sortBy(String criteria) {
    ExpenseCalculator.sortInPlace(_expenses, criteria);
    notifyListeners();
  }

  // --- AGGREGAZIONE E FILTRI ---
  // Delegano i calcoli complessi all'ExpenseCalculator.
  // Non vengono cachati perché ritornano strutture dati complesse (Map/List)
  // usate solo in schermate specifiche di reportistica.
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