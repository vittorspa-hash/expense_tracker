// profile_provider.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart'; // Per ChangeNotifier
import 'package:flutter/painting.dart'; // Per FileImage e gestione cache
import 'package:flutter/services.dart'; // Per Clipboard

// Importa i tuoi file
import 'package:expense_tracker/services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;

  ProfileProvider({required ProfileService profileService})
    : _profileService = profileService;

  // Stato Locale
  File? _localImage;
  File? get localImage => _localImage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Utente corrente (proxy verso il service)
  fb_auth.User? get user => _profileService.currentUser;

  // ---------------------------------------------------------------------------
  // 🚀 INIZIALIZZAZIONE
  // ---------------------------------------------------------------------------
  Future<void> loadLocalData() async {
    _localImage = await _profileService.getLocalImage();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 🔄 REFRESH UTENTE
  // ---------------------------------------------------------------------------
  Future<void> refreshUser() async {
    // Non gestiamo try/catch qui per la UI, ma solo per lo stato interno se necessario.
    // Rilanciamo l'errore affinché la UI possa mostrare la SnackBar di errore.
    try {
      await _profileService.reloadUser();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📸 IMPOSTA IMMAGINE (L'UI deve fornire il File)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // ❌ RIMUOVI IMMAGINE
  // ---------------------------------------------------------------------------
  Future<void> deleteProfileImage() async {
    // Nota: Nessun dialog qui. Il dialog è responsabilità della UI.
    try {
      await _profileService.deleteLocalImage();
      _localImage = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📝 MODIFICA NOME
  // ---------------------------------------------------------------------------
  Future<void> updateDisplayName(String newName) async {
    if (newName.isEmpty) return;

    _setLoading(true);
    try {
      await _profileService.updateDisplayName(newName);
      // reloadUser viene spesso chiamato internamente dal service,
      // ma notifyListeners aggiorna la UI qui.
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 📧 MODIFICA EMAIL
  // ---------------------------------------------------------------------------
  Future<void> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _profileService.updateEmail(newEmail: newEmail, password: password);
      // Logout gestito dalla UI o dal Service, qui aggiorniamo solo lo stato se serve
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 🔒 MODIFICA PASSWORD
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // 🗑 ELIMINA ACCOUNT
  // ---------------------------------------------------------------------------
  Future<void> deleteAccount() async {
    _setLoading(true);
    try {
      await _profileService.deleteAccount();
      // La navigazione di logout deve avvenire nella UI dopo che questo Future si completa
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 📋 UTILS
  // ---------------------------------------------------------------------------
  /// Copia il testo. Ritorna true se ha successo (così la UI mostra la snackbar)
  Future<void> copyToClipboard(String? text) async {
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
