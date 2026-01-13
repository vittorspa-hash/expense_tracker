import 'package:expense_tracker/models/expense_model.dart';

/// FILE: expense_calculator.dart
/// DESCRIZIONE: Classe di utilità (Helper) contenente metodi statici puri per l'elaborazione dei dati.
/// Gestisce il calcolo dei totali, l'aggregazione temporale (giornaliera/mensile) e l'ordinamento,
/// supportando la normalizzazione multi-valuta tramite una valuta target.

class ExpenseCalculator {
  
  // --- CALCOLO TOTALI TEMPORALI ---
  // Metodi per sommare le spese in intervalli specifici (Oggi, Settimana, Mese, Anno).
  // Richiedono [targetCurrency] per normalizzare le spese (che potrebbero essere in valute diverse)
  // in un unico valore comparabile prima della somma.
  
  static double totalExpenseToday(List<ExpenseModel> expenses, String targetCurrency) {
    final currentDate = DateTime.now();
    final startOfDay = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfDay))
        .fold(0.0, (acc, expense) => acc + expense.getValueIn(targetCurrency));
  }

  static double totalExpenseWeek(List<ExpenseModel> expenses, String targetCurrency) {
    final currentDate = DateTime.now();
    final startOfWeek = currentDate.subtract(
      Duration(days: currentDate.weekday - 1),
    );
    final startOfWeekMidnight = DateTime(
      startOfWeek.year, 
      startOfWeek.month, 
      startOfWeek.day
    );

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfWeekMidnight))
        .fold(0.0, (acc, expense) => acc + expense.getValueIn(targetCurrency));
  }

  static double totalExpenseMonth(List<ExpenseModel> expenses, String targetCurrency) {
    final currentDate = DateTime.now();
    final startOfMonth = DateTime(currentDate.year, currentDate.month, 1);

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfMonth))
        .fold(0.0, (acc, expense) => acc + expense.getValueIn(targetCurrency));
  }

  static double totalExpenseYear(List<ExpenseModel> expenses, String targetCurrency) {
    final currentDate = DateTime.now();
    final startOfYear = DateTime(currentDate.year, 1, 1);

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfYear))
        .fold(0.0, (acc, expense) => acc + expense.getValueIn(targetCurrency));
  }

  // --- AGGREGAZIONE DATI ---
  // Metodi per raggruppare le spese e calcolarne i totali parziali.
  // Utili per grafici o liste riepilogative. Anche qui i valori sono convertiti
  // nella valuta target per garantire coerenza nei totali raggruppati.

  // Raggruppa per mese (formato chiave "YYYY-MM").
  static Map<String, double> expensesByMonth(List<ExpenseModel> expenses, String targetCurrency) {
    final Map<String, double> grouped = {};

    for (var expense in expenses) {
      final date = expense.createdOn;
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      
      double convertedValue = expense.getValueIn(targetCurrency);
      grouped[key] = (grouped[key] ?? 0) + convertedValue;
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (var k in sortedKeys) k: grouped[k]!};
  }

  // Raggruppa per giorno specifico all'interno di un mese/anno dato (formato chiave "DD/MM/YYYY").
  static Map<String, double> expensesByDay(
    List<ExpenseModel> expenses,
    int year,
    int month,
    String targetCurrency, 
  ) {
    final Map<String, double> grouped = {};

    for (var expense in expenses) {
      final date = expense.createdOn;
      if (date.year == year && date.month == month) {
        final key =
            "${date.day.toString().padLeft(2, '0')}/"
            "${date.month.toString().padLeft(2, '0')}/"
            "${date.year}";
            
        double convertedValue = expense.getValueIn(targetCurrency);
        grouped[key] = (grouped[key] ?? 0) + convertedValue;
      }
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final da = DateTime.parse(a.split('/').reversed.join('-'));
        final db = DateTime.parse(b.split('/').reversed.join('-'));
        return db.compareTo(da);
      });

    return {for (var k in sortedKeys) k: grouped[k]!};
  }

  // --- FILTRAGGIO SPECIFICO ---
  // Restituisce la lista grezza di oggetti ExpenseModel per un giorno specifico.
  // Qui non avviene conversione valuta poiché serve per visualizzare i dettagli (lista transazioni).
  static List<ExpenseModel> expensesOfDay(
    List<ExpenseModel> expenses,
    int year,
    int month,
    int day,
  ) {
    final list = expenses.where((expense) {
      final date = expense.createdOn;
      return date.year == year && date.month == month && date.day == day;
    }).toList();

    list.sort((a, b) => b.createdOn.compareTo(a.createdOn));
    return list;
  }

  // --- ORDINAMENTO ---
  // Ordina la lista in-place. Se il criterio riguarda l'importo ("amount"),
  // è possibile passare [targetCurrency] per ordinare in base al valore reale convertito
  // (potere d'acquisto) invece che al semplice valore numerico.
  static void sortInPlace(List<ExpenseModel> expenses, String criteria, {String? targetCurrency}) {
    switch (criteria) {
      case "date_desc":
        expenses.sort((a, b) => b.createdOn.compareTo(a.createdOn));
        break;
      case "date_asc":
        expenses.sort((a, b) => a.createdOn.compareTo(b.createdOn));
        break;
      case "amount_desc":
        if (targetCurrency != null) {
          expenses.sort((a, b) => b.getValueIn(targetCurrency).compareTo(a.getValueIn(targetCurrency)));
        } else {
          expenses.sort((a, b) => b.value.compareTo(a.value));
        }
        break;
      case "amount_asc":
        if (targetCurrency != null) {
          expenses.sort((a, b) => a.getValueIn(targetCurrency).compareTo(b.getValueIn(targetCurrency)));
        } else {
          expenses.sort((a, b) => a.value.compareTo(b.value));
        }
        break;
    }
  }
}