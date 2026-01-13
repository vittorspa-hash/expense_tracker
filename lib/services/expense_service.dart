import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// FILE: expense_service.dart
/// DESCRIZIONE: Service Layer per la gestione delle operazioni sulle spese.
/// Agisce come intermediario tra il Provider (stato dell'applicazione) e il 
/// Repository (persistenza dati su Firebase). Gestisce la logica di business
/// per la creazione, lettura, aggiornamento ed eliminazione (CRUD), inclusa
/// la gestione dei dati multi-valuta.

class ExpenseService {
  // --- DIPENDENZE ---
  final FirebaseRepository _firebaseRepository;

  ExpenseService({required FirebaseRepository firebaseRepository})
    : _firebaseRepository = firebaseRepository;

  // --- LETTURA DATI ---
  // Recupera tutte le spese associate all'utente attualmente autenticato.
  // Restituisce una lista ordinata per data di creazione decrescente (dal più recente).
  Future<List<ExpenseModel>> loadUserExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final expenses = await _firebaseRepository.allExpensesForUser(user.uid);
    
    expenses.sort((a, b) => b.createdOn.compareTo(a.createdOn)); 
    return expenses;
  }

  // --- CREAZIONE SPESA ---
  // Genera un nuovo modello di spesa con un UUID univoco e lo persiste nel database.
  // Salva esplicitamente la valuta della transazione e i tassi di cambio storici
  // validi al momento della creazione.
  Future<ExpenseModel> createExpense({
    required double value,
    required String? description,
    required DateTime date,
    required String currency,                   
    required Map<String, double> exchangeRates, 
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw RepositoryFailure("User not authenticated.");

    final expense = ExpenseModel(
      uuid: const Uuid().v4(),
      value: value,
      description: description,
      createdOn: date,
      userId: user.uid,
      currency: currency,           
      exchangeRates: exchangeRates, 
    );

    await _firebaseRepository.createExpense(expense);
    return expense;
  }

  // --- RIPRISTINO (UNDO) ---
  // Reinserisce nel database una spesa precedentemente eliminata (es. tramite Snackbar).
  // Assicura che l'ID utente corrisponda all'utente corrente prima di salvare.
  Future<ExpenseModel> restoreExpense(ExpenseModel expenseModel) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw RepositoryFailure("User not authenticated.");

    if (expenseModel.userId != user.uid) {
      expenseModel.userId = user.uid;
    }

    await _firebaseRepository.createExpense(expenseModel);
    return expenseModel;
  }

  // --- MODIFICA SPESA ---
  // Aggiorna i dettagli di una spesa esistente.
  // Permette la modifica dell'importo, descrizione, data e valuta principale.
  // NOTA: I tassi di cambio storici (exchangeRates) NON vengono aggiornati per preservare
  // il valore storico della transazione originale.
  Future<ExpenseModel> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
    required String currency, 
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || expenseModel.userId != user.uid) {
      throw RepositoryFailure("You do not have permission to edit this expense.");
    }

    expenseModel.value = value;
    expenseModel.description = description;
    expenseModel.createdOn = date;
    
    expenseModel.currency = currency;

    await _firebaseRepository.updateExpense(expenseModel);
    return expenseModel;
  }

  // --- ELIMINAZIONE ---
  // Rimuove definitivamente una spesa dal database dopo aver verificato i permessi.
  Future<void> deleteExpense(ExpenseModel expenseModel) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || expenseModel.userId != user.uid) {
      throw RepositoryFailure("You do not have permission to delete this expense.");
    }

    await _firebaseRepository.deleteExpense(expenseModel);
  }
}