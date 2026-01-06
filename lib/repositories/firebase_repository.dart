import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/repository_failure.dart';

/// FILE: firebase_repository.dart
/// DESCRIZIONE: Repository per l'interazione diretta con Cloud Firestore.
/// Gestisce le operazioni CRUD (Create, Read, Update, Delete) verso il database remoto,
/// mappando i dati tra documenti Firestore e oggetti ExpenseModel e incapsulando 
/// le eccezioni di rete in errori di dominio gestibili.

class FirebaseRepository {
  // --- CONFIGURAZIONE ---
  // Riferimento alla collezione principale "expenses" su Firestore.
  final CollectionReference _collection = FirebaseFirestore.instance.collection("expenses");

  // --- LETTURA DATI (READ) ---
  // Recupera tutte le spese associate a un determinato ID utente.
  // Esegue una query filtrata e ordinata lato server, convertendo i documenti risultanti
  // in oggetti di dominio. Gestisce errori specifici di Firestore o di parsing.
  Future<List<ExpenseModel>> allExpensesForUser(String userId) async {
    try {
      final snapshot = await _collection
          .where("userId", isEqualTo: userId)
          .orderBy("createdOn", descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

    } on FirebaseException catch (e) {
      throw RepositoryFailure(
        "Errore Firestore durante il recupero: ${e.message}", 
        code: e.code
      );
    } catch (e) {
      throw RepositoryFailure("Errore generico nel recupero delle spese: $e");
    }
  }

  // --- SCRITTURA DATI (C.U.D.) ---
  // Metodi per la persistenza delle modifiche sul database remoto.
  // Utilizzano l'UUID della spesa come chiave del documento per garantire l'idempotenza.

  // Salva una nuova spesa nel database.
  // In caso di successo completa il Future, altrimenti lancia un'eccezione RepositoryFailure.
  Future<void> createExpense(ExpenseModel expenseModel) async {
    try {
      await _collection.doc(expenseModel.uuid).set(expenseModel.toMap());
    } on FirebaseException catch (e) {
      throw RepositoryFailure("Impossibile salvare la spesa", code: e.code);
    } catch (e) {
      throw RepositoryFailure("Errore imprevisto nel salvataggio");
    }
  }

  // Aggiorna i dati di una spesa esistente sovrascrivendo i campi nel documento corrispondente.
  Future<void> updateExpense(ExpenseModel expenseModel) async {
    try {
      await _collection.doc(expenseModel.uuid).update(expenseModel.toMap());
    } on FirebaseException catch (e) {
      throw RepositoryFailure("Impossibile aggiornare la spesa", code: e.code);
    } catch (e) {
      throw RepositoryFailure("Errore imprevisto nell'aggiornamento");
    }
  }

  // Rimuove permanentemente il documento della spesa dal database.
  Future<void> deleteExpense(ExpenseModel expenseModel) async {
    try {
      await _collection.doc(expenseModel.uuid).delete();
    } on FirebaseException catch (e) {
      throw RepositoryFailure("Impossibile eliminare la spesa", code: e.code);
    } catch (e) {
      throw RepositoryFailure("Errore imprevisto nell'eliminazione");
    }
  }
}