// auth_model.dart
// Modello che gestisce l’intera logica di autenticazione dell’app.
// Include:
// • Registrazione di un nuovo utente con email e password
// • Login con controllo della verifica email
// • Invio email di reset password
// • Prevenzione dell’invio eccessivo di email tramite rate-limit
// • Gestione uniforme degli errori e notifiche tramite SnackBar e dialog personalizzati

import 'package:expense_tracker/models/dialog_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/theme/app_colors.dart';

class AuthModel {
  // Istanza principale per gestire l’autenticazione tramite Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Timestamp dell’ultima email inviata (verifica o reset), usato per limitare gli invii
  DateTime? _lastEmailSent;

  // ---------------------------------------------------------------------------
  // 🟦 REGISTRAZIONE UTENTE
  // ---------------------------------------------------------------------------
  Future<void> signUp({
    required BuildContext context,
    required String email,
    required String password,
    required String confermaPassword,
    required String nome,
    required VoidCallback onSuccess,
  }) async {
    if (password != confermaPassword) {
      _showSnack(context, "Le password non coincidono");
      return;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      var user = userCredential.user;
      if (user == null) return;

      // Imposta il nome e aggiorna l’istanza utente
      await user.updateDisplayName(nome.trim());
      await user.reload();
      user = _auth.currentUser;

      // Limita l’invio eccessivo delle email di verifica
      if (_lastEmailSent != null &&
          DateTime.now().difference(_lastEmailSent!) <
              const Duration(seconds: 60)) {
        if (!context.mounted) return;
        _showSnack(
          context,
          "Attendi almeno 1 minuto prima di rinviare l'email di conferma.",
        );
        return;
      }

      // Invia email di verifica
      await user!.sendEmailVerification();
      _lastEmailSent = DateTime.now();

      if (!context.mounted) return;
      await DialogModel.showInfoDialog(
        context,
        title: "Verifica Email",
        content:
            "Ti abbiamo inviato una email di verifica. Controlla la tua casella di posta.",
      );

      onSuccess();
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      _showSnack(context, _errorMessageSignup(e));
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 LOGIN UTENTE
  // ---------------------------------------------------------------------------
  Future<void> signIn({
    required BuildContext context,
    required String email,
    required String password,
    required VoidCallback onSuccess,
  }) async {
    try {
      var userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      var user = userCredential.user;
      if (user == null) return;

      // Aggiorna lo stato dell’utente
      await user.reload();
      user = _auth.currentUser;

      if (!context.mounted) return;

      // Blocca l'accesso se l'email non è ancora verificata
      if (!user!.emailVerified) {
        await _showUnverifiedDialog(context, user);
        return;
      }

      onSuccess();
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      _showSnack(context, _errorMessageLogin(e));
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 RESET PASSWORD
  // ---------------------------------------------------------------------------
  Future<void> resetPassword(BuildContext context, String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      _showSnack(context, "Inserisci l'email.");
      return;
    }

    // Applica un limite per evitare invii ravvicinati
    if (_lastEmailSent != null &&
        DateTime.now().difference(_lastEmailSent!) <
            const Duration(seconds: 60)) {
      _showSnack(
        context,
        "Attendi almeno 1 minuto prima di richiedere un'altra email di reset.",
      );
      return;
    }

    try {
      // Invio email di ripristino password
      await _auth.sendPasswordResetEmail(email: trimmed);
      _lastEmailSent = DateTime.now();

      if (!context.mounted) return;
      await DialogModel.showInfoDialog(
        context,
        title: "Email inviata",
        content:
            "Se l'email è registrata, riceverai un link per reimpostare la password.",
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      _showSnack(context, _errorMessageReset(e));
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 EMAIL NON VERIFICATA — DIALOG DI CONFERMA
  // ---------------------------------------------------------------------------
  Future<void> _showUnverifiedDialog(BuildContext context, User user) async {
    if (!context.mounted) return;

    final confirmed = await DialogModel.showConfirmDialog(
      context,
      title: "Email non verificata",
      content: "Devi confermare la tua email prima di accedere.",
      confirmText: "Rinvia Email",
      cancelText: "OK",
    );

    if (confirmed == true) {
      // Rate-limit dell’invio email
      if (_lastEmailSent != null &&
          DateTime.now().difference(_lastEmailSent!) <
              const Duration(seconds: 60)) {
        if (context.mounted) {
          _showSnack(
            context,
            "Attendi almeno 1 minuto prima di rinviare l'email.",
          );
        }
        return;
      }

      try {
        await user.sendEmailVerification();
        _lastEmailSent = DateTime.now();

        if (context.mounted) {
          _showSnack(context, "Email di verifica inviata!");
        }
      } on FirebaseAuthException {
        if (context.mounted) {
          _showSnack(context, "Errore invio email di verifica.");
        }
      }
    } else {
      // Logout se l'utente rifiuta
      if (context.mounted) {
        await _auth.signOut();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 SNACKBAR UTILE PER ERRORI E NOTIFICHE
  // ---------------------------------------------------------------------------
  void _showSnack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.snackBar,
        content: Text(msg, style: TextStyle(color: AppColors.textLight)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🟦 MAPPATURA ERRORI — SIGNUP
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

  // ---------------------------------------------------------------------------
  // 🟦 MAPPATURA ERRORI — LOGIN
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // 🟦 MAPPATURA ERRORI — RESET PASSWORD
  // ---------------------------------------------------------------------------
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
