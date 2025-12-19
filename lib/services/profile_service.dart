// profile_service.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:path_provider/path_provider.dart';

class ProfileService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  fb_auth.User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // 🔄 REFRESH UTENTE
  // ---------------------------------------------------------------------------
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // ---------------------------------------------------------------------------
  // 💾 SALVATAGGIO IMMAGINE (File System)
  // ---------------------------------------------------------------------------
  /// Prende un file (selezionato dal picker nel provider) e lo salva in locale
  Future<File> saveLocalImage(File sourceFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final destination = '${appDir.path}/profile_picture.jpg';
      
      // Copia il file
      final savedImage = await sourceFile.copy(destination);
      
      // Svuota la cache dell'immagine vecchia
      // Nota: FileImage eviction è un concetto di Flutter Painting, 
      // ma dato che è legato al file system, possiamo lasciarlo gestire al Provider 
      // o farlo qui se importiamo painting. Per purezza, meglio che il service ritorni il File.
      
      return savedImage;
    } catch (e) {
      throw ProfileException("Errore durante il salvataggio immagine: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🗑 RIMOZIONE IMMAGINE
  // ---------------------------------------------------------------------------
  Future<void> deleteLocalImage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/profile_picture.jpg');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw ProfileException("Errore rimozione immagine: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 📂 CARICAMENTO IMMAGINE ESISTENTE
  // ---------------------------------------------------------------------------
  Future<File?> getLocalImage() async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/profile_picture.jpg');
    return (await file.exists()) ? file : null;
  }

  // ---------------------------------------------------------------------------
  // 📝 UPDATE DISPLAY NAME
  // ---------------------------------------------------------------------------
  Future<void> updateDisplayName(String newName) async {
    try {
      await _auth.currentUser?.updateDisplayName(newName);
      await reloadUser();
    } catch (e) {
      throw ProfileException("Errore aggiornamento nome: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 📧 UPDATE EMAIL
  // ---------------------------------------------------------------------------
  Future<void> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw ProfileException("Utente non trovato");

    try {
      // 1. Re-autenticazione
      final cred = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      // 2. Verifica prima dell'aggiornamento
      await user.verifyBeforeUpdateEmail(newEmail);

      // 3. Logout (richiesto dal tuo flusso originale)
      await _auth.signOut();
      
    } on fb_auth.FirebaseAuthException catch (e) {
      throw ProfileException("Errore cambio email: ${e.message}");
    }
  }

  // ---------------------------------------------------------------------------
  // 🔒 UPDATE PASSWORD
  // ---------------------------------------------------------------------------
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw ProfileException("Utente non trovato");

    try {
      final cred = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      
    } on fb_auth.FirebaseAuthException catch (e) {
      throw ProfileException("Errore cambio password: ${e.message}");
    }
  }

  // ---------------------------------------------------------------------------
  // 💀 DELETE ACCOUNT
  // ---------------------------------------------------------------------------
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      throw ProfileException("Errore eliminazione account: $e");
    }
  }
}

class ProfileException implements Exception {
  final String message;
  ProfileException(this.message);
  @override
  String toString() => message;
}