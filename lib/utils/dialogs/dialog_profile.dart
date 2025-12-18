// dialog_profile.dart
// Contiene utility per la costruzione degli elementi UI (header, azioni, list tile)
// relativi al profilo utente all'interno dei bottom sheet o dialoghi adattivi.
// Gestisce anche la navigazione verso le pagine Profilo/Impostazioni e il processo di Logout.

import 'dart:io';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/utils/dialog_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/pages/profile_page.dart';
import 'package:expense_tracker/pages/settings_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'dialog_commons.dart';

class DialogProfile {
  // Costruisce l'header del profilo utente (avatar, nome, email).
  static Widget buildProfileHeader(
    BuildContext context,
    User? user, // L'oggetto utente di Firebase.
    File? localAvatar, // L'avatar scaricato localmente.
    bool isDark,
  ) {
    final txtColor = DialogCommons.textColor(context);

    return Column(
      children: [
        buildAvatar(user, localAvatar), // Widget per l'avatar.
        SizedBox(height: DialogCommons.isIOS ? 10.h : 12.h),

        // Nome utente
        Text(
          user?.displayName ?? "Account", // Mostra il nome o "Account".
          style: TextStyle(
            color: txtColor,
            fontWeight: FontWeight.bold,
            fontSize: DialogCommons.isIOS ? 15.sp : 17.sp,
          ),
        ),
        SizedBox(height: 4.h),

        // Email utente
        Text(
          user?.email ?? "", // Mostra l'email.
          style: TextStyle(
            color: txtColor,
            fontSize: DialogCommons.isIOS ? 13.sp : 15.sp,
          ),
        ),
      ],
    );
  }

  // Costruisce il widget CircleAvatar, gestendo l'immagine locale, di rete o l'icona di default.
  static Widget buildAvatar(User? user, File? localAvatar) => CircleAvatar(
    radius: 34.r,
    backgroundColor: AppColors.backgroundAvatar,
    // Imposta l'immagine: prima locale, poi di rete, altrimenti null.
    backgroundImage: localAvatar != null
        ? FileImage(localAvatar)
        : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
    // Se non ci sono foto, mostra l'icona di default.
    child: localAvatar == null && user?.photoURL == null
        ? Icon(Icons.person, size: 50.sp, color: AppColors.avatar)
        : null,
  );

  // Costruisce l'azione "Profilo" per il CupertinoActionSheet.
  static Widget buildProfileAction(
    BuildContext context,
    User? user,
    File? localAvatar,
    Future<void> Function()
    reloadAvatar, // Callback per aggiornare l'avatar dopo la modifica.
    bool isDark,
  ) => CupertinoActionSheetAction(
    // Gestisce la navigazione verso la pagina ProfilePage.
    onPressed: () => _handleProfileNavigation(context, reloadAvatar),
    child: Text(
      "Profilo",
      style: TextStyle(
        color: isDark ? AppColors.textLight : AppColors.textDark,
        fontSize: 17.sp,
      ),
    ),
  );

  // Costruisce l'azione "Impostazioni" per il CupertinoActionSheet.
  static Widget buildSettingsAction(BuildContext context, bool isDark) =>
      CupertinoActionSheetAction(
        // Gestisce la navigazione verso la pagina SettingsPage.
        onPressed: () => _handleSettingsNavigation(context),
        child: Text(
          "Impostazioni",
          style: TextStyle(
            color: isDark ? AppColors.textLight : AppColors.textDark,
            fontSize: 17.sp,
          ),
        ),
      );

  // Costruisce l'azione "Logout" per il CupertinoActionSheet.
  static Widget buildLogoutAction(BuildContext context, bool isDark) {
    // Questo pulsante è rilevante solo per iOS, in Material si usa ListTile.
    if (!DialogCommons.isIOS) return const SizedBox.shrink();

    return CupertinoActionSheetAction(
      isDestructiveAction:
          true, // Rende il testo rosso per segnalare un'azione pericolosa.
      onPressed: () =>
          handleLogout(context, GetIt.instance<AuthService>()), // Avvia la procedura di logout con conferma.
      child: Text(
        "Logout",
        style: TextStyle(color: AppColors.delete, fontSize: 17.sp),
      ),
    );
  }

  // Costruisce la ListTile "Profilo" per il ModalBottomSheet (Material style).
  static Widget buildProfileListTile(
    BuildContext context,
    User? user,
    File? localAvatar,
    Future<void> Function() reloadAvatar,
    bool isDark,
  ) => ListTile(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
    leading: Icon(Icons.person, color: AppColors.primary, size: 24.sp),
    title: Text("Profilo", style: TextStyle(fontSize: 16.sp)),
    onTap: () => _handleProfileNavigation(context, reloadAvatar),
  );

  // Costruisce la ListTile "Impostazioni" per il ModalBottomSheet (Material style).
  static Widget buildSettingsListTile(BuildContext context, bool isDark) =>
      ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        leading: Icon(Icons.settings, color: AppColors.primary, size: 24.sp),
        title: Text("Impostazioni", style: TextStyle(fontSize: 16.sp)),
        onTap: () => _handleSettingsNavigation(context),
      );

  // Costruisce la ListTile "Logout" per il ModalBottomSheet (Material style).
  static Widget buildLogoutListTile(BuildContext context, bool isDark) =>
      ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        leading: Icon(Icons.logout, color: AppColors.delete, size: 24.sp),
        title: Text(
          "Logout",
          style: TextStyle(color: AppColors.delete, fontSize: 16.sp),
        ),
        onTap: () =>
            handleLogout(context, GetIt.instance<AuthService>()), // Avvia la procedura di logout con conferma.
      );

  // Gestisce la navigazione verso la pagina del profilo e il ricaricamento dell'avatar al ritorno.
  static Future<void> _handleProfileNavigation(
    BuildContext context,
    Future<void> Function() reloadAvatar,
  ) async {
    // Chiudi il dialog/sheet corrente.
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Aspetta un ciclo per permettere la chiusura del sheet.
    await Future.delayed(Duration.zero);

    // Naviga alla ProfilePage.
    if (context.mounted) {
      await Navigator.pushNamed(context, ProfilePage.route);
    }

    // Al ritorno, prova a ricaricare l'avatar.
    if (context.mounted) {
      try {
        await reloadAvatar();
      } catch (e) {
        debugPrint('⚠️ Errore durante il reload dell\'avatar: $e');
        // Opzionale: mostra una SnackBar in caso di errore.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Impossibile aggiornare l\'avatar'),
              duration: const Duration(seconds: 3),
              backgroundColor: AppColors.snackBar,
            ),
          );
        }
      }
    }
  }

  // Gestisce la navigazione verso la pagina delle impostazioni.
  static void _handleSettingsNavigation(BuildContext context) {
    // Chiudi il dialog/sheet corrente.
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Aspetta un ciclo per permettere la chiusura del sheet prima di navigare.
    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        Navigator.pushNamed(context, SettingsPage.route);
      }
    });
  }

  // Gestisce la procedura di logout, inclusa la richiesta di conferma.
  static Future<void> handleLogout(
    BuildContext context,
    AuthService authService,
  ) async {
    if (!context.mounted) return;
    Navigator.pop(context);
    await Future.delayed(Duration.zero);

    if (!context.mounted) return;

    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: "Conferma logout",
      content: "Sei sicuro di voler uscire dall'account?",
      confirmText: "Logout",
      cancelText: "Annulla",
    );

    if (confirmed == true && context.mounted) {
      await authService.signOut(
        context: context,
        onSuccess: () {}, // Gestito automaticamente da FirebaseAuth stream
      );
    }
  }
}
