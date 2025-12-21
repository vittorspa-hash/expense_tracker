import 'package:expense_tracker/models/expense_model.dart';

/// FILE: expense_calculator.dart
/// DESCRIZIONE: Classe di utilità (Helper) contenente metodi statici puri.
/// Si occupa di tutta la matematica e la manipolazione delle liste di spese:
/// 1. Calcolo dei totali per periodi temporali (Oggi, Settimana, Mese, Anno).
/// 2. Raggruppamento dei dati per la generazione di report e grafici.
/// 3. Ordinamento ottimizzato (In-Place) delle liste.

class ExpenseCalculator {
  
  // --- CALCOLO TOTALI TEMPORALI ---
  // Questi metodi filtrano la lista completa delle spese basandosi su un intervallo
  // di date calcolato a runtime (es. dall'inizio della giornata odierna) e
  // sommano i valori risultanti.
  // 

  // Totale spese di oggi
  static double totalExpenseToday(List<ExpenseModel> expenses) {
    final currentDate = DateTime.now();
    // Crea un DateTime all'ora 00:00:00 di oggi
    final startOfDay = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfDay))
        .fold(0.0, (acc, expense) => acc + expense.value);
  }

  // Totale spese della settimana corrente (Lun-Dom)
  static double totalExpenseWeek(List<ExpenseModel> expenses) {
    final currentDate = DateTime.now();
    // Calcola l'inizio della settimana (Lunedì)
    final startOfWeek = currentDate.subtract(
      Duration(days: currentDate.weekday - 1),
    );
    // Azzera l'orario per includere tutte le spese del Lunedì
    final startOfWeekMidnight = DateTime(
      startOfWeek.year, 
      startOfWeek.month, 
      startOfWeek.day
    );

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfWeekMidnight))
        .fold(0.0, (acc, expense) => acc + expense.value);
  }

  // Totale spese del mese corrente
  static double totalExpenseMonth(List<ExpenseModel> expenses) {
    final currentDate = DateTime.now();
    final startOfMonth = DateTime(currentDate.year, currentDate.month, 1);

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfMonth))
        .fold(0.0, (acc, expense) => acc + expense.value);
  }

  // Totale spese dell'anno corrente
  static double totalExpenseYear(List<ExpenseModel> expenses) {
    final currentDate = DateTime.now();
    final startOfYear = DateTime(currentDate.year, 1, 1);

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfYear))
        .fold(0.0, (acc, expense) => acc + expense.value);
  }

  // --- AGGREGAZIONE DATI (RAGGRUPPAMENTO) ---
  // Questi metodi trasformano una lista piatta di spese in una Mappa,
  // dove la chiave è il periodo (Mese o Giorno) e il valore è la somma delle spese.
  // Utile per popolare grafici e liste riepilogative.
  // 

  // Raggruppa le spese per mese (Format Key: "YYYY-MM")
  static Map<String, double> expensesByMonth(List<ExpenseModel> expenses) {
    final Map<String, double> grouped = {};

    for (var expense in expenses) {
      final date = expense.createdOn;
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      grouped[key] = (grouped[key] ?? 0) + expense.value;
    }

    // Ordina le chiavi (Mesi) in ordine decrescente (dal più recente)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (var k in sortedKeys) k: grouped[k]!};
  }

  // Raggruppa le spese per giorno all'interno di un mese specifico (Format Key: "dd/MM/yyyy")
  static Map<String, double> expensesByDay(
    List<ExpenseModel> expenses,
    int year,
    int month,
  ) {
    final Map<String, double> grouped = {};

    for (var expense in expenses) {
      final date = expense.createdOn;
      // Filtra solo le spese dell'anno e mese richiesti
      if (date.year == year && date.month == month) {
        final key =
            "${date.day.toString().padLeft(2, '0')}/"
            "${date.month.toString().padLeft(2, '0')}/"
            "${date.year}";
        grouped[key] = (grouped[key] ?? 0) + expense.value;
      }
    }

    // Ordina le chiavi (Giorni) parsando la stringa data
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final da = DateTime.parse(a.split('/').reversed.join('-'));
        final db = DateTime.parse(b.split('/').reversed.join('-'));
        return db.compareTo(da);
      });

    return {for (var k in sortedKeys) k: grouped[k]!};
  }

  // --- FILTRAGGIO SPECIFICO ---
  // Restituisce la lista grezza delle spese per un singolo giorno specifico.
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

  // --- ORDINAMENTO (OTTIMIZZATO) ---
  // Esegue un sort IN-PLACE sulla lista passata per riferimento.
  // Evita di creare copie inutili della lista, risparmiando memoria.
  static void sortInPlace(List<ExpenseModel> expenses, String criteria) {
    switch (criteria) {
      case "date_desc":
        expenses.sort((a, b) => b.createdOn.compareTo(a.createdOn));
        break;
      case "date_asc":
        expenses.sort((a, b) => a.createdOn.compareTo(b.createdOn));
        break;
      case "amount_desc":
        expenses.sort((a, b) => b.value.compareTo(a.value));
        break;
      case "amount_asc":
        expenses.sort((a, b) => a.value.compareTo(b.value));
        break;
    }
  }
}