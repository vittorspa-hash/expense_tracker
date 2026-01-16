import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:flutter/foundation.dart'; 

/// FILE: firebase_repository.dart
/// DESCRIZIONE: Repository per l'interazione diretta con Cloud Firestore.
/// Implementa una logica "Offline-First": tenta sempre di comunicare col server,
/// ma utilizza timeout aggressivi per passare alla cache locale o sbloccare la UI
/// in caso di connessioni instabili o assenti.

class FirebaseRepository {
  // --- CONFIGURAZIONE ---
  final CollectionReference _collection = FirebaseFirestore.instance.collection("expenses");

  // Timeout per le operazioni. 
  // 5 secondi sono sufficienti per una connessione lenta. Se supera, è offline/bloccato.
  static const Duration _operationTimeout = Duration(seconds: 5);

  // --- LETTURA DATI (READ) ---
  // Tenta di recuperare i dati dal server per avere quelli più aggiornati.
  // Se la chiamata al server impiega troppo tempo (timeout) o fallisce,
  // recupera istantaneamente i dati dalla cache locale di Firestore.
  Future<List<ExpenseModel>> allExpensesForUser(String userId) async {
    try {
      QuerySnapshot snapshot;
      
      try {
        // 1. Proviamo a scaricare dal server con un timeout
        snapshot = await _collection
            .where("userId", isEqualTo: userId)
            .orderBy("createdOn", descending: true)
            .get()
            .timeout(_operationTimeout);
            
      } on TimeoutException {
        // 2. Se il server non risponde (es. offline "appeso"), leggiamo dalla Cache
        debugPrint("Firestore Read Timeout: Switching to local cache.");
        snapshot = await _collection
            .where("userId", isEqualTo: userId)
            .orderBy("createdOn", descending: true)
            .get(const GetOptions(source: Source.cache));
      } catch (e) {
        // 3. Se fallisce per altri motivi (es. errore rete immediato), fallback su Cache
        debugPrint("Firestore Read Error ($e): Switching to local cache.");
        snapshot = await _collection
            .where("userId", isEqualTo: userId)
            .orderBy("createdOn", descending: true)
            .get(const GetOptions(source: Source.cache));
      }

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

    } on FirebaseException catch (e) {
      throw RepositoryFailure(
        "Firestore error during retrieval: ${e.message}", 
        code: e.code
      );
    } catch (e) {
      throw RepositoryFailure("Generic error retrieving expenses: $e");
    }
  }

  // --- SCRITTURA DATI (C.U.D.) ---
  // In tutte le operazioni di scrittura, applichiamo un .timeout().
  // Firestore scrive SEMPRE nella cache locale immediatamente. L'await aspetta la conferma del server.
  // Col timeout, se il server non conferma subito, noi "rompiamo" l'attesa e consideriamo
  // l'operazione riuscita (perché è salvata in locale e si sincronizzerà quando torna la rete).

  Future<void> createExpense(ExpenseModel expenseModel) async {
    try {
      await _collection
          .doc(expenseModel.uuid)
          .set(expenseModel.toMap())
          .timeout(_operationTimeout);
    } on TimeoutException {
      // Ignoriamo il timeout: il dato è salvato in locale e verrà sincronizzato.
      debugPrint("Create Expense Timeout: Assumed saved in local cache.");
    } on FirebaseException catch (e) {
      throw RepositoryFailure("Unable to save expense", code: e.code);
    } catch (e) {
      throw RepositoryFailure("Unexpected error saving expense");
    }
  }

  Future<void> updateExpense(ExpenseModel expenseModel) async {
    try {
      await _collection
          .doc(expenseModel.uuid)
          .update(expenseModel.toMap())
          .timeout(_operationTimeout);
    } on TimeoutException {
      debugPrint("Update Expense Timeout: Assumed updated in local cache.");
    } on FirebaseException catch (e) {
      throw RepositoryFailure("Unable to update expense", code: e.code);
    } catch (e) {
      throw RepositoryFailure("Unexpected error updating expense");
    }
  }

  Future<void> deleteExpense(ExpenseModel expenseModel) async {
    try {
      await _collection
          .doc(expenseModel.uuid)
          .delete()
          .timeout(_operationTimeout);
    } on TimeoutException {
      debugPrint("Delete Expense Timeout: Assumed deleted in local cache.");
    } on FirebaseException catch (e) {
      throw RepositoryFailure("Unable to delete expense", code: e.code);
    } catch (e) {
      throw RepositoryFailure("Unexpected error deleting expense");
    }
  }
}