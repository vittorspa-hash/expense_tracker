// login_form.dart
// -----------------------------------------------------------------------------
// 🔐 FORM DI LOGIN UTENTE
//
// Gestisce l’accesso dell’utente tramite:
// - Email
// - Password
//
// Include validazione dei campi, gestione dei FocusNode, toggle visibilità
// password, integrazione con AuthService per eseguire il login e pulsante per il
// recupero della password. 
// -----------------------------------------------------------------------------

import 'package:expense_tracker/components/auth/auth_button.dart';
import 'package:expense_tracker/components/auth/auth_text_field.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginForm extends StatefulWidget {
  final AuthService authService;
  const LoginForm({super.key, required this.authService});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // Chiave per validare l'intero form
  final _formKey = GlobalKey<FormState>();

  // Controller per input testo
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // FocusNode per gestione del flusso tra input
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // Gestione visibilità password
  bool _obscure = true;

  @override
  void dispose() {
    // Libera i controller e i focus node
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rileva tema scuro/chiaro per colori dinamici
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // -------------------------------------------------------------------
            // 🧱 CARD PRINCIPALE DEL FORM DI LOGIN
            // -------------------------------------------------------------------
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

              // -----------------------------------------------------------------
              // 📋 CONTENUTO INTERNO DELLA CARD
              // -----------------------------------------------------------------
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo
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

                  // Descrizione
                  Text(
                    "Accedi al tuo account per continuare",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark ? AppColors.greyDark : AppColors.greyLight,
                    ),
                  ),

                  SizedBox(height: 18.h),

                  // -------------------------------------------------------------
                  // 📧 Email
                  // -------------------------------------------------------------
                  AuthTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocus: _passwordFocus,
                    hint: "Email",
                    icon: FontAwesomeIcons.envelope,
                    keyboardType: TextInputType.emailAddress,
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

                  // -------------------------------------------------------------
                  // 🔒 Password
                  // -------------------------------------------------------------
                  AuthTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hint: "Password",
                    icon: FontAwesomeIcons.lock,
                    obscure: _obscure,
                    isLast: true,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Inserisci la password";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 8.h),

                  // -------------------------------------------------------------
                  // ❓ Link recupero password
                  // -------------------------------------------------------------
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => widget.authService.resetPassword(
                        context,
                        _emailController.text,
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                      ),
                      child: Text(
                        "Password dimenticata?",
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textDark2,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                          decoration: TextDecoration.underline,
                          decorationColor: isDark
                              ? AppColors.textLight
                              : AppColors.textDark2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10.h),

            // -------------------------------------------------------------------
            // 🚀 BOTTONE DI LOGIN
            // -------------------------------------------------------------------
            AuthButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.authService.signIn(
                    context: context,
                    email: _emailController.text,
                    password: _passwordController.text,
                    onSuccess: () => setState(() {}),
                  );
                }
              },
              icon: FontAwesomeIcons.rightToBracket,
              text: "Accedi",
            ),

            SizedBox(height: 18.h),
          ],
        ),
      ),
    );
  }
}
