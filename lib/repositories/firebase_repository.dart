// firebase_repository.dart
// Repository per gestire le operazioni CRUD delle spese su Firebase Firestore.
// Contiene funzioni per recuperare, creare, aggiornare ed eliminare spese.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/expense_model.dart';

class FirebaseRepository {
  // Riferimento alla collezione "expenses" su Firestore
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    "expenses",
  );

  // Recupera tutte le spese di un utente ordinandole per data decrescente
  Future<List<ExpenseModel>> allExpensesForUser(String userId) async {
    try {
      final snapshot = await _collection
          .where("userId", isEqualTo: userId) // Filtra per utente
          .orderBy("createdOn", descending: true) // Ordine decrescente per data
          .get();

      // Converte i documenti Firestore in oggetti ExpenseModel
      return snapshot.docs
          .map(
            (doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Crea una nuova spesa su Firestore
  Future<bool> createExpense(ExpenseModel expenseModel) async {
    try {
      await _collection.doc(expenseModel.uuid).set(expenseModel.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  // Aggiorna una spesa esistente su Firestore
  Future<bool> updateExpense(ExpenseModel expenseModel) async {
    try {
      await _collection.doc(expenseModel.uuid).update(expenseModel.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  // Elimina una spesa da Firestore
  Future<bool> deleteExpense(ExpenseModel expenseModel) async {
    try {
      await _collection.doc(expenseModel.uuid).delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
