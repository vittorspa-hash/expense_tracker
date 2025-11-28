// profile_model.dart
// -----------------------------------------------------------------------------
// 🧩 ProfileModel – Gestione logica e dati del profilo utente
//
// Responsabilità principali:
// - Gestione immagine profilo: caricamento locale, cambio e rimozione
// - Aggiornamento dati account: nome, email e password
// - Reset password via email
// - Eliminazione account con conferma
// - Funzioni ausiliarie: refresh dati utente, copia ID negli appunti
// -----------------------------------------------------------------------------
// NOTE:
// Questo model utilizza callback per aggiornare la UI (setState) e SnackBar
// per mostrare messaggi di conferma o errore.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:expense_tracker/models/dialog_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:expense_tracker/theme/app_colors.dart';

class ProfileModel {
  // ---------------------------------------------------------------------------
  // 🔧 Stato e risorse
  // ---------------------------------------------------------------------------

  /// Gestore immagini da galleria
  final picker = ImagePicker();

  /// Utente Firebase attualmente autenticato
  fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;

  /// Immagine profilo locale
  File? localImage;

  /// Flag stato caricamento immagine
  bool isUploading = false;

  // ---------------------------------------------------------------------------
  // 🔄 Aggiorna dati utente da Firebase
  // ---------------------------------------------------------------------------
  Future<void> refreshUser(
    BuildContext context,
    VoidCallback onUserUpdated,
  ) async {
    await user?.reload();
    user = fb_auth.FirebaseAuth.instance.currentUser;
    onUserUpdated();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Dati profilo aggiornati",
          style: TextStyle(color: AppColors.textLight),
        ),
        backgroundColor: AppColors.snackBar,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📸 Cambia immagine profilo scegliendola dalla galleria
  // ---------------------------------------------------------------------------
  Future<void> changeProfilePicture(
    BuildContext context,
    VoidCallback onUpdated,
  ) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    isUploading = true;
    onUpdated();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final savedImage = await File(
        pickedFile.path,
      ).copy('${appDir.path}/profile_picture.jpg');

      // Aggiorna cache immagine
      final provider = FileImage(savedImage);
      await provider.evict();

      localImage = savedImage;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Immagine profilo aggiornata!",
              style: TextStyle(color: AppColors.textLight),
            ),
            backgroundColor: AppColors.snackBar,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Errore durante il salvataggio: $e",
            style: TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.snackBar,
        ),
      );
    } finally {
      isUploading = false;
      onUpdated();
    }
  }

  // ---------------------------------------------------------------------------
  // ❌ Rimuove immagine profilo con conferma popup adattivo
  // ---------------------------------------------------------------------------
  Future<void> removeProfilePicture(
    BuildContext context,
    VoidCallback onUpdated,
  ) async {
    final confirm = await DialogModel.showConfirmDialog(
      context,
      title: "Rimuovi immagine",
      content: "Sei sicuro di voler eliminare la foto profilo?",
      confirmText: "Elimina",
      cancelText: "Annulla",
    );

    if (confirm != true) return;

    if (localImage != null && await localImage!.exists()) {
      await localImage!.delete();
      localImage = null;
      onUpdated();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Immagine profilo rimossa",
            style: TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.snackBar,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 💾 Carica immagine profilo salvata localmente (se presente)
  // ---------------------------------------------------------------------------
  Future<void> loadLocalProfileImage(VoidCallback onUpdated) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageFile = File('${appDir.path}/profile_picture.jpg');
    if (await imageFile.exists()) {
      localImage = imageFile;
      onUpdated();
    }
  }

  // ---------------------------------------------------------------------------
  // 📝 Modifica nome utente
  // ---------------------------------------------------------------------------
  Future<void> changeDisplayName(BuildContext context) async {
    final result = await DialogModel.showInputDialogAdaptive(
      context,
      title: "Modifica nome",
      fields: [
        {
          "hintText": "Nuovo nome",
          "initialValue": user?.displayName ?? "",
          "obscureText": false,
        },
      ],
      confirmText: "Salva",
      cancelText: "Annulla",
    );

    if (result != null && result.isNotEmpty && result.first.isNotEmpty) {
      await user?.updateDisplayName(result.first);
      await user?.reload();
      user = fb_auth.FirebaseAuth.instance.currentUser;

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Nome aggiornato con successo",
            style: TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.snackBar,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 📧 Modifica email utente con re-authentication e verifica via mail
  // ---------------------------------------------------------------------------
  Future<void> changeEmail(
    BuildContext context,
    Future<void> Function() refreshUser,
  ) async {
    final result = await DialogModel.showInputDialogAdaptive(
      context,
      title: "Modifica email",
      fields: [
        {
          "hintText": "Nuova email",
          "initialValue": user?.email ?? "",
          "keyboardType": TextInputType.emailAddress,
          "obscureText": false,
        },
        {"hintText": "Password attuale", "obscureText": true},
      ],
      confirmText: "Salva",
      cancelText: "Annulla",
    );

    if (result == null || result.length < 2) return;

    final newEmail = result[0].trim();
    final password = result[1];

    if (newEmail.isEmpty || password.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Inserisci email e password valide",
            style: TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.snackBar,
        ),
      );
      return;
    }

    try {
      final cred = fb_auth.EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );

      await user!.reauthenticateWithCredential(cred);
      await user!.verifyBeforeUpdateEmail(newEmail);
      await refreshUser();
      await fb_auth.FirebaseAuth.instance.signOut();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Abbiamo inviato una mail di conferma alla nuova email. Confermala e poi effettua il login.",
            style: TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.snackBar,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } on fb_auth.FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Errore: ${e.message}",
            style: TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.snackBar,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 🔒 Modifica password con re-authentication
  // ---------------------------------------------------------------------------
  Future<void> changePassword(BuildContext context) async {
    final result = await DialogModel.showInputDialogAdaptive(
      context,
      title: "Modifica password",
      fields: [
        {"hintText": "Password attuale", "obscureText": true},
        {"hintText": "Nuova password", "obscureText": true},
        {"hintText": "Conferma password", "obscureText": true},
      ],
      confirmText: "Salva",
      cancelText: "Annulla",
      onForgotPassword: () => showForgotPasswordAction(context),
    );

    if (result == null || result.length < 3) return;

    final currentPassword = result[0].trim();
    final newPassword = result[1].trim();
    final confirmPassword = result[2].trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Compila tutti i campi",
            style: TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.snackBar,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Le nuove password non coincidono",
            style: TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.snackBar,
        ),
      );
      return;
    }

    try {
      final cred = fb_auth.EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );

      await user!.reauthenticateWithCredential(cred);
      await user!.updatePassword(newPassword);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Password aggiornata con successo",
            style: TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.snackBar,
        ),
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Errore: ${e.message}",
            style: TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.snackBar,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 📩 Reset password via email
  // ---------------------------------------------------------------------------
  Future<void> showForgotPasswordAction(BuildContext context) async {
    try {
      await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(
        email: user!.email!,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Email di recupero inviata a ${user!.email!}",
              style: TextStyle(color: AppColors.textLight),
            ),
            backgroundColor: AppColors.snackBar,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Errore durante il reset: $e",
              style: TextStyle(color: AppColors.textLight),
            ),
            backgroundColor: AppColors.snackBar,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 🗑 Elimina account con conferma popup
  // ---------------------------------------------------------------------------
  Future<void> deleteAccount(BuildContext context) async {
    final confirm = await DialogModel.showConfirmDialog(
      context,
      title: "Elimina account",
      content: "Sei sicuro di voler eliminare definitivamente il tuo account?",
      confirmText: "Elimina",
      cancelText: "Annulla",
    );

    if (confirm == true) {
      try {
        await user?.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Account eliminato con successo",
                style: TextStyle(color: AppColors.textLight),
              ),
              backgroundColor: AppColors.snackBar,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Errore: $e",
                style: TextStyle(color: AppColors.textLight),
              ),
              backgroundColor: AppColors.snackBar,
            ),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📋 Copia testo negli appunti
  // ---------------------------------------------------------------------------
  void copyToClipboard(BuildContext context, String? text, {String? message}) {
    if (text == null) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? "Copiato negli appunti",
          style: TextStyle(color: AppColors.textLight),
        ),
        backgroundColor: AppColors.snackBar,
      ),
    );
  }
}
