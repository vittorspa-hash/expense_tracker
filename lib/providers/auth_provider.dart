import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Assicurati che questi import puntino ai file corretti nel tuo progetto
import 'package:expense_tracker/services/auth_service.dart'; // Il file che hai appena modificato
import 'package:expense_tracker/utils/dialog_utils.dart';
import 'package:expense_tracker/theme/app_colors.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({required AuthService authService})
      : _authService = authService;

  // Stato per gestire caricamenti (utile per mostrare spinner nei pulsanti)
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Getter per l'utente corrente
  User? get currentUser => _authService.currentUser;

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
    // 1. Validazione UI (password match)
    if (password != confermaPassword) {
      _showSnack(context, "Le password non coincidono");
      return;
    }

    _setLoading(true);

    try {
      // 2. Chiamata alla Logica Pura
      await _authService.signUp(
        email: email, 
        password: password, 
        nome: nome
      );

      _setLoading(false);

      // 3. Callback di successo (navigazione)
      onSuccess();

      // 4. Feedback Utente (Dialog)
      if (context.mounted) {
        await DialogUtils.showInfoDialog(
          context,
          title: "Verifica Email",
          content: "Ti abbiamo inviato una email di verifica. Controlla la tua casella di posta.",
        );
      }

    } on AuthException catch (e) {
      _setLoading(false);
      if (context.mounted) _showSnack(context, e.message);
    } catch (e) {
      _setLoading(false);
      if (context.mounted) _showSnack(context, "Errore imprevisto: $e");
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
    _setLoading(true);

    try {
      // 1. Chiamata alla Logica
      final user = await _authService.signIn(email: email, password: password);
      
      _setLoading(false);

      if (!context.mounted) return;

      // 2. Controllo Email Verificata (Logica di flusso UI)
      if (!user.emailVerified) {
        await _handleUnverifiedUser(context, user);
        return; // Blocchiamo il login qui
      }

      // 3. Successo
      onSuccess();

    } on AuthException catch (e) {
      _setLoading(false);
      if (context.mounted) _showSnack(context, e.message);
    } catch (e) {
      _setLoading(false);
      if (context.mounted) _showSnack(context, "Errore imprevisto durante il login.");
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 LOGOUT UTENTE
  // ---------------------------------------------------------------------------
  Future<void> signOut(BuildContext context, {required VoidCallback onSuccess}) async {
    try {
      await _authService.signOut();
      debugPrint('✅ Logout completato con successo');
      onSuccess();
    } on AuthException catch (e) {
      if (context.mounted) _showSnack(context, e.message);
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 RESET PASSWORD
  // ---------------------------------------------------------------------------
  Future<void> resetPassword(
    BuildContext context, {
    String? email,
    String? customSuccessMessage,
  }) async {
    _setLoading(true);

    try {
      await _authService.resetPassword(email);
      
      _setLoading(false);

      if (context.mounted) {
        final message = customSuccessMessage ??
            "Se l'email è registrata, riceverai un link per reimpostare la password.";
        _showSnack(context, message);
      }
    } on AuthException catch (e) {
      _setLoading(false);
      if (context.mounted) _showSnack(context, e.message);
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 LOGICA DIALOGO EMAIL NON VERIFICATA
  // ---------------------------------------------------------------------------
  Future<void> _handleUnverifiedUser(BuildContext context, User user) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: "Email non verificata",
      content: "Devi confermare la tua email prima di accedere.",
      confirmText: "Rinvia Email",
      cancelText: "OK",
    );

    if (!context.mounted) return;

    if (confirmed == true) {
      try {
        await _authService.sendVerificationEmail(user);
        if (context.mounted) _showSnack(context, "Email di verifica inviata!");
      } on AuthException catch (e) {
        if (context.mounted) _showSnack(context, e.message);
      }
    } else {
      // Logout se l'utente rifiuta o chiude il dialog senza verificare
      await _authService.signOut();
    }
  }

  // ---------------------------------------------------------------------------
  // 🛠 UTILS
  // ---------------------------------------------------------------------------
  
  // Gestione stato di caricamento e notifica ai listener (la UI si aggiorna)
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Helper per mostrare SnackBar
  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.snackBar,
        content: Text(msg, style: TextStyle(color: AppColors.textLight)),
      ),
    );
  }
}