// register_form.dart
// -----------------------------------------------------------------------------
// 📝 FORM DI REGISTRAZIONE UTENTE
//
// Gestisce la creazione di un nuovo account tramite:
// - Nome completo
// - Email
// - Password + Conferma password
//
// Include validazione dei campi, gestione dei focus, gestione visibilità
// password e integrazione diretta con AuthModel per eseguire la registrazione.
// L’intero form è stilizzato per mantenere coerenza con il tema dell’app.
// -----------------------------------------------------------------------------

import 'package:expense_tracker/components/auth/text_field.dart';
import 'package:expense_tracker/models/auth_model.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterForm extends StatefulWidget {
  final AuthModel authModel;
  const RegisterForm({super.key, required this.authModel});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  // Chiave del form per validazione generale
  final _formKey = GlobalKey<FormState>();

  // Controller per i campi di input
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // FocusNode per controllare il passaggio tra un campo e l’altro
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  // Gestione visibilità password
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    // Libera tutte le risorse dei controller e focus node
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // -------------------------------------------------------------------
            // 📦 CARD PRINCIPALE DEL FORM
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
              // 🧭 CONTENUTO DEL FORM
              // -----------------------------------------------------------------
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo form
                  Text(
                    "Crea un account",
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textLight : AppColors.textDark2,
                      letterSpacing: 0.3,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Sottotitolo form
                  Text(
                    "Registrati per iniziare a tracciare le spese",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark ? AppColors.greyDark : AppColors.greyLight,
                    ),
                  ),

                  SizedBox(height: 18.h),

                  // -------------------------------------------------------------
                  // 🧑 Nome completo
                  // -------------------------------------------------------------
                  ModernTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocus: _emailFocus,
                    hint: "Nome completo",
                    icon: FontAwesomeIcons.user,
                    capitalization: TextCapitalization.words,
                    validator: (v) =>
                        v!.trim().isEmpty ? "Inserisci il tuo nome" : null,
                  ),

                  SizedBox(height: 8.h),

                  // -------------------------------------------------------------
                  // 📧 Email
                  // -------------------------------------------------------------
                  ModernTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocus: _passwordFocus,
                    hint: "Email",
                    icon: FontAwesomeIcons.envelope,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Inserisci l'email";
                      }
                      if (!v.contains("@")) return "Email non valida";
                      return null;
                    },
                  ),

                  SizedBox(height: 8.h),

                  // -------------------------------------------------------------
                  // 🔒 Password
                  // -------------------------------------------------------------
                  ModernTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    nextFocus: _confirmFocus,
                    hint: "Password",
                    icon: FontAwesomeIcons.lock,
                    obscure: _obscure1,
                    onToggleObscure: () =>
                        setState(() => _obscure1 = !_obscure1),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Inserisci la password";
                      }
                      if (v.length < 6) {
                        return "Minimo 6 caratteri";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 8.h),

                  // -------------------------------------------------------------
                  // 🔒 Conferma password
                  // -------------------------------------------------------------
                  ModernTextField(
                    controller: _confirmController,
                    focusNode: _confirmFocus,
                    hint: "Conferma password",
                    icon: FontAwesomeIcons.lock,
                    obscure: _obscure2,
                    isLast: true,
                    onToggleObscure: () =>
                        setState(() => _obscure2 = !_obscure2),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Conferma la password";
                      }
                      if (v != _passwordController.text) {
                        return "Le password non coincidono";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 10.h),

            // -------------------------------------------------------------------
            // 🚀 BOTTONE DI REGISTRAZIONE
            // -------------------------------------------------------------------
            ElevatedButton(
              onPressed: () {
                // Valida tutti i campi prima di procedere
                if (_formKey.currentState!.validate()) {
                  widget.authModel.signUp(
                    context: context,
                    email: _emailController.text,
                    password: _passwordController.text,
                    confermaPassword: _confirmController.text,
                    nome: _nameController.text,
                    onSuccess: () => setState(() {}),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textLight,
                elevation: 6,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),

              // Contenuto visivo del pulsante
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.userPlus,
                    size: 15.r,
                    color: AppColors.textLight,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    "Registrati",
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),
          ],
        ),
      ),
    );
  }
}
