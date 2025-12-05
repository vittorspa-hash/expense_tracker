// dialog_profile.dart
// Questo file contiene una serie di metodi statici per la costruzione di:
// - Header del profilo (avatar, nome, email)
// - Azioni relative al profilo (Profilo, Impostazioni, Logout)
// - Versioni sia per Cupertino (iOS) che per Material (Android)
// - Funzioni di supporto per logout con dialog di conferma

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/pages/profile_page.dart';
import 'package:expense_tracker/pages/settings_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dialog_commons.dart';

class DialogProfile {
  // ---------------------------------------------------------------------------
  // 🔹 HEADER PROFILO (Avatar + Nome + Email)
  // ---------------------------------------------------------------------------
  // Mostra le informazioni base dell'utente all'interno di un dialog o sheet.
  // Include avatar locale, foto o icona di fallback.
  static Widget buildProfileHeader(
    BuildContext context,
    User? user,
    File? localAvatar,
    bool isDark,
  ) {
    final txtColor = DialogCommons.textColor(context);

    return Column(
      children: [
        buildAvatar(user, localAvatar),
        SizedBox(height: DialogCommons.isIOS ? 10.h : 12.h),

        // Nome utente
        Text(
          user?.displayName ?? "Account",
          style: TextStyle(
            color: txtColor,
            fontWeight: FontWeight.bold,
            fontSize: DialogCommons.isIOS ? 15.sp : 17.sp,
          ),
        ),
        SizedBox(height: 4.h),

        // Email utente
        Text(
          user?.email ?? "",
          style: TextStyle(
            color: txtColor,
            fontSize: DialogCommons.isIOS ? 13.sp : 15.sp,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 AVATAR UTENTE
  // ---------------------------------------------------------------------------
  static Widget buildAvatar(User? user, File? localAvatar) => CircleAvatar(
    radius: 34.r,
    backgroundColor: AppColors.backgroundAvatar,
    backgroundImage: localAvatar != null
        ? FileImage(localAvatar)
        : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
    child: localAvatar == null && user?.photoURL == null
        ? Icon(Icons.person, size: 50.sp, color: AppColors.avatar)
        : null,
  );

  // ---------------------------------------------------------------------------
  // 🔹 PULSANTE "Profilo" (Cupertino / iOS)
  // ---------------------------------------------------------------------------
  // Apre la pagina del profilo e aggiorna l'avatar al ritorno.
  // ---------------------------------------------------------------------------
  static Widget buildProfileAction(
    BuildContext context,
    User? user,
    File? localAvatar,
    Future<void> Function() reloadAvatar,
    bool isDark,
  ) => CupertinoActionSheetAction(
    onPressed: () => _handleProfileNavigation(context, reloadAvatar),
    child: Text(
      "Profilo",
      style: TextStyle(
        color: isDark ? AppColors.textLight : AppColors.textDark,
        fontSize: 17.sp,
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // 🔹 PULSANTE "Impostazioni" (Cupertino / iOS)
  // ---------------------------------------------------------------------------
  static Widget buildSettingsAction(BuildContext context, bool isDark) =>
      CupertinoActionSheetAction(
        onPressed: () => _handleSettingsNavigation(context),  
        child: Text(
          "Impostazioni",
          style: TextStyle(
            color: isDark ? AppColors.textLight : AppColors.textDark,
            fontSize: 17.sp,
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // 🔹 PULSANTE "Logout" (Cupertino / iOS)
  // ---------------------------------------------------------------------------
  // Mostra l’azione distruttiva solo per iOS.
  // ---------------------------------------------------------------------------
  static Widget buildLogoutAction(
    BuildContext context,
    bool isDark,
    
  ) {
    if (!DialogCommons.isIOS) return const SizedBox.shrink();

    return CupertinoActionSheetAction(
      isDestructiveAction: true,
      onPressed: () => handleLogout(context),
      child: Text(
        "Logout",
        style: TextStyle(color: AppColors.delete, fontSize: 17.sp),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 LIST TILE "Profilo" (Android)
  // ---------------------------------------------------------------------------
  // Alternativa al CupertinoActionSheet per dispositivi Material.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // 🔹 LIST TILE "Impostazioni" (Android)
  // ---------------------------------------------------------------------------
  static Widget buildSettingsListTile(BuildContext context, bool isDark) =>
      ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        leading: Icon(Icons.settings, color: AppColors.primary, size: 24.sp),
        title: Text("Impostazioni", style: TextStyle(fontSize: 16.sp)),
        onTap: () => _handleSettingsNavigation(context),
      );

  // ---------------------------------------------------------------------------
  // 🔹 LIST TILE "Logout" (Android)
  // ---------------------------------------------------------------------------
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
        onTap: () => handleLogout(context),
      );

  // ========== NAVIGATION HANDLERS (Private) ==========

  /// Gestisce la navigazione al profilo con context safety
  /// ✅ Error handling per reloadAvatar
  static Future<void> _handleProfileNavigation(
    BuildContext context,
    Future<void> Function() reloadAvatar,
  ) async {
    // Chiudi il dialog/sheet corrente
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Aspetta un frame per assicurarsi che il pop sia completato
    await Future.delayed(Duration.zero);

    // Naviga alla pagina profilo
    if (context.mounted) {
      await Navigator.pushNamed(context, ProfilePage.route);
    }

    // Ricarica l'avatar con error handling
    if (context.mounted) {
      try {
        await reloadAvatar();
      } catch (e) {
        debugPrint('⚠️ Errore durante il reload dell\'avatar: $e');
        // Opzionale: mostra snackbar all'utente
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossibile aggiornare l\'avatar'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// Gestisce la navigazione alle impostazioni con context safety
  static void _handleSettingsNavigation(BuildContext context) {
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Aspetta che il pop sia completato
    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        Navigator.pushNamed(context, SettingsPage.route);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 🔻 LOGOUT (Dialog di conferma)
  // ---------------------------------------------------------------------------
  // Gestisce:
  // - Chiusura sheet/list
  // - Dialog Cupertino o Material
  // - Conferma utente
  // - Logout Firebase
  // ---------------------------------------------------------------------------
  static Future<void> handleLogout(BuildContext context) async {
    if (!context.mounted) return;

    Navigator.pop(context);

    await Future.delayed(Duration.zero);

    if (!context.mounted) return;

    final textColor = DialogCommons.textColor(context);
    const title = "Conferma logout";
    const content = "Sei sicuro di voler uscire dall'account?";
    const cancelText = "Annulla";
    const confirmText = "Logout";

    bool? confirm;

    // ----------------------------- iOS ---------------------------------------
    if (DialogCommons.isIOS) {
      if (!context.mounted) return;
      confirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title, style: TextStyle(fontSize: 15.sp)),
          content: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(content, style: TextStyle(fontSize: 14.sp)),
          ),
          actions: [
            DialogCommons.buildActionButton(
              context,
              cancelText,
              textColor,
              false,
            ),
            DialogCommons.buildActionButton(
              context,
              confirmText,
              AppColors.delete,
              true,
            ),
          ],
        ),
      );
    }
    // ----------------------------- ANDROID -----------------------------------
    else {
      if (!context.mounted) return;
      confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: DialogCommons.roundedRectangleBorder(),
          title: Text(
            title,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          content: Text(content, style: TextStyle(fontSize: 14.sp)),
          actions: [
            DialogCommons.buildActionButton(
              context,
              cancelText,
              textColor,
              false,
            ),
            DialogCommons.buildActionButton(
              context,
              confirmText,
              AppColors.delete,
              true,
            ),
          ],
        ),
      );
    }

    // Se l’utente conferma → logout da Firebase
    if (confirm == true && context.mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        debugPrint('✅ Logout completato con successo');
      } catch (e) {
        debugPrint('❌ Errore durante il logout: $e');

        // ✅ Mostra errore all'utente
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore durante il logout: ${e.toString()}'),
              backgroundColor: AppColors.delete,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
