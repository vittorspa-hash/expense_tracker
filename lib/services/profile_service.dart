// profile_service.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:path_provider/path_provider.dart';

class ProfileService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  fb_auth.User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // 🛠 HELPER PRIVATO: Genera il percorso file basato sull'UID
  // ---------------------------------------------------------------------------
  /// Restituisce il riferimento al File specifico per l'utente loggato.
  /// Es: .../documents/profile_pic_AbCdEf123456.jpg
  Future<File> _getUserFile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ProfileException(
        "Nessun utente loggato: impossibile gestire l'immagine.",
      );
    }

    final appDir = await getApplicationDocumentsDirectory();
    // 🔑 QUI È LA MAGIA: Usiamo user.uid nel nome del file
    return File('${appDir.path}/profile_pic_${user.uid}.jpg');
  }

  // ---------------------------------------------------------------------------
  // 🔄 REFRESH UTENTE
  // ---------------------------------------------------------------------------
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // ---------------------------------------------------------------------------
  // 💾 SALVATAGGIO IMMAGINE
  // ---------------------------------------------------------------------------
  Future<File> saveLocalImage(File sourceFile) async {
    try {
      // Ottengo il file di destinazione specifico per questo utente
      final destinationFile = await _getUserFile();

      // Se esiste già un file vecchio per questo utente, lo sovrascriviamo.
      // Opzionale: cancellarlo esplicitamente prima della copia per pulizia
      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }

      // Copia il file dalla cache/galleria alla cartella documenti
      final savedImage = await sourceFile.copy(destinationFile.path);

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
      final file = await _getUserFile();
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
    try {
      final file = await _getUserFile();
      return (await file.exists()) ? file : null;
    } catch (e) {
      // Se non c'è utente loggato (es. fase di logout/inizializzazione),
      // ritorniamo null invece di lanciare eccezione
      return null;
    }
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
