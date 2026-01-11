import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// FILE: expense_service.dart
/// DESCRIZIONE: Service Layer per la gestione delle spese.
/// Agisce come ponte tra il Provider (Stato) e il Repository (Dati/Firebase),
/// occupandosi della logica di business come la generazione degli UUID,
/// la verifica dell'autenticazione corrente e l'ordinamento iniziale dei dati.

class ExpenseService {
  // --- STATO E DIPENDENZE ---
  // Iniezione del repository per l'accesso al database.
  final FirebaseRepository _firebaseRepository;

  ExpenseService({required FirebaseRepository firebaseRepository})
    : _firebaseRepository = firebaseRepository;

  // --- LETTURA DATI (READ) ---
  // Recupera le spese associate all'utente corrente.
  // Gestisce il caso di utente non loggato restituendo una lista vuota 
  // e ordina i risultati per data decrescente prima di restituirli al Provider.
  Future<List<ExpenseModel>> loadUserExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final expenses = await _firebaseRepository.allExpensesForUser(user.uid);
    
    expenses.sort((a, b) => b.createdOn.compareTo(a.createdOn)); 
    return expenses;
  }

  // --- CREAZIONE (CREATE) ---
  // Genera un nuovo oggetto ExpenseModel assegnando un UUID univoco e
  // associandolo all'utente corrente. Lancia un'eccezione se l'utente non è autenticato.
  Future<ExpenseModel> createExpense({
    required double value,
    required String? description,
    required DateTime date,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw RepositoryFailure("User not authenticated.");

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

  // --- RIPRISTINO (UNDO) ---
  // Reinserisce una spesa precedentemente eliminata (funzionalità Undo).
  // Assicura che l'ID utente sia corretto prima di salvare nuovamente il dato.
  Future<ExpenseModel> restoreExpense(ExpenseModel expenseModel) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw RepositoryFailure("User not authenticated.");

    if (expenseModel.userId != user.uid) {
      expenseModel.userId = user.uid;
    }

    await _firebaseRepository.createExpense(expenseModel);
    return expenseModel;
  }

  // --- MODIFICA E CANCELLAZIONE ---
  // Gestisce l'aggiornamento e l'eliminazione delle spese.
  // Esegue un controllo di sicurezza (ownership) per garantire che l'utente
  // stia modificando o eliminando solo le proprie spese.
  Future<ExpenseModel> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || expenseModel.userId != user.uid) {
      throw RepositoryFailure("You do not have permission to edit this expense.");
    }

    expenseModel.value = value;
    expenseModel.description = description;
    expenseModel.createdOn = date;

    await _firebaseRepository.updateExpense(expenseModel);
    return expenseModel;
  }

  Future<void> deleteExpense(ExpenseModel expenseModel) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || expenseModel.userId != user.uid) {
      throw RepositoryFailure("You do not have permission to delete this expense.");
    }

    await _firebaseRepository.deleteExpense(expenseModel);
  }
}