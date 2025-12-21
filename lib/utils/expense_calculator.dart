// expense_calculator.dart
// Classe statica per tutti i calcoli e raggruppamenti delle spese.
// Funzioni pure senza side effects, facilmente testabili.

import 'package:expense_tracker/models/expense_model.dart';

class ExpenseCalculator {
  // Totale spese di oggi
  static double totalExpenseToday(List<ExpenseModel> expenses) {
    final currentDate = DateTime.now();
    final startOfDay = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfDay))
        .fold(0.0, (acc, expense) => acc + expense.value);
  }

  // Totale spese della settimana corrente
  static double totalExpenseWeek(List<ExpenseModel> expenses) {
    final currentDate = DateTime.now();
    final startOfWeek = currentDate.subtract(
      Duration(days: currentDate.weekday - 1),
    );

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfWeek))
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

  // Raggruppa le spese per mese (key: "YYYY-MM")
  static Map<String, double> expensesByMonth(List<ExpenseModel> expenses) {
    final Map<String, double> grouped = {};

    for (var expense in expenses) {
      final date = expense.createdOn;
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      grouped[key] = (grouped[key] ?? 0) + expense.value;
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (var k in sortedKeys) k: grouped[k]!};
  }

  // Raggruppa le spese per giorno di un determinato mese
  static Map<String, double> expensesByDay(
    List<ExpenseModel> expenses,
    int year,
    int month,
  ) {
    final Map<String, double> grouped = {};

    for (var expense in expenses) {
      final date = expense.createdOn;
      if (date.year == year && date.month == month) {
        final key =
            "${date.day.toString().padLeft(2, '0')}/"
            "${date.month.toString().padLeft(2, '0')}/"
            "${date.year}";
        grouped[key] = (grouped[key] ?? 0) + expense.value;
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

  // Restituisce le spese di un giorno specifico
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

  // ✅ OTTIMIZZATO: Ora fa sort IN-PLACE invece di creare una nuova lista
  // Modifica direttamente la lista passata per riferimento
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
