import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

/// FILE: auth_service.dart
/// DESCRIZIONE: Service che gestisce l'interazione diretta con Firebase Authentication.
/// Fornisce metodi per registrazione, login, logout e reset password, incapsulando
/// la gestione degli errori (traduzione codici) e implementando un rate-limit
/// di sicurezza per l'invio delle email di sistema.

class AuthService {
  final FirebaseAuth _firebaseAuth;
  AuthService({required FirebaseAuth firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  // --- CONFIGURAZIONE E STATO ---
  DateTime? _lastEmailSent;

  User? get currentUser => _firebaseAuth.currentUser;

  // --- REGISTRAZIONE UTENTE ---
  // Crea un nuovo utente su Firebase, aggiorna il nome visualizzato (DisplayName)
  // e invia automaticamente l'email di verifica.
  Future<void> signUp({
    required String email,
    required String password,
    required String nome,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      var user = userCredential.user;
      if (user == null) {
        throw AuthException("Unknown error creating user.");
      }

      // Aggiornamento profilo e ricarica stato utente
      await user.updateDisplayName(nome.trim());
      await user.reload();
      final reloadUser = _firebaseAuth.currentUser;
      if (reloadUser == null) throw AuthException("User not found.");

      // Invio email di verifica gestito internamente
      await sendVerificationEmail(reloadUser);
    } on FirebaseAuthException catch (e) {
      // Utilizza il messaggio diretto di Firebase o un fallback generico in inglese
      throw AuthException(e.message ?? "An error occurred during registration.");
    }
  }

  // --- ACCESSO ---
  // Effettua il login con email e password. Ricarica lo stato dell'utente
  // per garantire che il flag 'emailVerified' sia aggiornato prima di restituirlo.
  Future<User> signIn({required String email, required String password}) async {
    try {
      var userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      var user = userCredential.user;
      if (user == null) throw AuthException("User not found.");

      await user.reload();
      return _firebaseAuth.currentUser!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? "An error occurred during login.");
    }
  }

  // --- DISCONNESSIONE ---
  // Termina la sessione corrente su Firebase.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Error during logout.');
    }
  }

  // --- RECUPERO PASSWORD ---
  // Invia un link per il reset della password all'email specificata.
  // Include un controllo di rate-limit per prevenire spam.
  Future<void> resetPassword(String? email) async {
    final targetEmail = email?.trim() ?? _firebaseAuth.currentUser?.email;

    if (targetEmail == null || targetEmail.isEmpty) {
      throw AuthException("Please enter an email.");
    }

    _checkRateLimit(
      "Please wait at least 1 minute before requesting another reset email.",
    );

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: targetEmail);
      _lastEmailSent = DateTime.now();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? "An error occurred during password reset.");
    }
  }

  // --- VERIFICA EMAIL ---
  // Invia nuovamente l'email di conferma all'utente corrente.
  // Soggetto a rate-limit (60 secondi).
  Future<void> sendVerificationEmail([User? user]) async {
    final u = user ?? _firebaseAuth.currentUser;
    if (u == null) throw AuthException("No user logged in.");

    _checkRateLimit(
      "Please wait at least 1 minute before resending the confirmation email.",
    );

    try {
      await u.sendEmailVerification();
      _lastEmailSent = DateTime.now();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? "Error sending verification email.");
    }
  }

  // --- HELPER DI CONTROLLO ---
  // Verifica se è passato abbastanza tempo dall'ultimo invio di email.
  void _checkRateLimit(String errorMessage) {
    if (_lastEmailSent != null &&
        DateTime.now().difference(_lastEmailSent!) <
            const Duration(seconds: 60)) {
      throw AuthException(errorMessage);
    }
  }
}

// --- ECCEZIONI PERSONALIZZATE ---
// Wrapper per gestire errori specifici del service di autenticazione.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}