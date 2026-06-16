import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: auth_notifier.dart
/// DESCRIZIONE: Gestore dello stato di autenticazione (AuthState) basato sullo stream
/// di Firebase. Utilizza StreamNotifier per mappare i cambiamenti di sessione in uno
/// dei tre stati possibili: authenticated, unverified, unauthenticated.
/// Le azioni (signIn, signUp, signOut, ecc.) delegano la logica ad AuthService e
/// gestiscono il flag isLoading senza interrompere lo stream sottostante.

enum AuthStatus { authenticated, unauthenticated, unverified }

// --- STATO ---
class AuthState {
  final AuthStatus authStatus;
  final User? user;
  final bool isLoading;

  const AuthState({
    required this.authStatus,
    this.user,
    this.isLoading = false,
  });

  /// Crea una copia dello stato modificando solo i campi necessari.
  /// Preserva l'utente corrente proveniente dallo stream anche durante le azioni.
  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    bool? isLoading,
  }) {
    return AuthState(
      authStatus: authStatus ?? this.authStatus,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- NOTIFIER ---
/// StreamNotifier che espone lo stato di autenticazione derivato dallo stream
/// idTokenChanges() di Firebase. Ogni emissione del token aggiorna automaticamente
/// lo stato; le azioni usano _setLoading per segnalare operazioni in corso
/// senza interrompere o sostituire lo stream attivo.
class AuthNotifier extends StreamNotifier<AuthState> {
  AuthService get _authService => ref.read(authServiceProvider);

  @override
  Stream<AuthState> build() {
    return ref.watch(firebaseAuthProvider).idTokenChanges().map((user) {
      if (user == null) {
        return const AuthState(authStatus: AuthStatus.unauthenticated);
      }
      if (!user.emailVerified) {
        return AuthState(authStatus: AuthStatus.unverified, user: user);
      }
      return AuthState(authStatus: AuthStatus.authenticated, user: user);
    });
  }

  // --- HELPERS PRIVATI ---
  /// Aggiorna il flag isLoading preservando lo stato corrente dello stream.
  /// Usa AsyncData invece di AsyncLoading per evitare di distruggere lo stato esistente.
  void _setLoading(bool loading) {
    state = AsyncData(state.value!.copyWith(isLoading: loading));
  }

  // --- AZIONI ED OPERAZIONI ---
  /// Effettua il login delegando ad AuthService; rilancia l'eccezione alla UI in caso di errore.
  Future<void> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _authService.signIn(email: email, password: password);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Registra un nuovo utente delegando ad AuthService; rilancia l'eccezione alla UI in caso di errore.
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

  /// Termina la sessione corrente delegando ad AuthService; rilancia l'eccezione alla UI in caso di errore.
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Invia l'email di reset password delegando ad AuthService; rilancia l'eccezione alla UI in caso di errore.
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

  /// Invia nuovamente l'email di verifica all'utente specificato; rilancia l'eccezione alla UI in caso di errore.
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
}