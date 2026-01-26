import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart'; 
import 'package:flutter/painting.dart'; 
import 'package:expense_tracker/services/profile_service.dart';

/// FILE: profile_provider.dart
/// DESCRIZIONE: State Manager per il profilo utente.
/// Agisce da intermediario tra la UI e il ProfileService, gestendo:
/// 1. Lo stato dell'immagine locale (caricamento, cache eviction, aggiornamento).
/// 2. Lo stato di caricamento (loading spinner) per operazioni lunghe.
/// 3. La propagazione delle modifiche ai dati utente (Nome, Email, Password).

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;

  ProfileProvider({required ProfileService profileService})
    : _profileService = profileService;

  // --- STATO E GETTERS ---
  // Gestione dello stato interno (File immagine, flag loading) e proxy
  // verso l'utente Firebase corrente per l'accesso in sola lettura.
  File? _localImage;
  File? get localImage => _localImage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  fb_auth.User? get user => _profileService.currentUser;

  // --- INIZIALIZZAZIONE E REFRESH ---
  // Metodi per il caricamento iniziale dell'immagine dal disco e per
  // la sincronizzazione manuale (pull-to-refresh) dei dati utente da Firebase.
  Future<void> loadLocalData() async {
  try {
    _localImage = await _profileService.getLocalImage();
  } catch (e) {
    _localImage = null; // Fallback sicuro
  } finally {
    notifyListeners();
  }
}

  Future<void> refreshUser() async {
    try {
      await _profileService.reloadUser();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // --- GESTIONE IMMAGINE PROFILO ---
  // Gestisce il salvataggio e la rimozione dell'immagine.
  // CRITICO: Esegue l'invalidazione della cache (evict) e la pulizia della ImageCache
  // globale per garantire che la UI mostri subito la nuova foto sovrascritta.
  // 
  Future<void> setProfileImage(File imageFile) async {
    _setLoading(true);
    try {
      final savedFile = await _profileService.saveLocalImage(imageFile);

      // Invalida la cache dell'immagine precedente
      await FileImage(savedFile).evict();

      // Pulizia extra cache globale (opzionale ma consigliato)
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      _localImage = savedFile;
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProfileImage() async {
    try {
      await _profileService.deleteLocalImage();
      _localImage = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // --- AGGIORNAMENTO DATI UTENTE ---
  // Metodi wrapper che gestiscono il loading state durante le chiamate asincrone
  // al service per modificare nome, email e password.
  Future<void> updateDisplayName(String newName) async {
    if (newName.isEmpty) return;

    _setLoading(true);
    try {
      await _profileService.updateDisplayName(newName);
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _profileService.updateEmail(newEmail: newEmail, password: password);
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _profileService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- ELIMINAZIONE ACCOUNT ---
  // Avvia la procedura di cancellazione definitiva.
  Future<void> deleteAccount() async {
    _setLoading(true);
    try {
      await _profileService.deleteAccount();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}