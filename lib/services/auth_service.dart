import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

// Importa la tua classe di eccezione personalizzata se l'hai messa in un altro file,
// altrimenti puoi definirla in fondo a questo file.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Timestamp per rate-limit
  DateTime? _lastEmailSent;

  // Getter utile per l'esterno
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // 🟦 REGISTRAZIONE
  // ---------------------------------------------------------------------------
  Future<void> signUp({
    required String email,
    required String password,
    required String nome,
  }) async {
    try {
      // Nota: Il controllo "password != confermaPassword" deve essere fatto nel UI/Provider prima di chiamare questo metodo.

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      var user = userCredential.user;
      if (user == null){
        throw AuthException("Errore sconosciuto nella creazione utente.");
      }

      await user.updateDisplayName(nome.trim());
      await user.reload();
      user = _auth.currentUser;

      // Invio email di verifica gestito internamente
      await sendVerificationEmail(user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_errorMessageSignup(e));
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 LOGIN
  // ---------------------------------------------------------------------------
  Future<User> signIn({required String email, required String password}) async {
    try {
      var userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      var user = userCredential.user;
      if (user == null) throw AuthException("Utente non trovato.");

      await user.reload();
      // Restituiamo l'utente così il Provider può controllare se emailVerified è true/false
      return _auth.currentUser!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_errorMessageLogin(e));
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 LOGOUT
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException('Errore durante il logout: ${e.message ?? e.code}');
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 RESET PASSWORD
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // 🟦 INVIO EMAIL DI VERIFICA (Con Rate Limit)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // 🛠 HELPER: RATE LIMIT CHECK
  // ---------------------------------------------------------------------------
  void _checkRateLimit(String errorMessage) {
    if (_lastEmailSent != null &&
        DateTime.now().difference(_lastEmailSent!) <
            const Duration(seconds: 60)) {
      throw AuthException(errorMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // 🛠 MAPPATURA ERRORI (Preservata dal tuo codice originale)
  // ---------------------------------------------------------------------------
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

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
