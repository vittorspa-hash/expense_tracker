// expense_service.dart
// Service per la logica di business delle spese.
// Gestisce le operazioni CRUD e l'interazione con il repository.

import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ExpenseService {
  final FirebaseRepository _firebaseRepository;

  ExpenseService({required FirebaseRepository firebaseRepository})
    : _firebaseRepository = firebaseRepository;

  // Carica tutte le spese dell'utente corrente dal repository
  Future<List<ExpenseModel>> loadUserExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final expenses = await _firebaseRepository.allExpensesForUser(user.uid);
    expenses.sort(
      (a, b) => b.createdOn.compareTo(a.createdOn),
    ); // Ordine decrescente per data
    return expenses;
  }

  // Crea una nuova spesa
  Future<ExpenseModel> createExpense({
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

    await _firebaseRepository.createExpense(expense);
    return expense;
  }

  // Ripristina una spesa già esistente (utilizzato per undo)
  Future<ExpenseModel> restoreExpense(ExpenseModel expenseModel) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utente non loggato");

    // Assicuriamoci che il userId sia corretto
    if (expenseModel.userId != user.uid) {
      expenseModel.userId = user.uid;
    }

    await _firebaseRepository.createExpense(expenseModel);
    return expenseModel;
  }

  // Modifica una spesa esistente
  Future<ExpenseModel> editExpense(
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

    await _firebaseRepository.updateExpense(expenseModel);
    return expenseModel;
  }

  // Elimina una spesa
  Future<void> deleteExpense(ExpenseModel expenseModel) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || expenseModel.userId != user.uid) {
      throw Exception("Non hai permesso di eliminare questa spesa");
    }

    await _firebaseRepository.deleteExpense(expenseModel);
  }
}
