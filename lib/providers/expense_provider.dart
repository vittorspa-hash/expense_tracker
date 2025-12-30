import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:flutter/foundation.dart';

/// FILE: expense_provider.dart
/// DESCRIZIONE: Layer di gestione dello stato (State Management).
/// Agisce da "Single Source of Truth" per la UI.
/// Responsabilità:
/// 1. Mantenere la lista locale delle spese sincronizzata con il Service.
/// 2. Gestire la cache dei totali (Oggi, Settimana, Mese, Anno).
/// 3. Delegare i calcoli matematici complessi a ExpenseCalculator.
/// 4. Notificare i listener (UI) e verificare le soglie di budget.

class ExpenseProvider extends ChangeNotifier {
  final NotificationProvider _notificationProvider;
  final ExpenseService _expenseService;

  ExpenseProvider({
    required NotificationProvider notificationProvider,
    required ExpenseService expenseService,
  }) : _notificationProvider = notificationProvider,
       _expenseService = expenseService;

  // --- STATO ---
  // Lista principale delle spese caricata in memoria.
  List<ExpenseModel> _expenses = [];
  
  // Getter immutabile per proteggere la lista originale da modifiche esterne accidentali.
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  // --- CACHE TOTALI ---
  // Variabili per memorizzare i totali calcolati ed evitare ricalcoli inutili nel build della UI.
  double _todayTotal = 0.0;
  double _weekTotal = 0.0;
  double _monthTotal = 0.0;
  double _yearTotal = 0.0;

  double get totalExpenseToday => _todayTotal;
  double get totalExpenseWeek => _weekTotal;
  double get totalExpenseMonth => _monthTotal;
  double get totalExpenseYear => _yearTotal;

  // --- HELPER INTERNI ---
  // Metodi privati per aggiornare lo stato interno.
  
  // Ricalcola tutti i totali delegando la logica pura a ExpenseCalculator.
  void _refreshTotals() {
    _todayTotal = ExpenseCalculator.totalExpenseToday(_expenses);
    _weekTotal = ExpenseCalculator.totalExpenseWeek(_expenses);
    _monthTotal = ExpenseCalculator.totalExpenseMonth(_expenses);
    _yearTotal = ExpenseCalculator.totalExpenseYear(_expenses);
  }
  
  // Ordina la lista locale in place (dal più recente) per consistenza UI.
  void _sortByDateDesc() {
    ExpenseCalculator.sortInPlace(_expenses, "date_desc");
  }

  // --- INIZIALIZZAZIONE ---
  // Carica i dati iniziali dal Service (DB) all'avvio dell'app.
  Future<void> initialise() async {
    _expenses = await _expenseService.loadUserExpenses();
    _refreshTotals();
    notifyListeners();
  }

  // Pulisce lo stato (utile ad esempio al logout).
  void clear() {
    _expenses = [];
    _refreshTotals();
    notifyListeners();
  }

  // --- CREAZIONE & MODIFICA (Singole) ---
  // Gestiscono il ciclo di vita di una singola spesa: DB -> Lista Locale -> Ordina -> Calcola -> Notifica.
  
  Future<void> createExpense({
    required double value,
    required String? description,
    required DateTime date,
  }) async {
    // 1. Persistenza remota
    final expense = await _expenseService.createExpense(
      value: value,
      description: description,
      date: date,
    );
    // 2. Aggiornamento locale
    _expenses.add(expense);
    _sortByDateDesc(); 
    _refreshTotals();
    notifyListeners();
    // 3. Side Effect (Budget Check)
    _checkBudget(dateToCheck: date);
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
    _sortByDateDesc();
    _refreshTotals();
    notifyListeners();
    _checkBudget(dateToCheck: date);
  }

  // --- ELIMINAZIONE UNIFICATA (Batch & Single) ---
  // Gestisce la rimozione di una o più spese (es. selezione multipla o swipe singolo).
  // Ottimizzato per performance: esegue chiamate parallele al DB.
  
  /// Elimina una o più spese.
  // ignore: unintended_html_in_doc_comment
  /// Accetta una List<ExpenseModel>. Per eliminare un singolo elemento: `deleteExpenses([item])`
  Future<void> deleteExpenses(List<ExpenseModel> expensesToDelete) async {
    if (expensesToDelete.isEmpty) return;

    // 1. DB: Esecuzione parallela per ridurre i tempi di attesa
    await Future.wait(expensesToDelete.map((e) => _expenseService.deleteExpense(e)));

    // 2. Local State: Rimozione efficiente tramite Set di UUID
    final idsToRemove = expensesToDelete.map((e) => e.uuid).toSet();
    _expenses.removeWhere((element) => idsToRemove.contains(element.uuid));

    // 3. UI Updates: Ricalcolo totali e refresh
    _refreshTotals();
    notifyListeners();
  }

  // --- RIPRISTINO UNIFICATO (Batch & Single) ---
  // Gestisce l'Undo (annulla eliminazione) per una o più spese.
  
  /// Ripristina una o più spese (Undo).
  Future<void> restoreExpenses(List<ExpenseModel> expensesToRestore) async {
    if (expensesToRestore.isEmpty) return;

    // 1. DB: Ripristino parallelo
    await Future.wait(expensesToRestore.map((e) => _expenseService.restoreExpense(e)));

    // 2. Local State: Reinserimento dati
    _expenses.addAll(expensesToRestore);
    _sortByDateDesc(); 

    // 3. UI Updates: Ricalcolo totali, refresh e verifica budget (poiché la spesa aumenta)
    _refreshTotals();
    notifyListeners();
    _checkBudgetForList(expensesToRestore);
  }

  // --- HELPER BUDGET ---
  // Verifica se il totale mensile supera la soglia impostata dall'utente.
  // Esegue il controllo solo se la data passata corrisponde al mese/anno attuali.
  Future<void> _checkBudget({required DateTime dateToCheck}) async {
    final now = DateTime.now();
    
    // Se la spesa è vecchia (o futura di un altro mese), interrompiamo subito.
    if (dateToCheck.month != now.month || dateToCheck.year != now.year) {
      return;
    }

    if (_notificationProvider.limitAlertEnabled) {
      await _notificationProvider.checkBudgetLimit(_monthTotal);
    }
  }

  // Helper specifico per le liste (usato in restoreExpenses)
  Future<void> _checkBudgetForList(List<ExpenseModel> expenses) async {
    final now = DateTime.now();
    
    // Controlla se nella lista c'è almeno una spesa del mese corrente
    bool hasCurrentMonthExpense = expenses.any((e) => 
      e.createdOn.month == now.month && e.createdOn.year == now.year
    );

    if (hasCurrentMonthExpense && _notificationProvider.limitAlertEnabled) {
      await _notificationProvider.checkBudgetLimit(_monthTotal);
    }
  }

  // --- ORDINAMENTO & FILTRI ---
  // Metodi pubblici per l'ordinamento dinamico e il raggruppamento (utili per grafici o liste).
  
  void sortBy(String criteria) {
    ExpenseCalculator.sortInPlace(_expenses, criteria);
    notifyListeners();
  }

  // Raggruppamento per Mese (Graph Data)
  Map<String, double> get expensesByMonth => ExpenseCalculator.expensesByMonth(_expenses);
  
  // Raggruppamento per Giorno specifico (Calendar Data)
  Map<String, double> expensesByDay(int year, int month) => 
      ExpenseCalculator.expensesByDay(_expenses, year, month);
  
  // Filtro spese per data specifica
  List<ExpenseModel> expensesOfDay(int year, int month, int day) => 
      ExpenseCalculator.expensesOfDay(_expenses, year, month, day);
}