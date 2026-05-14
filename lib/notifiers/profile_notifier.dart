import 'dart:io';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/services/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- STATO ---
class ProfileState {
  final fb_auth.User? user;
  final File? localImage;
  final bool isLoading;

  const ProfileState({this.user,this.localImage, this.isLoading = false});

  ProfileState copyWith({fb_auth.User? user,File? localImage, bool? isLoading, bool clearImage = false}) {
    return ProfileState(
      user: user ?? this.user,
      localImage: clearImage ? null : (localImage ?? this.localImage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- NOTIFIER ---
class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return ProfileState(user: _profileService.currentUser);
  }

  ProfileService get _profileService => ref.read(profileServiceProvider);

  // --- INIZIALIZZAZIONE E REFRESH ---
  Future<void> loadLocalData() async {
    try {
      final image = await _profileService.getLocalImage();
      state = state.copyWith(localImage: image);
    } catch (e) {
      state = state.copyWith(clearImage: true);
    }
  }

  Future<void> refreshUser() async {
    try {
      await _profileService.reloadUser();
      // Forza rebuild della UI notificando un nuovo state identico
      state = state.copyWith(user: _profileService.currentUser);
    } catch (e) {
      rethrow;
    }
  }

  // --- GESTIONE IMMAGINE PROFILO ---
  Future<void> setProfileImage(File imageFile) async {
    state = state.copyWith(isLoading: true);
    try {
      final savedFile = await _profileService.saveLocalImage(imageFile);
      await FileImage(savedFile).evict();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      state = state.copyWith(localImage: savedFile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteProfileImage() async {
    state = state.copyWith(isLoading: true);
    try {
      await _profileService.deleteLocalImage();
      state = state.copyWith(clearImage: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  // --- AGGIORNAMENTO DATI UTENTE ---
  Future<void> updateDisplayName(String newName) async {
    if (newName.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      await _profileService.updateDisplayName(newName);
      state = state.copyWith(user: _profileService.currentUser, isLoading: false,);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _profileService.updateEmail(newEmail: newEmail, password: password);
      state = state.copyWith(user: _profileService.currentUser,isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _profileService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  // --- ELIMINAZIONE ACCOUNT ---
  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      await _profileService.deleteAccount();
      state = state.copyWith(user: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}