import 'dart:io';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/services/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: profile_notifier.dart
/// DESCRIZIONE: Gestore dello stato del profilo utente (ProfileState).
/// Utilizza AsyncNotifier perché la build() esegue un'operazione asincrona
/// (caricamento dell'avatar locale). Le operazioni successive preservano lo stato
/// esistente tramite AsyncData(state.value!.copyWith(...)) invece di AsyncLoading,
/// evitando flash visivi indesiderati durante gli aggiornamenti.

// --- STATO ---
class ProfileState {
  final User? user;
  final File? localImage;
  final bool isLoading;

  const ProfileState({this.user, this.localImage, this.isLoading = false});

  ProfileState copyWith({
    User? user,
    File? localImage,
    bool? isLoading,
    bool clearImage = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      localImage: clearImage ? null : (localImage ?? this.localImage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- NOTIFIER ---
/// AsyncNotifier che inizializza lo stato caricando l'immagine locale in build().
/// Tutte le azioni usano ref.read(profileServiceProvider) per accedere al service,
/// in quanto le operazioni avvengono fuori dal ciclo di build.
class ProfileNotifier extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    final user = ref.watch(authNotifierProvider.select((s) => s.value?.user));
    final image = await _profileService.getLocalImage();
    return ProfileState(user: user, localImage: image);
  }

  ProfileService get _profileService => ref.read(profileServiceProvider);
  User? get _currentUser => ref.read(firebaseAuthProvider).currentUser;

  // --- SINCRONIZZAZIONE UTENTE ---
  /// Ricarica i dati utente da Firebase e aggiorna lo stato preservando
  /// il resto del ProfileState corrente.
  Future<void> refreshUser() async {
    await _profileService.reloadUser();
    state = AsyncData(state.value!.copyWith(user: _currentUser));
  }

  // --- GESTIONE IMMAGINE PROFILO ---
  /// Salva la nuova immagine localmente e invalida la cache di Flutter
  /// per forzare il refresh visivo dell'avatar in tutta l'app.
  Future<void> setProfileImage(File imageFile) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      final savedFile = await _profileService.saveLocalImage(imageFile);

      // Sfratta l'immagine precedente dalla cache di Flutter per forzare il refresh visivo
      await FileImage(savedFile).evict();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      state = AsyncData(state.value!.copyWith(localImage: savedFile, isLoading: false));
    } catch (e) {
      state = AsyncData(state.value!.copyWith(isLoading: false));
      rethrow;
    }
  }

  /// Elimina l'immagine locale e azzera il campo nel ProfileState tramite clearImage.
  Future<void> deleteProfileImage() async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      await _profileService.deleteLocalImage();
      state = AsyncData(state.value!.copyWith(clearImage: true, isLoading: false));
    } catch (e) {
      state = AsyncData(state.value!.copyWith(isLoading: false));
      rethrow;
    }
  }

  // --- AGGIORNAMENTO DATI UTENTE ---
  /// Aggiorna il nome visualizzato su Firebase e riflette la modifica nello stato locale.
  Future<void> updateDisplayName(String newName) async {
    if (newName.isEmpty) return;
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      await _profileService.updateDisplayName(newName);
      state = AsyncData(state.value!.copyWith(user: _currentUser, isLoading: false));
    } catch (e) {
      state = AsyncData(state.value!.copyWith(isLoading: false));
      rethrow;
    }
  }

  /// Aggiorna l'email su Firebase previa riautenticazione con la password corrente.
  Future<void> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      await _profileService.updateEmail(newEmail: newEmail, password: password);
      state = AsyncData(state.value!.copyWith(user: _currentUser, isLoading: false));
    } catch (e) {
      state = AsyncData(state.value!.copyWith(isLoading: false));
      rethrow;
    }
  }

  /// Aggiorna la password su Firebase previa riautenticazione con la password corrente.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      await _profileService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = AsyncData(state.value!.copyWith(isLoading: false));
    } catch (e) {
      state = AsyncData(state.value!.copyWith(isLoading: false));
      rethrow;
    }
  }

  // --- ELIMINAZIONE ACCOUNT ---
  /// Elimina definitivamente l'account Firebase e azzera l'utente nello stato locale.
  Future<void> deleteAccount() async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      await _profileService.deleteAccount();
      state = AsyncData(state.value!.copyWith(user: null, isLoading: false));
    } catch (e) {
      state = AsyncData(state.value!.copyWith(isLoading: false));
      rethrow;
    }
  }
}