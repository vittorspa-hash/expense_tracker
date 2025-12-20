// auth_provider.dart
import 'package:flutter/foundation.dart'; // Per ChangeNotifier
import 'package:firebase_auth/firebase_auth.dart';

// Assicurati che l'import punti al tuo service corretto
import 'package:expense_tracker/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({required AuthService authService})
      : _authService = authService;

  // Stato per gestire caricamenti
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Getter per l'utente corrente
  User? get currentUser => _authService.currentUser;

  // ---------------------------------------------------------------------------
  // 🟦 REGISTRAZIONE UTENTE
  // ---------------------------------------------------------------------------
  Future<void> signUp({
    required String email,
    required String password,
    required String nome,
  }) async {
    // Nota: La validazione delle password (match) deve essere fatta dalla UI prima di chiamare questo metodo.
    
    _setLoading(true);
    try {
      await _authService.signUp(
        email: email, 
        password: password, 
        nome: nome
      );
      // Il service si occupa di inviare l'email automatica se configurato, 
      // oppure la UI può mostrare il Dialog di successo dopo l'await.
    } catch (e) {
      rethrow; // Rilancia l'errore alla UI (es. "Email già in uso")
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 LOGIN UTENTE
  // ---------------------------------------------------------------------------
  /// Ritorna l'oggetto User così la UI può controllare user.emailVerified
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final user = await _authService.signIn(email: email, password: password);
      return user; 
      // La logica "Se non verificato -> Show Dialog" ora appartiene alla UI
    } catch (e) {
      rethrow; // Rilancia l'errore alla UI (es. "Password errata")
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 LOGOUT UTENTE
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      notifyListeners(); 
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 RESET PASSWORD
  // ---------------------------------------------------------------------------
  Future<void> resetPassword({String? email}) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 INVIA EMAIL DI VERIFICA MANUALE
  // ---------------------------------------------------------------------------
  // Metodo esposto per essere chiamato dal Dialog della UI "Email non verificata"
  Future<void> sendVerificationEmail(User user) async {
    try {
      await _authService.sendVerificationEmail(user);
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🛠 UTILS INTERNE
  // ---------------------------------------------------------------------------
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}