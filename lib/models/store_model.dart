// store_model.dart
// Store centrale per gestire tutte le spese dell'applicazione.
// Include funzioni per creare, modificare, cancellare e raggruppare le spese.
// Supporta anche i calcoli di totali giornalieri, settimanali, mensili e annuali.

import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/settings_provider.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

// Oggetto globale osservabile di StoreModel
final storeModel = StoreModel().obs;

class StoreModel {
  // Lista interna di tutte le spese
  List<ExpenseModel> expenses = [];

  // Inizializza lo store caricando le spese dell'utente dal repository
  Future<void> initialise() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      expenses = [];
      storeModel.refresh();
      return;
    }

    expenses = await GetIt.instance<FirebaseRepository>().allExpensesForUser(
      user.uid,
    );

    expenses.sort(
      (a, b) => b.createdOn.compareTo(a.createdOn),
    ); // Ordine decrescente per data
    storeModel.refresh();
  }

  // Pulisce tutte le spese dallo store
  void clear() {
    expenses = [];
    storeModel.refresh();
  }

  // Totale spese di oggi
  double get totalExpenseToday {
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
  double get totalExpenseWeek {
    final currentDate = DateTime.now();
    final startOfWeek = currentDate.subtract(
      Duration(days: currentDate.weekday - 1),
    );

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfWeek))
        .fold(0.0, (acc, expense) => acc + expense.value);
  }

  // Totale spese del mese corrente
  double get totalExpenseMonth {
    final currentDate = DateTime.now();
    final startOfMonth = DateTime(currentDate.year, currentDate.month, 1);

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfMonth))
        .fold(0.0, (acc, expense) => acc + expense.value);
  }

  // Totale spese dell'anno corrente
  double get totalExpenseYear {
    final currentDate = DateTime.now();
    final startOfYear = DateTime(currentDate.year, 1, 1);

    return expenses
        .where((expense) => expense.createdOn.isAfter(startOfYear))
        .fold(0.0, (acc, expense) => acc + expense.value);
  }

  // Crea una nuova spesa
  Future<void> createExpense({
    required double value,
    required String? description,
    required DateTime date,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utente non loggato");

    final expense = ExpenseModel(
      uuid: const Uuid().v4(),
      value: value,
      description: description,
      createdOn: date,
      userId: user.uid,
    );

    expenses.add(expense);
    expenses.sort((a, b) => b.createdOn.compareTo(a.createdOn));
    GetIt.instance<FirebaseRepository>().createExpense(expense);
    storeModel.refresh();

    final settingsProvider = GetIt.instance<SettingsProvider>();
    if (settingsProvider.limitAlertEnabled) {
      await settingsProvider.checkBudgetLimit(totalExpenseMonth);
    }
  }

  // Ripristina una spesa già esistente (utilizzato per undo)
  Future<void> restoreExpense(ExpenseModel expenseModel) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utente non loggato");

    // Assicuriamoci che il userId sia corretto
    if (expenseModel.userId != user.uid) {
      expenseModel.userId = user.uid;
    }

    expenses.add(expenseModel);
    expenses.sort((a, b) => b.createdOn.compareTo(a.createdOn));
    GetIt.instance<FirebaseRepository>().createExpense(expenseModel);
    storeModel.refresh();

    final settingsProvider = GetIt.instance<SettingsProvider>();
    if (settingsProvider.limitAlertEnabled) {
      await settingsProvider.checkBudgetLimit(totalExpenseMonth);
    }
  }

  // Modifica una spesa esistente
  Future<void> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || expenseModel.userId != user.uid) {
      throw Exception("Non hai permesso di modificare questa spesa");
    }

    expenseModel.value = value;
    expenseModel.description = description;
    expenseModel.createdOn = date;

    expenses.sort((a, b) => b.createdOn.compareTo(a.createdOn));
    GetIt.instance<FirebaseRepository>().updateExpense(expenseModel);
    storeModel.refresh();

    final settingsProvider = GetIt.instance<SettingsProvider>();
    if (settingsProvider.limitAlertEnabled) {
      await settingsProvider.checkBudgetLimit(totalExpenseMonth);
    }
  }

  // Elimina una spesa
  Future<void> deleteExpense(ExpenseModel expenseModel) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || expenseModel.userId != user.uid) {
      throw Exception("Non hai permesso di eliminare questa spesa");
    }

    expenses.remove(expenseModel);
    GetIt.instance<FirebaseRepository>().deleteExpense(expenseModel);
    storeModel.refresh();

    final settingsProvider = GetIt.instance<SettingsProvider>();
    if (settingsProvider.limitAlertEnabled) {
      await settingsProvider.checkBudgetLimit(totalExpenseMonth);
    }
  }

  // Ordina la lista delle spese in base al criterio
  void sortBy(String criteria) {
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
    storeModel.refresh();
  }

  // Raggruppa le spese per mese (key: "YYYY-MM")
  Map<String, double> get expensesByMonth {
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
  Map<String, double> expensesByDay(int year, int month) {
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
  List<ExpenseModel> expensesOfDay(int year, int month, int day) {
    final list = expenses.where((expense) {
      final date = expense.createdOn;
      return date.year == year && date.month == month && date.day == day;
    }).toList();

    list.sort((a, b) => b.createdOn.compareTo(a.createdOn));
    return list;
  }
}
