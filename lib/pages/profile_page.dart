// profile_page.dart
import 'dart:io';

import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart'; // Necessario ora qui
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Necessario ora qui
import 'package:provider/provider.dart';

import 'package:expense_tracker/providers/profile_provider.dart';
import 'package:expense_tracker/providers/auth_provider.dart'; // Per il reset password
import 'package:expense_tracker/components/profile/profile_avatar.dart';
import 'package:expense_tracker/components/profile/profile_tile.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfilePage extends StatefulWidget {
  static const route = "/profile/page";
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  // UI Controller Resources
  final ImagePicker _picker = ImagePicker();

  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();
    initFadeAnimation();

    // Caricamento iniziale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileProvider>().loadLocalData();
      }
    });
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 🎨 BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ascoltiamo le modifiche del provider
    final provider = context.watch<ProfileProvider>();
    final user = provider.user;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Profilo",
        icon: Icons.person_rounded,
        isDark: isDark,
      ),

      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          try {
            await provider.refreshUser();
            if (mounted) _showSnack("Dati aggiornati");
          } catch (e) {
            if (mounted) _showSnack("Errore refresh: $e", isError: true);
          }
        },

        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
          ),
          child: buildWithFadeAnimation(
            ListView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              children: [
                // 🖼️ AVATAR
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark.withValues(alpha: 0.3)
                        : AppColors.cardLight.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ProfileAvatar(
                    // Key per forzare il refresh se cambia il file
                    key: ObjectKey(provider.localImage),
                    image: provider.localImage,
                    isUploading: provider.isLoading,
                    onChangePicture: _handleChangePicture,
                    onRemovePicture: _handleRemovePicture,
                  ),
                ),

                SizedBox(height: 32.h),

                // 📑 DATI PERSONALI
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark.withValues(alpha: 0.5)
                        : AppColors.cardLight.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(
                          alpha: isDark ? 0.3 : 0.08,
                        ),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Nome
                      ProfileTile(
                        icon: Icons.person_outline_rounded,
                        title: "Nome",
                        value: user?.displayName,
                        tooltip: "Modifica nome",
                        onPressed: _handleChangeDisplayName,
                        isLoading: provider.isLoading,
                      ),

                      _buildDivider(isDark),

                      // Email
                      ProfileTile(
                        icon: Icons.email_outlined,
                        title: "Email",
                        value: user?.email,
                        tooltip: "Modifica email",
                        onPressed: _handleChangeEmail,
                        isLoading: provider.isLoading,
                      ),

                      _buildDivider(isDark),

                      // Password
                      ProfileTile(
                        icon: Icons.lock_outline_rounded,
                        title: "Password",
                        value: "••••••••••",
                        tooltip: "Modifica password",
                        onPressed: _handleChangePassword,
                        isLoading: provider.isLoading,
                      ),

                      _buildDivider(isDark),

                      // ID
                      ProfileTile(
                        icon: Icons.badge_outlined,
                        title: "ID utente",
                        value: user?.uid,
                        trailingIcon: Icons.content_copy_rounded,
                        tooltip: "Copia ID",
                        onPressed: () async {
                          await provider.copyToClipboard(user?.uid);
                          _showSnack("ID copiato negli appunti");
                        },
                        isLoading: provider.isLoading,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // 🗑️ ELIMINA
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _handleDeleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: isDark
                        ? AppColors.textDark
                        : AppColors.textLight,
                    elevation: 6,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (provider.isLoading)
                        Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textLight,
                            ),
                          ),
                        )
                      else ...[
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 22.r,
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textLight,
                        ),
                        SizedBox(width: 12.w),
                      ],
                      Text(
                        "Elimina account",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? AppColors.dividerDark.withValues(alpha: 0.3)
            : AppColors.dividerLight.withValues(alpha: 0.5),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🕹️ LOGICA UI (Gestione Dialoghi e Chiamate al Provider)
  // ---------------------------------------------------------------------------

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.snackBar,
        content: Text(msg, style: TextStyle(color: AppColors.textLight)),
      ),
    );
  }

  /// 📸 CAMBIO IMMAGINE
  Future<void> _handleChangePicture() async {
    final provider = context.read<ProfileProvider>();

    // 1. Scelta Immagine (UI)
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      // 2. Logica Provider
      await provider.setProfileImage(File(pickedFile.path));
      _showSnack("Immagine profilo aggiornata!");
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  /// ❌ RIMOZIONE IMMAGINE
  Future<void> _handleRemovePicture() async {
    final provider = context.read<ProfileProvider>();

    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: "Rimuovi immagine",
      content: "Sei sicuro di voler eliminare la foto profilo?",
      confirmText: "Elimina",
      cancelText: "Annulla",
    );

    if (confirm != true) return;

    try {
      await provider.deleteProfileImage();
      _showSnack("Immagine profilo rimossa");
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  /// 📝 MODIFICA NOME
  Future<void> _handleChangeDisplayName() async {
    final provider = context.read<ProfileProvider>();

    final result = await DialogUtils.showInputDialogAdaptive(
      context,
      title: "Modifica nome",
      fields: [
        {
          "hintText": "Nuovo nome",
          "initialValue": provider.user?.displayName ?? "",
          "obscureText": false,
        },
      ],
      confirmText: "Salva",
      cancelText: "Annulla",
    );

    if (result != null && result.isNotEmpty && result.first.isNotEmpty) {
      try {
        await provider.updateDisplayName(result.first);
        _showSnack("Nome aggiornato con successo");
      } catch (e) {
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  /// 📧 MODIFICA EMAIL
  Future<void> _handleChangeEmail() async {
    final provider = context.read<ProfileProvider>();

    final result = await DialogUtils.showInputDialogAdaptive(
      context,
      title: "Modifica email",
      fields: [
        {
          "hintText": "Nuova email",
          "initialValue": provider.user?.email ?? "",
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
      _showSnack("Inserisci dati validi", isError: true);
      return;
    }

    try {
      await provider.updateEmail(newEmail: newEmail, password: password);
      if (!mounted) return;

      _showSnack("Conferma la nuova email inviata. Effettua l'accesso.");
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  /// 🔒 MODIFICA PASSWORD
  Future<void> _handleChangePassword() async {
    final provider = context.read<ProfileProvider>();
    // Otteniamo l'email in anticipo per usarla nella callback
    final userEmail = provider.user?.email;

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
      // Callback aggiornata per il nuovo AuthProvider
      onForgotPassword: () async {
        try {
          await context.read<AuthProvider>().resetPassword(email: userEmail);
          // Messaggio gestito qui nella UI
          if (mounted) {
            _showSnack("Email di recupero inviata a $userEmail");
          }
        } catch (e) {
          // Errore gestito qui nella UI
          if (mounted) {
            _showSnack(e.toString(), isError: true);
          }
        }
      },
    );

    if (result == null || result.length < 3) return;

    final currentPass = result[0].trim();
    final newPass = result[1].trim();
    final confirmPass = result[2].trim();

    if (newPass != confirmPass) {
      _showSnack("Le nuove password non coincidono", isError: true);
      return;
    }

    try {
      await provider.updatePassword(
        currentPassword: currentPass,
        newPassword: newPass,
      );
      _showSnack("Password aggiornata con successo");
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  /// 🗑 ELIMINA ACCOUNT
  Future<void> _handleDeleteAccount() async {
    final provider = context.read<ProfileProvider>();

    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: "Elimina account",
      content: "Sei sicuro di voler eliminare definitivamente il tuo account?",
      confirmText: "Elimina",
      cancelText: "Annulla",
    );

    if (confirm == true) {
      try {
        await provider.deleteAccount();
        if (!mounted) return;
        _showSnack("Account eliminato con successo");
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        _showSnack(e.toString(), isError: true);
      }
    }
  }
}
