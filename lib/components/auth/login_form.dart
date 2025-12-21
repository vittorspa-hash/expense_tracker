import 'package:expense_tracker/components/auth/auth_button.dart';
import 'package:expense_tracker/components/auth/auth_text_field.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

/// FILE: login_form.dart
/// DESCRIZIONE: Widget contenente il form di accesso. Gestisce l'input utente,
/// la validazione dei campi, la chiamata al Provider di autenticazione e
/// la logica di verifica email/recupero password.

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // --- GESTIONE STATO E CONTROLLER ---
  // Definizione delle chiavi per la validazione del form e dei controller
  // per gestire l'input testuale e il focus dei campi.
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure = true;

  // --- PULIZIA RISORSE ---
  // Rilascio dei controller e focus node alla chiusura del widget per evitare memory leak.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // --- BUILD UI ---
  // Costruzione dell'interfaccia con gestione adattiva del tema (Light/Dark)
  // e monitoraggio dello stato di caricamento dal Provider.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final provider = context.watch<AuthProvider>();
    final isLoading = provider.isLoading;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
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
                    "Bentornato!",
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textLight : AppColors.textDark2,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Accedi al tuo account per continuare",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark ? AppColors.greyDark : AppColors.greyLight,
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // --- CAMPI DI INPUT ---
                  // Componenti personalizzati per l'inserimento di Email e Password
                  // con validazione integrata.
                  AuthTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocus: _passwordFocus,
                    hint: "Email",
                    icon: FontAwesomeIcons.envelope,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Inserisci l'email";
                      }
                      if (!value.contains("@")) {
                        return "Email non valida";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 8.h),

                  AuthTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hint: "Password",
                    icon: FontAwesomeIcons.lock,
                    obscure: _obscure,
                    isLast: true,
                    enabled: !isLoading,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Inserisci la password";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 8.h),

                  // --- LINK AZIONI SECONDARIE ---
                  // Pulsante per avviare il flusso di reset della password.
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
                        "Password dimenticata?",
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
            ),

            SizedBox(height: 10.h),

            // --- AZIONI PRINCIPALI ---
            // Bottone di Login che mostra un indicatore di caricamento durante l'attesa.
            AuthButton(
              onPressed: isLoading ? null : _handleLogin,
              icon: isLoading ? null : FontAwesomeIcons.rightToBracket,
              text: isLoading ? "" : "Accedi",
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
  // Metodo helper per mostrare messaggi (errori o conferme) tramite SnackBar.
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.snackBar,
        content: Text(msg, style: TextStyle(color: AppColors.textLight)),
      ),
    );
  }

  // --- LOGICA DI LOGIN ---
  // Coordina la validazione del form, l'autenticazione tramite Provider,
  // la gestione degli errori e il controllo obbligatorio della verifica email.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();

    try {
      // 1. Chiamata al Provider (Logica Pura)
      final user = await provider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // 2. Controllo Email Verificata (Logica UI)
      if (!user.emailVerified) {
        // 2a. Mostra Dialogo
        final confirm = await DialogUtils.showConfirmDialog(
          context,
          title: "Email non verificata",
          content: "Devi confermare la tua email prima di accedere.",
          confirmText: "Rinvia Email",
          cancelText: "Chiudi",
        );

        if (!mounted) return;

        if (confirm == true) {
          // 2b. Invia Email Verifica (se richiesto)
          try {
            await provider.sendVerificationEmail(user);
            _showSnack("Email di verifica inviata!");
          } catch (e) {
            _showSnack(e.toString(), isError: true);
          }
        }

        // 2c. Forza il Logout perché l'accesso è bloccato
        await provider.signOut();
        return;
      }

      // 3. Successo -> Navigazione (Es. alla Dashboard)
      // Qui dovresti gestire la navigazione, esempio:
      // Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      // 4. Gestione Errori Login
      _showSnack(e.toString(), isError: true);
    }
  }

  // --- RECUPERO PASSWORD ---
  // Gestisce l'invio dell'email di reset password tramite il Provider.
  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack("Inserisci la tua email per il recupero", isError: true);
      return;
    }

    try {
      await context.read<AuthProvider>().resetPassword(email: email);
      _showSnack("Email di recupero inviata a $email");
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }
}