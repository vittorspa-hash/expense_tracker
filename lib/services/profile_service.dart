import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:path_provider/path_provider.dart';

/// FILE: profile_service.dart
/// DESCRIZIONE: Service che gestisce le operazioni sul profilo utente.
/// Si occupa della persistenza locale dell'immagine profilo (utilizzando l'UID
/// per garantire univocità) e comunica con Firebase Auth per aggiornare
/// dati sensibili come Nome, Email e Password.

class ProfileService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  fb_auth.User? get currentUser => _auth.currentUser;

  // --- GESTIONE FILE LOCALE ---
  // Genera il percorso del file immagine basandosi sull'UID dell'utente corrente.
  // Questo previene conflitti di sovrascrittura tra utenti diversi sullo stesso dispositivo.
  // 
  Future<File> _getUserFile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ProfileException(
        "No user logged in: cannot handle image.",
      );
    }

    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/profile_pic_${user.uid}.jpg');
  }

  // --- SINCRONIZZAZIONE ---
  // Ricarica i dati dell'utente da Firebase per assicurarsi di avere lo stato più recente.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // --- GESTIONE IMMAGINE PROFILO ---
  // Metodi per salvare, recuperare ed eliminare l'immagine del profilo dalla memoria locale.
  Future<File> saveLocalImage(File sourceFile) async {
    try {
      final destinationFile = await _getUserFile();

      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }

      final savedImage = await sourceFile.copy(destinationFile.path);

      return savedImage;
    } catch (e) {
      throw ProfileException("Error saving image: $e");
    }
  }

  Future<void> deleteLocalImage() async {
    try {
      final file = await _getUserFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw ProfileException("Error removing image: $e");
    }
  }

  Future<File?> getLocalImage() async {
    try {
      final file = await _getUserFile();
      return (await file.exists()) ? file : null;
    } catch (e) {
      return null;
    }
  }

  // --- AGGIORNAMENTO DATI UTENTE ---
  // Wrapper per le chiamate a Firebase Auth per modificare i dati anagrafici.
  Future<void> updateDisplayName(String newName) async {
    try {
      await _auth.currentUser?.updateDisplayName(newName);
      await reloadUser();
    } catch (e) {
      throw ProfileException("Error updating name: $e");
    }
  }

  // --- OPERAZIONI SENSIBILI (EMAIL & PASSWORD) ---
  // Richiedono la ri-autenticazione dell'utente per motivi di sicurezza
  // prima di procedere con le modifiche.
  Future<void> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw ProfileException("User not found");

    try {
      // 1. Re-autenticazione
      final cred = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      // 2. Verifica e Logout
      await user.verifyBeforeUpdateEmail(newEmail);
      await _auth.signOut();
    } on fb_auth.FirebaseAuthException catch (e) {
      throw ProfileException("Error changing email: ${e.message}");
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw ProfileException("User not found");

    try {
      final cred = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw ProfileException("Error changing password: ${e.message}");
    }
  }

  // --- ELIMINAZIONE ACCOUNT ---
  // Rimuove definitivamente l'utente da Firebase Auth.
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      throw ProfileException("Error deleting account: $e");
    }
  }
}

// --- ECCEZIONI PERSONALIZZATE ---
class ProfileException implements Exception {
  final String message;
  ProfileException(this.message);
  @override
  String toString() => message;
}