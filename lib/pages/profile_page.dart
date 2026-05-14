import 'dart:io';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/utils/clipboard_utils.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expense_tracker/components/profile/profile_avatar.dart';
import 'package:expense_tracker/components/profile/profile_tile.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: profile_page.dart
/// DESCRIZIONE: Schermata di gestione del profilo utente.
/// Permette di visualizzare e modificare le informazioni personali (Avatar, Nome, Email, Password)
/// e gestire la sicurezza dell'account (Eliminazione).
/// Interagisce con ProfileProvider per la logica di business e AuthProvider per il reset password.

class ProfilePage extends ConsumerStatefulWidget {
  static const route = "/profile/page";
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  // --- INIZIALIZZAZIONE ---
  // Configura il picker immagini, le animazioni e richiede il caricamento
  // dei dati locali del profilo all'avvio del widget.
  final ImagePicker _picker = ImagePicker();

  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();
    initFadeAnimation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(profileNotifierProvider.notifier).loadLocalData();
      }
    });
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  // --- BUILD UI ---
  // Costruisce la lista scrollabile delle impostazioni.
  // Include un RefreshIndicator per sincronizzare i dati con il server
  // e sezioni distinte per Avatar, Dati Anagrafici e Azioni Critiche.
  //
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(profileNotifierProvider);
    final user = profileState.user;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBar(
        title: loc.profileTitle,
        icon: Icons.person_rounded,
        isDark: isDark,
      ),

      body: RefreshIndicator(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        color: AppColors.primary,
        onRefresh: () async {
          try {
            await ref.read(profileNotifierProvider.notifier).refreshUser();
            if (mounted) _showSnack(loc.dataUpdated);
          } catch (e) {
            if (mounted) {
              _showSnack(loc.refreshError(e.toString()), isError: true);
            }
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
                // SEZIONE AVATAR
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark.withValues(alpha: 0.3)
                        : AppColors.cardLight.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: ProfileAvatar(
                    key: ObjectKey(profileState.localImage),
                    image: profileState.localImage,
                    isUploading: profileState.isLoading,
                    onChangePicture: _handleChangePicture,
                    onRemovePicture: _handleRemovePicture,
                  ),
                ),

                SizedBox(height: 32.h),

                // SEZIONE DATI PERSONALI
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
                        title: loc.nameLabel,
                        value: user?.displayName,
                        tooltip: loc.editNameTooltip,
                        onPressed: _handleChangeDisplayName,
                        isLoading: profileState.isLoading,
                      ),

                      _buildDivider(isDark),

                      // Email
                      ProfileTile(
                        icon: Icons.email_outlined,
                        title: loc.emailLabel,
                        value: user?.email,
                        tooltip: loc.editEmailTooltip,
                        onPressed: _handleChangeEmail,
                        isLoading: profileState.isLoading,
                      ),

                      _buildDivider(isDark),

                      // Password
                      ProfileTile(
                        icon: Icons.lock_outline_rounded,
                        title: loc.passwordLabel,
                        value: "••••••••••",
                        tooltip: loc.editPasswordTooltip,
                        onPressed: _handleChangePassword,
                        isLoading: profileState.isLoading,
                      ),

                      _buildDivider(isDark),

                      // ID Utente (Copiabile)
                      ProfileTile(
                        icon: Icons.badge_outlined,
                        title: loc.userIdLabel,
                        value: user?.uid,
                        trailingIcon: Icons.content_copy_rounded,
                        tooltip: loc.copyIdTooltip,
                        onPressed: () async {
                          final loc = AppLocalizations.of(context)!;
                          await ClipboardUtils.copy(user?.uid);
                          _showSnack(loc.idCopied);
                        },
                        isLoading: profileState.isLoading,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // BOTTONE ELIMINAZIONE ACCOUNT
                ElevatedButton(
                  onPressed: profileState.isLoading ? null : _handleDeleteAccount,
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
                      if (profileState.isLoading)
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
                        loc.deleteAccountButton,
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

  // Helper per divisori grafici
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

  // --- HELPER LOGICA UI ---
  // Funzioni di utilità per mostrare feedback all'utente (SnackBar).
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.snackBar,
        content: Text(msg, style: TextStyle(color: AppColors.textLight)),
      ),
    );
  }

  // --- GESTIONE AVATAR ---
  // Logica per selezionare una nuova immagine dalla galleria o rimuovere quella esistente.
  //
  Future<void> _handleChangePicture() async {
    final loc = AppLocalizations.of(context)!;
    final notifier = ref.read(profileNotifierProvider.notifier);

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );

      if (pickedFile == null) return;
      if (!mounted) return;

      await notifier.setProfileImage(File(pickedFile.path));
      _showSnack(loc.profilePictureUpdated);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _handleRemovePicture() async {
    final loc = AppLocalizations.of(context)!;
    final notifier = ref.read(profileNotifierProvider.notifier);

    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: loc.removePictureTitle,
      content: loc.removePictureMessage,
      confirmText: loc.delete,
      cancelText: loc.cancel,
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      await notifier.deleteProfileImage();
      _showSnack(loc.pictureRemoved);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  // --- MODIFICA DATI UTENTE ---
  // Serie di metodi che aprono dialoghi di input specifici (Nome, Email, Password),
  // validano i dati inseriti e invocano i metodi di aggiornamento del Provider.
  //
  Future<void> _handleChangeDisplayName() async {
    final loc = AppLocalizations.of(context)!;

    final result = await DialogUtils.showInputDialogAdaptive(
      context,
      title: loc.editNameTooltip,
      fields: [
        {
          "hintText": loc.newNameHint,
          "initialValue": ref.read(profileNotifierProvider).user?.displayName ?? "",
          "obscureText": false,
        },
      ],
      confirmText: loc.save,
      cancelText: loc.cancel,
    );

    if (result != null && result.isNotEmpty && result.first.isNotEmpty) {
      try {
        await ref.read(profileNotifierProvider.notifier).updateDisplayName(result.first);
        _showSnack(loc.nameUpdated);
      } catch (e) {
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  Future<void> _handleChangeEmail() async {
    final loc = AppLocalizations.of(context)!;

    final result = await DialogUtils.showInputDialogAdaptive(
      context,
      title: loc.editEmailTooltip,
      fields: [
        {
          "hintText": loc.newEmailHint,
          "initialValue": ref.read(profileNotifierProvider).user?.email ?? "",
          "keyboardType": TextInputType.emailAddress,
          "obscureText": false,
        },
        {"hintText": loc.currentPasswordHint, "obscureText": true},
      ],
      confirmText: loc.save,
      cancelText: loc.cancel,
    );

    if (result == null || result.length < 2) return;

    final newEmail = result[0].trim();
    final password = result[1];

    if (newEmail.isEmpty || password.isEmpty) {
      _showSnack(loc.invalidData, isError: true);
      return;
    }

    try {
      await ref.read(profileNotifierProvider.notifier).updateEmail(newEmail: newEmail, password: password);
      if (!mounted) return;

      _showSnack(loc.emailUpdateSent);
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _handleChangePassword() async {
    final userEmail = ref.read(profileNotifierProvider).user?.email;
    final loc = AppLocalizations.of(context)!;

    final result = await DialogUtils.showInputDialogAdaptive(
      context,
      title: loc.editPasswordTooltip,
      fields: [
        {"hintText": loc.currentPasswordHint, "obscureText": true},
        {"hintText": loc.newPasswordHint, "obscureText": true},
        {"hintText": loc.confirmPasswordHint, "obscureText": true},
      ],
      confirmText: loc.save,
      cancelText: loc.cancel,
      // Callback per AuthProvider
      onForgotPassword: () async {
        try {
          await ref.read(authNotifierProvider.notifier).resetPassword(email: userEmail);
          if (mounted) {
            _showSnack(loc.recoveryEmailSent(userEmail.toString()));
          }
        } catch (e) {
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
      _showSnack(loc.passwordsDoNotMatch, isError: true);
      return;
    }

    try {
      await ref.read(profileNotifierProvider.notifier).updatePassword(
        currentPassword: currentPass,
        newPassword: newPass,
      );
      _showSnack(loc.passwordUpdated);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  // --- CANCELLAZIONE ACCOUNT ---
  // Flusso critico per l'eliminazione definitiva dell'utente.
  Future<void> _handleDeleteAccount() async {
    final loc = AppLocalizations.of(context)!;

    final confirm = await DialogUtils.showConfirmDialog(
      context,
      title: loc.deleteAccountTitle,
      content: loc.deleteAccountMessage,
      confirmText: loc.delete,
      cancelText: loc.cancel,
    );

   
    if (confirm == true) {
      if (!mounted) return;
      final confirm2 = await DialogUtils.showConfirmDialog(
        context,
        title: loc.warningTitle,
        content: loc.deleteAccountMessageConfirm,
        confirmText: loc.delete,
        cancelText: loc.cancel
      );

      if (confirm2 == true) {
        if (!mounted) return;
        try {
          await ref.read(profileNotifierProvider.notifier).deleteAccount();
          if (!mounted) return;
          _showSnack(loc.accountDeleted);
          Navigator.of(context).popUntil((route) => route.isFirst);
        } catch (e) {
          _showSnack(e.toString(), isError: true);
        }
      }
    }
  }
}
