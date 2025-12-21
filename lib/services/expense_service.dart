import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// FILE: expense_service.dart
/// DESCRIZIONE: Layer di logica di business (Business Logic Layer).
/// Si posiziona tra il Provider (Stato) e il Repository (Dati).
/// Responsabilità:
/// 1. Validazione dell'utente corrente (Auth Check).
/// 2. Validazione della proprietà del dato (Ownership Check).
/// 3. Generazione di ID univoci (UUID).
/// 4. Ordinamento iniziale dei dati.

class ExpenseService {
  final FirebaseRepository _firebaseRepository;

  ExpenseService({required FirebaseRepository firebaseRepository})
    : _firebaseRepository = firebaseRepository;

  // --- LETTURA DATI (READ) ---
  // Recupera le spese dal repository e applica un ordinamento di default (Data decrescente).
  // Se non c'è un utente loggato, restituisce una lista vuota per sicurezza.
  // 
  Future<List<ExpenseModel>> loadUserExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final expenses = await _firebaseRepository.allExpensesForUser(user.uid);
    
    // Business Logic: L'app si aspetta i dati ordinati per data (dal più recente)
    expenses.sort(
      (a, b) => b.createdOn.compareTo(a.createdOn),
    ); 
    
    return expenses;
  }

  // --- CREAZIONE (CREATE) ---
  // Genera un nuovo oggetto ExpenseModel con un UUID v4 univoco e lo salva.
  Future<ExpenseModel> createExpense({
    required double value,
    required String? description,
    required DateTime date,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utente non loggato");

    final expense = ExpenseModel(
      uuid: const Uuid().v4(), // Generazione ID univoco client-side
      value: value,
      description: description,
      createdOn: date,
      userId: user.uid,
    );

    await _firebaseRepository.createExpense(expense);
    return expense;
  }

  // --- RIPRISTINO (UNDO) ---
  // Simile alla creazione, ma riutilizza un modello esistente (es. dopo uno swipe-to-delete).
  // Forza il userId all'utente corrente per sicurezza.
  Future<ExpenseModel> restoreExpense(ExpenseModel expenseModel) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utente non loggato");

    // Security Check: Assicuriamoci che la spesa venga riassegnata all'utente attuale
    if (expenseModel.userId != user.uid) {
      expenseModel.userId = user.uid;
    }

    await _firebaseRepository.createExpense(expenseModel);
    return expenseModel;
  }

  // --- MODIFICA E CANCELLAZIONE (UPDATE & DELETE) ---
  // Eseguono controlli rigorosi sulla proprietà: solo l'autore della spesa può modificarla o eliminarla.
  // 
  
  Future<ExpenseModel> editExpense(
    ExpenseModel expenseModel, {
    required double value,
    required String? description,
    required DateTime date,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    
    // Security Check
    if (user == null || expenseModel.userId != user.uid) {
      throw Exception("Non hai permesso di modificare questa spesa");
    }

    // Aggiornamento campi
    expenseModel.value = value;
    expenseModel.description = description;
    expenseModel.createdOn = date;

    await _firebaseRepository.updateExpense(expenseModel);
    return expenseModel;
  }

  Future<void> deleteExpense(ExpenseModel expenseModel) async {
    final user = FirebaseAuth.instance.currentUser;
    
    // Security Check
    if (user == null || expenseModel.userId != user.uid) {
      throw Exception("Non hai permesso di eliminare questa spesa");
    }

    await _firebaseRepository.deleteExpense(expenseModel);
  }
}