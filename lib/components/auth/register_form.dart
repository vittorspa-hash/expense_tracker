import 'package:expense_tracker/components/auth/auth_button.dart';
import 'package:expense_tracker/components/auth/auth_text_field.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

/// FILE: register_form.dart
/// DESCRIZIONE: Widget contenente il form di registrazione. Raccoglie i dati dell'utente
/// (Nome, Email, Password), gestisce la validazione dei campi e comunica con il
/// Provider di autenticazione per la creazione di un nuovo account Firebase.

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  // --- GESTIONE STATO E CONTROLLER ---
  // Controller per l'input testuale, nodi per la gestione del focus
  // e variabili per la visibilità delle password.
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
  // Rilascio dei controller alla distruzione del widget.
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

  // --- BUILD UI ---
  // Costruzione interfaccia con adattamento al tema e ascolto dello stato di loading.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AuthProvider>();
    final isLoading = provider.isLoading;
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // --- CARD INSERIMENTO DATI ---
            // Contenitore stilizzato con ombra e campi di input.
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(
                      alpha: isDark ? 0.3 : 0.08,
                    ),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
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

                  // Input Nome
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

                  // Input Email
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

                  // Input Password
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

                  // Input Conferma Password
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

            // --- AZIONE DI REGISTRAZIONE ---
            // Bottone principale per inviare il form.
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

  // --- FEEDBACK UTENTE ---
  // Helper per mostrare messaggi tramite SnackBar.
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.snackBar,
        content: Text(msg, style: TextStyle(color: AppColors.textLight)),
      ),
    );
  }

  // --- LOGICA DI REGISTRAZIONE ---
  // Gestisce la validazione dei dati, la corrispondenza delle password,
  // la chiamata al servizio di registrazione e la visualizzazione del dialog di successo.
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final loc = AppLocalizations.of(context)!;

    if (_passwordController.text != _confirmController.text) {
      _showSnack(loc.passwordsDoNotMatch, isError: true);
      return;
    }

    final provider = context.read<AuthProvider>();

    try {
      await provider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nome: _nameController.text.trim(),
      );

      if (!mounted) return;

      // Successo: Informa l'utente della verifica email necessaria
      await DialogUtils.showInfoDialog(
        context,
        title: loc.verifyEmailTitle,
        content: loc.verifyEmailContent,
      );

    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }
}