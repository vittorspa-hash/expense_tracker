// profile_provider.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Per Clipboard
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Importa i tuoi file
import 'package:expense_tracker/services/profile_service.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/utils/dialog_utils.dart';
import 'package:expense_tracker/theme/app_colors.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;

  ProfileProvider({required ProfileService profileService})
    : _profileService = profileService;

  // Dependency Injection
  final ImagePicker _picker = ImagePicker();

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
  /// Carica l'immagine locale all'avvio
  Future<void> loadLocalData() async {
    _localImage = await _profileService.getLocalImage();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 🔄 REFRESH UTENTE
  // ---------------------------------------------------------------------------
  Future<void> refreshUser(BuildContext context) async {
    try {
      await _profileService.reloadUser();
      notifyListeners();

      if (context.mounted) _showSnack(context, "Dati profilo aggiornati");
    } catch (e) {
      if (context.mounted) _showSnack(context, "Errore refresh: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 📸 CAMBIA IMMAGINE (Galleria)
  // ---------------------------------------------------------------------------
  Future<void> changeProfilePicture(BuildContext context) async {
    // 1. Scelta immagine (UI Logic)
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    _setLoading(true);

    try {
      // 2. Salvataggio (Business Logic)
      final savedFile = await _profileService.saveLocalImage(
        File(pickedFile.path),
      );

      // Invalida la cache dell'immagine precedente per forzare il refresh UI
      await FileImage(savedFile).evict();

      _localImage = savedFile;
      _setLoading(false);

      if (context.mounted) _showSnack(context, "Immagine profilo aggiornata!");
    } catch (e) {
      _setLoading(false);
      if (context.mounted) _showSnack(context, e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // ❌ RIMUOVI IMMAGINE
  // ---------------------------------------------------------------------------
  Future<void> removeProfilePicture(BuildContext context) async {
    // 1. Dialogo conferma
    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: "Rimuovi immagine",
      content: "Sei sicuro di voler eliminare la foto profilo?",
      confirmText: "Elimina",
      cancelText: "Annulla",
    );

    if (confirm != true) return;

    try {
      // 2. Logica rimozione
      await _profileService.deleteLocalImage();
      _localImage = null;
      notifyListeners();

      if (context.mounted) _showSnack(context, "Immagine profilo rimossa");
    } catch (e) {
      if (context.mounted) _showSnack(context, e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // 📝 MODIFICA NOME
  // ---------------------------------------------------------------------------
  Future<void> changeDisplayName(BuildContext context) async {
    final result = await DialogUtils.showInputDialogAdaptive(
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
      _setLoading(true);
      try {
        await _profileService.updateDisplayName(result.first);
        _setLoading(false);
        if (context.mounted) {
          _showSnack(context, "Nome aggiornato con successo");
        }
      } catch (e) {
        _setLoading(false);
        if (context.mounted) _showSnack(context, e.toString());
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📧 MODIFICA EMAIL
  // ---------------------------------------------------------------------------
  Future<void> changeEmail(BuildContext context) async {
    final result = await DialogUtils.showInputDialogAdaptive(
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

    if (!context.mounted) return;

    if (result == null || result.length < 2) return;

    final newEmail = result[0].trim();
    final password = result[1];
    
    if (newEmail.isEmpty || password.isEmpty) {
      _showSnack(context, "Inserisci email e password valide");
      return;
    }

    _setLoading(true);
    try {
      await _profileService.updateEmail(newEmail: newEmail, password: password);
      _setLoading(false);

      if (!context.mounted) return;
      _showSnack(
        context,
        "Conferma la nuova email che ti abbiamo inviato, poi accedi.",
      );

      // Navigazione gestita qui perché è un cambio di stato dell'app (logout forzato)
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      _setLoading(false);
      if (context.mounted) _showSnack(context, e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // 🔒 MODIFICA PASSWORD
  // ---------------------------------------------------------------------------
  Future<void> changePassword(BuildContext context) async {
    final result = await DialogUtils.showInputDialogAdaptive(
      context,
      title: "Modifica password",
      fields: [
        {"hintText": "Password attuale", "obscureText": true},
        {"hintText": "Nuova password", "obscureText": true},
        {"hintText": "Conferma password", "obscureText": true},
      ],
      confirmText: "Salva",
      cancelText: "Annulla",
      // Qui deleghiamo al AuthProvider tramite context
      onForgotPassword: () => _showForgotPasswordAction(context),
    );

    if (!context.mounted) return;

    if (result == null || result.length < 3) return;

    final currentPassword = result[0].trim();
    final newPassword = result[1].trim();
    final confirmPassword = result[2].trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnack(context, "Compila tutti i campi");
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnack(context, "Le nuove password non coincidono");
      return;
    }

    _setLoading(true);
    try {
      await _profileService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _setLoading(false);
      if (context.mounted) {
        _showSnack(context, "Password aggiornata con successo");
      }
    } catch (e) {
      _setLoading(false);
      if (context.mounted) _showSnack(context, e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // 📩 RESET PASSWORD (Delega)
  // ---------------------------------------------------------------------------
  Future<void> _showForgotPasswordAction(BuildContext context) async {
    // Usiamo il context per trovare l'AuthProvider esistente
    await context.read<AuthProvider>().resetPassword(
      context,
      email: user?.email,
      customSuccessMessage: "Email di recupero inviata a ${user?.email}",
    );
  }

  // ---------------------------------------------------------------------------
  // 🗑 ELIMINA ACCOUNT
  // ---------------------------------------------------------------------------
  Future<void> deleteAccount(BuildContext context) async {
    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: "Elimina account",
      content: "Sei sicuro di voler eliminare definitivamente il tuo account?",
      confirmText: "Elimina",
      cancelText: "Annulla",
    );

    if (confirm == true) {
      _setLoading(true);
      try {
        await _profileService.deleteAccount();
        _setLoading(false);

        if (context.mounted) {
          _showSnack(context, "Account eliminato con successo");
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        _setLoading(false);
        if (context.mounted) _showSnack(context, e.toString());
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📋 UTILS
  // ---------------------------------------------------------------------------
  void copyToClipboard(BuildContext context, String? text, {String? message}) {
    if (text == null) return;
    Clipboard.setData(ClipboardData(text: text));
    _showSnack(context, message ?? "Copiato negli appunti");
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.snackBar,
        content: Text(msg, style: TextStyle(color: AppColors.textLight)),
      ),
    );
  }
}
