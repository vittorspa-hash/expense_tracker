// register_form.dart
import 'package:expense_tracker/components/auth/auth_button.dart';
import 'package:expense_tracker/components/auth/auth_text_field.dart';
// Assicurati che l'import punti al tuo AuthProvider
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart'; // 👈 Indispensabile

class RegisterForm extends StatefulWidget {
  // Rimosso AuthService dal costruttore
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
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

  // Rimosso _isLoading locale, useremo quello del Provider

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

  // ---------------------------------------------------------------------------
  // ⚡️ GESTIONE REGISTRAZIONE
  // ---------------------------------------------------------------------------
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Usiamo read perché siamo dentro una funzione callback
    final provider = context.read<AuthProvider>();

    await provider.signUp(
      context: context,
      email: _emailController.text,
      password: _passwordController.text,
      confermaPassword: _confirmController.text,
      nome: _nameController.text,
      onSuccess: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 👀 ASCOLTIAMO IL PROVIDER
    final provider = context.watch<AuthProvider>();
    final isLoading = provider.isLoading;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // -------------------------------------------------------------------
            // 📦 CARD PRINCIPALE
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    "Registrati per iniziare a tracciare le spese",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark ? AppColors.greyDark : AppColors.greyLight,
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // -------------------------------------------------------------
                  // 🧑 Nome
                  // -------------------------------------------------------------
                  AuthTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocus: _emailFocus,
                    hint: "Nome completo",
                    icon: FontAwesomeIcons.user,
                    capitalization: TextCapitalization.words,
                    enabled: !isLoading, // Disabilita se carica
                    validator: (v) =>
                        v!.trim().isEmpty ? "Inserisci il tuo nome" : null,
                  ),

                  SizedBox(height: 8.h),

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
                    enabled: !isLoading, // Disabilita se carica
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
                  AuthTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    nextFocus: _confirmFocus,
                    hint: "Password",
                    icon: FontAwesomeIcons.lock,
                    obscure: _obscure1,
                    enabled: !isLoading, // Disabilita se carica
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
                  // 🔒 Conferma Password
                  // -------------------------------------------------------------
                  AuthTextField(
                    controller: _confirmController,
                    focusNode: _confirmFocus,
                    hint: "Conferma password",
                    icon: FontAwesomeIcons.lock,
                    obscure: _obscure2,
                    isLast: true,
                    enabled: !isLoading, // Disabilita se carica
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
            // 🚀 BOTTONE REGISTRAZIONE
            // -------------------------------------------------------------------
            AuthButton(
              onPressed: isLoading ? null : _handleRegister,
              icon: isLoading ? null : FontAwesomeIcons.userPlus,
              text: isLoading ? "" : "Registrati",
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
}
