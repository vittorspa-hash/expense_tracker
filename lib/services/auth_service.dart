import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

/// FILE: auth_service.dart
/// DESCRIZIONE: Service che gestisce l'interazione diretta con Firebase Authentication.
/// Fornisce metodi per registrazione, login, logout e reset password, incapsulando
/// la gestione degli errori (traduzione codici) e implementando un rate-limit
/// di sicurezza per l'invio delle email di sistema.

class AuthService {
  // --- CONFIGURAZIONE E STATO ---
  // Istanza di Firebase Auth e timestamp per gestire il rate-limit delle email.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime? _lastEmailSent;

  User? get currentUser => _auth.currentUser;

  // --- REGISTRAZIONE UTENTE ---
  // Crea un nuovo utente su Firebase, aggiorna il nome visualizzato (DisplayName)
  // e invia automaticamente l'email di verifica.
  Future<void> signUp({
    required String email,
    required String password,
    required String nome,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      var user = userCredential.user;
      if (user == null){
        throw AuthException("Errore sconosciuto nella creazione utente.");
      }

      // Aggiornamento profilo e ricarica stato utente
      await user.updateDisplayName(nome.trim());
      await user.reload();
      user = _auth.currentUser;

      // Invio email di verifica gestito internamente
      await sendVerificationEmail(user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_errorMessageSignup(e));
    }
  }

  // --- ACCESSO ---
  // Effettua il login con email e password. Ricarica lo stato dell'utente
  // per garantire che il flag 'emailVerified' sia aggiornato prima di restituirlo.
  Future<User> signIn({required String email, required String password}) async {
    try {
      var userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      var user = userCredential.user;
      if (user == null) throw AuthException("Utente non trovato.");

      await user.reload();
      return _auth.currentUser!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_errorMessageLogin(e));
    }
  }

  // --- DISCONNESSIONE ---
  // Termina la sessione corrente su Firebase.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException('Errore durante il logout: ${e.message ?? e.code}');
    }
  }

  // --- RECUPERO PASSWORD ---
  // Invia un link per il reset della password all'email specificata.
  // Include un controllo di rate-limit per prevenire spam.
  Future<void> resetPassword(String? email) async {
    final targetEmail = email?.trim() ?? _auth.currentUser?.email;

    if (targetEmail == null || targetEmail.isEmpty) {
      throw AuthException("Inserisci l'email.");
    }

    _checkRateLimit(
      "Attendi almeno 1 minuto prima di richiedere un'altra email di reset.",
    );

    try {
      await _auth.sendPasswordResetEmail(email: targetEmail);
      _lastEmailSent = DateTime.now();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_errorMessageReset(e));
    }
  }

  // --- VERIFICA EMAIL ---
  // Invia nuovamente l'email di conferma all'utente corrente.
  // Soggetto a rate-limit (60 secondi).
  Future<void> sendVerificationEmail([User? user]) async {
    final u = user ?? _auth.currentUser;
    if (u == null) throw AuthException("Nessun utente loggato.");

    _checkRateLimit(
      "Attendi almeno 1 minuto prima di rinviare l'email di conferma.",
    );

    try {
      await u.sendEmailVerification();
      _lastEmailSent = DateTime.now();
    } on FirebaseAuthException {
      throw AuthException("Errore invio email di verifica.");
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

  // --- MAPPATURA ERRORI ---
  // Metodi helper per tradurre i codici di errore Firebase in messaggi
  // leggibili in italiano per l'utente finale.
  String _errorMessageSignup(FirebaseAuthException e) {
    switch (e.code) {
      case "email-already-in-use":
        return "Questa email è già registrata.";
      case "invalid-email":
        return "Email non valida.";
      case "weak-password":
        return "La password è troppo debole (almeno 6 caratteri).";
      case "too-many-requests":
        return "Hai fatto troppe richieste. Riprova più tardi.";
      default:
        return "Errore durante la registrazione.";
    }
  }

  String _errorMessageLogin(FirebaseAuthException e) {
    switch (e.code) {
      case "user-not-found":
        return "Utente non trovato.";
      case "wrong-password":
        return "Password errata.";
      case "invalid-email":
        return "Email non valida.";
      case "too-many-requests":
        return "Hai fatto troppe richieste. Riprova più tardi.";
      default:
        return "Errore durante il login.";
    }
  }

  String _errorMessageReset(FirebaseAuthException e) {
    switch (e.code) {
      case "user-not-found":
        return "Utente non trovato.";
      case "invalid-email":
        return "Email non valida.";
      case "too-many-requests":
        return "Hai fatto troppe richieste. Riprova più tardi.";
      default:
        return "Errore durante il reset della password.";
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