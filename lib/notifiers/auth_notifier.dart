import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, unverified }

// --- STATO ---
class AuthState {
  final AuthStatus authStatus;
  final bool isLoading;

  const AuthState({
    this.authStatus = AuthStatus.unknown,
    this.isLoading = false,
  });

  AuthState copyWith({AuthStatus? authStatus, bool? isLoading}) {
    return AuthState(
      authStatus: authStatus ?? this.authStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- NOTIFIER ---
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final firebaseAuth = ref.watch(firebaseAuthProvider);

    // ref.listen dentro build() sostituisce il StreamSubscription.
    // Riverpod gestisce automaticamente la cancellazione quando il provider
    // viene dismesso, eliminando il rischio di memory leak.
    final sub = firebaseAuth.idTokenChanges().listen(_onAuthStateChanged);
    ref.onDispose(() => sub.cancel());

    return const AuthState();
  }

  void _onAuthStateChanged(User? user) {
    if (user == null) {
      state = state.copyWith(authStatus: AuthStatus.unauthenticated);
    } else if (!user.emailVerified) {
      state = state.copyWith(authStatus: AuthStatus.unverified);
    } else {
      state = state.copyWith(authStatus: AuthStatus.authenticated);
    }
  }

  // Getter di convenienza
  User? get currentUser => ref.read(firebaseAuthProvider).currentUser;
  AuthService get _authService => ref.read(authServiceProvider);

  // --- REGISTRAZIONE ---
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

  // --- LOGIN ---
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

  // --- LOGOUT ---
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // --- GESTIONE ACCOUNT ---
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