// login_form.dart
import 'package:expense_tracker/components/auth/auth_button.dart';
import 'package:expense_tracker/components/auth/auth_text_field.dart';
// Assicurati che questo import punti al file dove hai messo la classe AuthProvider
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart'; // 👈 Importante per usare context.read/watch

class LoginForm extends StatefulWidget {
  // Rimosso AuthService dal costruttore, ora usiamo Provider
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure = true;

  // Rimosso bool _isLoading locale. Ora usiamo provider.isLoading

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ⚡️ GESTIONE LOGIN
  // ---------------------------------------------------------------------------
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Recuperiamo il provider senza ascoltare i cambiamenti (listen: false)
    // perché siamo dentro una funzione, non nel build.
    final provider = context.read<AuthProvider>();

    // Non serve più il try-catch qui per gestire il loading UI,
    // lo fa il provider notificando i listener.
    await provider.signIn(
      context: context,
      email: _emailController.text,
      password: _passwordController.text,
      onSuccess: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 👀 ASCOLTIAMO IL PROVIDER
    // Usiamo watch così il widget si ricostruisce quando isLoading cambia (true/false)
    final provider = context.watch<AuthProvider>();
    final isLoading = provider.isLoading; // Alias per comodità

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
                    enabled:
                        !isLoading, // Disabilita se il provider sta caricando
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
                    enabled:
                        !isLoading, // Disabilita se il provider sta caricando
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
                      // Chiamata al provider
                      onPressed: isLoading
                          ? null
                          : () => provider.resetPassword(
                              context,
                              email: _emailController.text.trim(),
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

            // -------------------------------------------------------------------
            // 🚀 BOTTONE LOGIN
            // -------------------------------------------------------------------
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
}
