import 'package:expense_tracker/components/auth/auth_button.dart';
import 'package:expense_tracker/components/auth/auth_form_card.dart';
import 'package:expense_tracker/components/auth/auth_text_field.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// FILE: login_form.dart
/// DESCRIZIONE: Widget contenente il form di accesso. Gestisce l'input utente,
/// la validazione dei campi, l'interazione con authNotifierProvider di Riverpod
/// e la logica di verifica della mail o del recupero password.

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  // --- GESTIONE STATO E CONTROLLER ---
  // Definizioni per la validazione del form, focus dei campi e input testuale.
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure = true;

  // --- PULIZIA RISORSE ---
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // --- COSTRUZIONE INTERFACCIA ---
  @override
  Widget build(BuildContext context) {
    // Rilevamento del tema e dello stato di caricamento dal provider di autenticazione.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(authFlowBusyProvider);
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthFormCard(
              title: loc.welcomeBack,
              subtitle: loc.signInToContinue,
              children: [
                // CAMPO DI INPUT EMAIL
                AuthTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  nextFocus: _passwordFocus,
                  hint: loc.emailHint,
                  icon: FontAwesomeIcons.envelope,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.emailRequired;
                    }
                    if (!value.contains("@")) {
                      return loc.emailInvalid;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8.h),

                // CAMPO DI INPUT PASSWORD
                AuthTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  hint: loc.passwordHint,
                  icon: FontAwesomeIcons.lock,
                  obscure: _obscure,
                  isLast: true,
                  enabled: !isLoading,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.passwordRequired;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8.h),

                // PULSANTE RECUPERO PASSWORD
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : _handleResetPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                    ),
                    child: Text(
                      loc.forgotPassword,
                      style: TextStyle(
                        color: isLoading
                            ? (isDark
                                  ? AppColors.greyDark
                                  : AppColors.greyLight)
                            : (isDark
                                  ? AppColors.textLight
                                  : AppColors.textDark),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                        decoration: TextDecoration.underline,
                        decorationColor: isLoading
                            ? (isDark
                                  ? AppColors.greyDark
                                  : AppColors.greyLight)
                            : (isDark
                                  ? AppColors.textLight
                                  : AppColors.textDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // BOTTONE DI ACCESSO PRINCIPALE
            AuthButton(
              onPressed: isLoading ? null : _handleLogin,
              icon: isLoading ? null : FontAwesomeIcons.rightToBracket,
              text: isLoading ? "" : loc.loginButton,
              child: isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5.w,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textLight,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 18.h),
          ],
        ),
      ),
    );
  }

  // --- LOGICA DI AUTENTICAZIONE E ACCESSO ---

  /// Avvia l'autenticazione, verifica lo stato dell'email ed esegue l'eventuale re-invio.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authNotifierProvider.notifier);
    final loc = AppLocalizations.of(context)!;
    // Catturato SUBITO, prima di qualsiasi await: rimane valido anche se
    // il widget viene smontato da una navigazione innescata dal login riuscito.
    final busyNotifier = ref.read(authFlowBusyProvider.notifier);

    ref.invalidate(navigationNotifierProvider);
    busyNotifier.state = true;
    try {
      await auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final user = ref.read(authNotifierProvider).value?.user;

      if (user != null && !user.emailVerified) {
        final dialogFuture = DialogUtils.showConfirmDialog(
          context,
          title: loc.emailNotVerifiedTitle,
          content: loc.emailNotVerifiedMessage,
          confirmText: loc.resendEmail,
          cancelText: loc.close,
        );

        busyNotifier.state = false;

        final confirm = await dialogFuture;

        if (!mounted) return;

        if (confirm == true) {
          try {
            await auth.sendVerificationEmail(user);
            if (!mounted) return;
            SnackbarUtils.show(
              context: context,
              title: loc.successTitle,
              message: loc.verificationEmailSent,
              navBar: false,
            );
          } catch (e) {
            if (!mounted) return;
            SnackbarUtils.show(
              context: context,
              title: loc.errorTitle,
              message: e.toString(),
              navBar: false,
            );
          }
        }

        await auth.signOut();
        return;
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.show(
        context: context,
        title: loc.errorTitle,
        message: e.toString(),
        navBar: false,
      );
    } finally {
      busyNotifier.state = false;
    }
  }

  // --- RECUPERO PASSWORD ---

  /// Gestisce la richiesta di reset password inviando la mail all'indirizzo inserito.
  Future<void> _handleResetPassword() async {
    final loc = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      if (!mounted) return;
      SnackbarUtils.show(
        context: context,
        title: loc.errorTitle,
        message: loc.insertEmailForRecovery,
        navBar: false,
      );
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(email: email);
      if (!mounted) return;
      SnackbarUtils.show(
        context: context,
        title: loc.successTitle,
        message: loc.recoveryEmailSent(email),
        navBar: false,
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.show(
        context: context,
        title: loc.errorTitle,
        message: e.toString(),
        navBar: false,
      );
    }
  }
}
