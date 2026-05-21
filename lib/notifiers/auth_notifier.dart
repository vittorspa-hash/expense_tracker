import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: auth_notifier.dart
/// DESCRIZIONE: Gestisce lo stato globale di autenticazione dell'applicazione.
/// Ascolta in tempo reale i cambiamenti di sessione da Firebase Auth e coordina
/// le operazioni di Login, Registrazione, Logout e recupero credenziali,
/// esponendo uno stato immutabile (AuthState) alla UI.

enum AuthStatus { unknown, authenticated, unauthenticated, unverified }

// --- STATO ---
/// Rappresentazione immutabile dello stato di autenticazione e caricamento.
class AuthState {
  final AuthStatus authStatus;
  final bool isLoading;

  const AuthState({
    this.authStatus = AuthStatus.unknown,
    this.isLoading = false,
  });

  /// Metodo per generare una nuova istanza dello stato modificandone selettivamente i parametri.
  AuthState copyWith({AuthStatus? authStatus, bool? isLoading}) {
    return AuthState(
      authStatus: authStatus ?? this.authStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- NOTIFIER ---
/// Controller reattivo dello stato di autenticazione che estende la classe Notifier di Riverpod.
class AuthNotifier extends Notifier<AuthState> {
  
  @override
  AuthState build() {
    final firebaseAuth = ref.watch(firebaseAuthProvider);

    // Sottoscrizione allo stream dei token per monitorare lo stato utente.
    // La cancellazione (cancel) viene gestita manualmente al dispose del provider per prevenire leak.
    final sub = firebaseAuth.idTokenChanges().listen(_onAuthStateChanged);
    ref.onDispose(() => sub.cancel());

    return const AuthState();
  }

  // --- GESTORE CAMBIAMENTI DI STATO ---
  /// Intercetta le variazioni di Firebase User e aggiorna l'AuthStatus dello stato.
  void _onAuthStateChanged(User? user) {
    if (user == null) {
      state = state.copyWith(authStatus: AuthStatus.unauthenticated);
    } else if (!user.emailVerified) {
      state = state.copyWith(authStatus: AuthStatus.unverified);
    } else {
      state = state.copyWith(authStatus: AuthStatus.authenticated);
    }
  }

  // --- GETTER DI CONVENIENZA ---
  /// Restituisce l'utente Firebase correntemente in sessione.
  User? get currentUser => ref.read(firebaseAuthProvider).currentUser;
  
  /// Riferimento interno al servizio di autenticazione business.
  AuthService get _authService => ref.read(authServiceProvider);

  // --- OPERAZIONI DI AUTENTICAZIONE ---

  /// Avvia la procedura di registrazione di un nuovo utente.
  Future<void> signUp({
    required String email,
    required String password,
    required String nome,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signUp(email: email, password: password, nome: nome);
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Esegue l'accesso dell'utente tramite email e password.
  Future<User> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    try {
      return await _authService.signIn(email: email, password: password);
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Disconnette l'utente corrente chiudendo la sessione attiva su Firebase.
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // --- GESTIONE ACCOUNT ---

  /// Invia un'email per il ripristino o la reimpostazione della password.
  Future<void> resetPassword({String? email}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Invia una nuova email contenente il link di verifica dell'account.
  Future<void> sendVerificationEmail(User user) async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.sendVerificationEmail(user);
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}