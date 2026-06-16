import 'package:expense_tracker/components/auth/auth_button.dart';
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

/// FILE: register_form.dart
/// DESCRIZIONE: Widget contenente il form di registrazione. Raccoglie i dati dell'utente
/// (Nome, Email, Password), gestisce la validazione dei campi e comunica con il
/// provider authNotifierProvider di Riverpod per la creazione di un nuovo account Firebase.

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  // --- GESTIONE STATO E CONTROLLER ---
  // Definizioni per la validazione del form, focus dei campi, input testuale
  // e parametri di visibilità del testo della password.
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscure1 = true;
  bool _obscure2 = true;

  // --- PULIZIA RISORSE ---
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // --- COSTRUZIONE INTERFACCIA ---
  @override
  Widget build(BuildContext context) {
    // Rilevamento del tema corrente e ascolto dello stato di caricamento dal provider.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(authNotifierProvider).value?.isLoading ?? false;
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // SCHEDA DEL FORM DI REGISTRAZIONE
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.createAccount,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textLight : AppColors.textDark2,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    loc.registerToStart,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark ? AppColors.greyDark : AppColors.greyLight,
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // CAMPO DI INPUT NOME
                  AuthTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocus: _emailFocus,
                    hint: loc.fullNameHint,
                    icon: FontAwesomeIcons.user,
                    capitalization: TextCapitalization.words,
                    enabled: !isLoading,
                    validator: (v) =>
                        v!.trim().isEmpty ? loc.nameRequired : null,
                  ),
                  SizedBox(height: 8.h),

                  // CAMPO DI INPUT EMAIL
                  AuthTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocus: _passwordFocus,
                    hint: loc.emailHint,
                    icon: FontAwesomeIcons.envelope,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return loc.emailRequired;
                      }
                      if (!v.contains("@")) return loc.emailInvalid;
                      return null;
                    },
                  ),
                  SizedBox(height: 8.h),

                  // CAMPO DI INPUT PASSWORD
                  AuthTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    nextFocus: _confirmFocus,
                    hint: loc.passwordHint,
                    icon: FontAwesomeIcons.lock,
                    obscure: _obscure1,
                    enabled: !isLoading,
                    onToggleObscure: () =>
                        setState(() => _obscure1 = !_obscure1),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return loc.passwordRequired;
                      }
                      if (v.length < 6) {
                        return loc.passwordMinLength;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8.h),

                  // CAMPO DI INPUT CONFERMA PASSWORD
                  AuthTextField(
                    controller: _confirmController,
                    focusNode: _confirmFocus,
                    hint: loc.confirmPasswordHint,
                    icon: FontAwesomeIcons.lock,
                    obscure: _obscure2,
                    isLast: true,
                    enabled: !isLoading,
                    onToggleObscure: () =>
                        setState(() => _obscure2 = !_obscure2),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return loc.confirmPasswordRequired;
                      }
                      if (v != _passwordController.text) {
                        return loc.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),

            // BOTTONE DI REGISTRAZIONE
            AuthButton(
              onPressed: isLoading ? null : _handleRegister,
              icon: isLoading ? null : FontAwesomeIcons.userPlus,
              text: isLoading ? "" : loc.registerButton,
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

  // --- LOGICA DI CREAZIONE ACCOUNT ---

  /// Valida il form ed esegue l'operazione di sign up, mostrando infine il prompt di verifica mail.
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final loc = AppLocalizations.of(context)!;

    final auth = ref.read(authNotifierProvider.notifier);

    try {
      // Invia la richiesta di registrazione a Firebase tramite l'AuthNotifier.
      await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nome: _nameController.text.trim(),
      );

      if (!mounted) return;

      // Mostra un dialogo informativo per spiegare la necessità di convalidare l'indirizzo email.
      await DialogUtils.showInfoDialog(
        context,
        title: loc.verifyEmailTitle,
        content: loc.verifyEmailContent,
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.show(
        context: context,
        title: loc.errorTitle,
        message: e.toString(),
      );
    }
  }
}