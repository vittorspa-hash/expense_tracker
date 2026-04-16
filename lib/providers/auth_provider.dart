import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/services/auth_service.dart';

/// FILE: auth_provider.dart
/// DESCRIZIONE: State Manager per l'autenticazione (ChangeNotifier).
/// Agisce come intermediario tra la UI e l'AuthService, gestendo lo stato di
/// caricamento (loading spinners) e propagando errori o successi alle viste.

enum AuthStatus { unknown, authenticated, unauthenticated, unverified }

class AuthProvider extends ChangeNotifier {
  // --- STATO E DIPENDENZE ---
  // Iniezione del servizio di autenticazione e gestione dello stato di caricamento
  final AuthService _authService;
  final FirebaseAuth _firebaseAuth;

  late final StreamSubscription<User?> _authSubscription;
  AuthStatus _authStatus = AuthStatus.unknown;
  AuthStatus get authStatus => _authStatus;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  User? get currentUser => _firebaseAuth.currentUser;

  AuthProvider({
    required AuthService authService,
    required FirebaseAuth firebaseAuth,
  }) : _authService = authService,
       _firebaseAuth = firebaseAuth {
    // Sottoscrizione allo stream Firebase: aggiorna authStatus e notifica la UI.
    _authSubscription = _firebaseAuth.idTokenChanges().listen(
      _onAuthStateChanged,
    );
  }

  void _onAuthStateChanged(User? user) {
    if (user == null) {
      _authStatus = AuthStatus.unauthenticated;
    } else if (!user.emailVerified) {
      _authStatus = AuthStatus.unverified;
    } else {
      _authStatus = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel(); // evita memory leak
    super.dispose();
  }

  // --- REGISTRAZIONE ---
  // Coordina la creazione dell'account gestendo il loading state.
  // Gli errori (es. email duplicata) vengono rilanciati alla UI per la gestione visiva.
  Future<void> signUp({
    required String email,
    required String password,
    required String nome,
  }) async {
    _setLoading(true);
    try {
      await _authService.signUp(email: email, password: password, nome: nome);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- LOGIN ---
  // Gestisce l'accesso e restituisce l'oggetto User.
  // Questo permette alla UI di verificare immediatamente lo stato (es. emailVerified)
  // e decidere se procedere alla Home o mostrare avvisi.
  Future<User> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      final user = await _authService.signIn(email: email, password: password);
      return user;
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- LOGOUT ---
  // Esegue la disconnessione e notifica i listener per aggiornare il routing
  // (es. AuthWrapper reindirizza al Login).
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // --- GESTIONE ACCOUNT ---
  // Metodi di supporto per il recupero password e l'invio manuale
  // dell'email di verifica (utilizzato nei dialog di avviso).
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

  Future<void> sendVerificationEmail(User user) async {
    _setLoading(true);
    try {
      await _authService.sendVerificationEmail(user);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- HELPER INTERNI ---
  // Utility per aggiornare lo stato di caricamento e notificare la UI in un unico passaggio.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
