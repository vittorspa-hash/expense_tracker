import 'dart:io';
import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/components/profile/delete_account_button.dart';
import 'package:expense_tracker/components/profile/profile_info_card.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/utils/clipboard_utils.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expense_tracker/components/profile/profile_avatar.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: profile_page.dart
/// DESCRIZIONE: Schermata di gestione del profilo utente.
/// Permette di visualizzare e modificare le informazioni personali (Avatar, Nome, Email, Password)
/// e gestire la sicurezza dell'account (Eliminazione).
/// Interagisce con ProfileProvider per la logica di business e AuthProvider per il reset password.
/// Utilizza `SnackbarUtils` per standardizzare il feedback visivo delle operazioni.

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  final ImagePicker _picker = ImagePicker();

  // --- INIZIALIZZAZIONE ---
  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();
    initFadeAnimation();
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  // --- BUILD UI ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(profileNotifierProvider).value;
    final user = profileState?.user;
    final isLoading = profileState?.isLoading ?? false;
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
            if (context.mounted) {
              SnackbarUtils.show(
                context: context,
                title: loc.successTitle,
                message: loc.dataUpdated,
                navBar: true,
              );
            }
          } catch (e) {
            if (context.mounted) {
              SnackbarUtils.show(
                context: context,
                title: loc.errorTitle,
                message: loc.refreshError(e.toString()),
                navBar: true,
              );
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
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: ProfileAvatar(
                    key: ObjectKey(profileState?.localImage),
                    image: profileState?.localImage,
                    isUploading: isLoading,
                    onChangePicture: _handleChangePicture,
                    onRemovePicture: _handleRemovePicture,
                  ),
                ),

                SizedBox(height: 32.h),

                // SEZIONE DATI PERSONALI
                ProfileInfoCard(
                  user: user,
                  isLoading: isLoading,
                  onEditName: _handleChangeDisplayName,
                  onEditEmail: _handleChangeEmail,
                  onEditPassword: _handleChangePassword,
                  onCopyId: () async {
                    await ClipboardUtils.copy(user?.uid);
                    if (context.mounted) {
                      SnackbarUtils.show(
                        context: context,
                        title: loc.successTitle,
                        message: loc.idCopied,
                        navBar: true,
                      );
                    }
                  },
                ),

                SizedBox(height: 24.h),

                // BOTTONE ELIMINAZIONE ACCOUNT
                DeleteAccountButton(
                  isLoading: isLoading,
                  onPressed: _handleDeleteAccount,
                ),

                SizedBox(height: 120.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- GESTIONE AVATAR ---
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
      if (mounted) {
        SnackbarUtils.show(
          context: context,
          title: loc.successTitle,
          message: loc.profilePictureUpdated,
          navBar: true,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.show(
          context: context,
          title: loc.errorTitle,
          message: e.toString(),
          navBar: true,
        );
      }
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
      if (mounted) {
        SnackbarUtils.show(
          context: context,
          title: loc.successTitle,
          message: loc.pictureRemoved,
          navBar: true,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.show(
          context: context,
          title: loc.errorTitle,
          message: e.toString(),
          navBar: true,
        );
      }
    }
  }

  // --- MODIFICA DATI UTENTE ---
  Future<void> _handleChangeDisplayName() async {
    final loc = AppLocalizations.of(context)!;

    final result = await DialogUtils.showInputDialogAdaptive(
      context,
      title: loc.editNameTooltip,
      fields: [
        {
          "hintText": loc.newNameHint,
          "initialValue":
              ref.read(profileNotifierProvider).value?.user?.displayName ?? "",
          "obscureText": false,
        },
      ],
      confirmText: loc.save,
      cancelText: loc.cancel,
    );

    if (result != null && result.isNotEmpty && result.first.isNotEmpty) {
      try {
        await ref
            .read(profileNotifierProvider.notifier)
            .updateDisplayName(result.first);
        if (mounted) {
          SnackbarUtils.show(
            context: context,
            title: loc.successTitle,
            message: loc.nameUpdated,
            navBar: true,
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.show(
            context: context,
            title: loc.errorTitle,
            message: e.toString(),
            navBar: true,
          );
        }
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
          "initialValue":
              ref.read(profileNotifierProvider).value?.user?.email ?? "",
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

    if ((newEmail.isEmpty || password.isEmpty) && mounted) {
      SnackbarUtils.show(
        context: context,
        title: loc.errorTitle,
        message: loc.invalidData,
        navBar: true,
      );
      return;
    }
    // 1. SALVIAMO I DATI PRIMA DELL'AWAIT (Mentre il context è valido)
    if (!mounted) return;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final successTitle = loc.successTitle;
    final successMessage = loc.emailUpdateSent;

    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .updateEmail(newEmail: newEmail, password: password);
      // 2. USIAMO LE VARIABILI SALVATE (Senza toccare il context)
      SnackbarUtils.showGlobal(
        messengerKey: rootScaffoldMessengerKey,
        isDark: isDarkTheme,
        title: successTitle,
        message: successMessage,
        navBar: false,
      );
    } catch (e) {
      if (mounted) {
        SnackbarUtils.show(
          context: context,
          title: loc.errorTitle,
          message: e.toString(),
          navBar: true,
        );
      }
    }
  }

  Future<void> _handleChangePassword() async {
    final userEmail = ref.read(profileNotifierProvider).value?.user?.email;
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
      onForgotPassword: () async {
        try {
          await ref
              .read(authNotifierProvider.notifier)
              .resetPassword(email: userEmail);
          if (mounted) {
            SnackbarUtils.show(
              context: context,
              title: loc.successTitle,
              message: loc.recoveryEmailSent(userEmail.toString()),
              navBar: true,
            );
          }
        } catch (e) {
          if (mounted) {
            SnackbarUtils.show(
              context: context,
              title: loc.errorTitle,
              message: e.toString(),
              navBar: true,
            );
          }
        }
      },
    );

    if (result == null || result.length < 3) return;

    final currentPass = result[0].trim();
    final newPass = result[1].trim();
    final confirmPass = result[2].trim();

    if (newPass != confirmPass && mounted) {
      SnackbarUtils.show(
        context: context,
        title: loc.errorTitle,
        message: loc.passwordsDoNotMatch,
        navBar: true,
      );
      return;
    }

    // 1. SALVIAMO I DATI PRIMA DELL'AWAIT
    if (!mounted) return;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final successTitle = loc.successTitle;
    final successMessage = loc.passwordUpdated;

    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .updatePassword(currentPassword: currentPass, newPassword: newPass);
      // 2. USIAMO LE VARIABILI SALVATE
      SnackbarUtils.showGlobal(
        messengerKey: rootScaffoldMessengerKey,
        isDark: isDarkTheme,
        title: successTitle,
        message: successMessage,
        navBar: true,
      );
    } catch (e) {
      if (mounted) {
        SnackbarUtils.show(
          context: context,
          title: loc.errorTitle,
          message: e.toString(),
          navBar: true,
        );
      }
    }
  }

  // --- CANCELLAZIONE ACCOUNT ---
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
        cancelText: loc.cancel,
      );

      if (confirm2 == true) {
        if (!mounted) return;

        // 1. SALVIAMO I DATI PRIMA DELL'AWAIT
        final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
        final successTitle = loc.successTitle;
        final successMessage = loc.accountDeleted;

        try {
          await ref.read(profileNotifierProvider.notifier).deleteAccount();
          SnackbarUtils.showGlobal(
            messengerKey: rootScaffoldMessengerKey,
            isDark: isDarkTheme,
            title: successTitle,
            message: successMessage,
            navBar: false,
          );
        } catch (e) {
          if (mounted) {
            SnackbarUtils.show(
              context: context,
              title: loc.errorTitle,
              message: e.toString(),
              navBar: true,
            );
          }
        }
      }
    }
  }
}
