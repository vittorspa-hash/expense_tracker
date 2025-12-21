import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/expense_model.dart';

/// FILE: firebase_repository.dart
/// DESCRIZIONE: Data Access Layer (DAL) per Cloud Firestore.
/// Isola l'applicazione dai dettagli di implementazione del database.
/// Gestisce la collezione "expenses" e mappa i documenti Firestore
/// negli oggetti di dominio (ExpenseModel).

class FirebaseRepository {
  // --- CONFIGURAZIONE COLLEZIONE ---
  // Riferimento alla root collection dove vengono salvati tutti i documenti.
  // Struttura DB: Collection "expenses" -> Document (UUID) -> Fields (value, date, userId...)
  // 
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    "expenses",
  );

  // --- LETTURA DATI (READ) ---
  // Esegue una query composta:
  // 1. Filtra per 'userId' (sicurezza/isolamento dati).
  // 2. Ordina per 'createdOn' decrescente (dal più recente).
  // Nota: Questa query richiede un indice composito su Firestore (userId + createdOn).
  // 
  Future<List<ExpenseModel>> allExpensesForUser(String userId) async {
    try {
      final snapshot = await _collection
          .where("userId", isEqualTo: userId)
          .orderBy("createdOn", descending: true)
          .get();

      // Mapping: QuerySnapshot -> List<DocumentSnapshot> -> List<ExpenseModel>
      return snapshot.docs
          .map(
            (doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      // In produzione, loggare l'errore (es. Crashlytics) sarebbe preferibile
      return [];
    }
  }

  // --- SCRITTURA DATI (C.U.D.) ---
  // Operazioni di mutazione del database.
  // Utilizzano l'UUID della spesa come chiave primaria del documento.
  // 

  // CREATE: Usa .set() per creare o sovrascrivere un documento con ID specifico
  Future<bool> createExpense(ExpenseModel expenseModel) async {
    try {
      await _collection.doc(expenseModel.uuid).set(expenseModel.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  // UPDATE: Usa .update() per modificare i campi esistenti
  Future<bool> updateExpense(ExpenseModel expenseModel) async {
    try {
      await _collection.doc(expenseModel.uuid).update(expenseModel.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  // DELETE: Rimuove fisicamente il documento dalla collezione
  Future<bool> deleteExpense(ExpenseModel expenseModel) async {
    try {
      await _collection.doc(expenseModel.uuid).delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}