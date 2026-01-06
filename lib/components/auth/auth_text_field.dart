import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// FILE: auth_text_field.dart
/// DESCRIZIONE: Componente UI riutilizzabile per i campi di input nei form di autenticazione.
/// Centralizza la logica di stile, validazione, gestione del focus, visibilità password
/// e adattamento cromatico (Light/Dark mode) e di stato (Abilitato/Disabilitato).

class AuthTextField extends StatelessWidget {
  // --- PARAMETRI DI CONFIGURAZIONE ---
  // Controller per il testo, callback per azioni (es. toggle password),
  // nodi per la gestione del focus e flag di stato.
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;
  final TextCapitalization capitalization;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final bool isLast;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
    this.capitalization = TextCapitalization.none,
    this.focusNode,
    this.nextFocus,
    this.isLast = false,
    this.enabled = true, 
  });

  @override
  Widget build(BuildContext context) {
    // --- TEMA E STILE TESTO ---
    // Rileva il tema corrente per adattare i colori del testo e disabilita visivamente
    // il componente se la proprietà 'enabled' è falsa.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      cursorColor: AppColors.primary,
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      validator: validator,
      enabled: enabled,
      textInputAction:
          isLast 
          ? TextInputAction.done
          : TextInputAction.next,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: enabled
            ? null
            : (isDark
                ? AppColors.greyDark.withValues(alpha: 0.5)
                : AppColors.greyLight.withValues(alpha: 0.5)),
      ),

      // --- GESTIONE FOCUS ---
      // Logica per spostare il focus al campo successivo o chiudere la tastiera
      // quando l'utente preme il tasto di conferma.
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(focusNode!.context!).requestFocus(nextFocus);
        } else {
          FocusScope.of(focusNode!.context!).unfocus();
        }
      },

      // --- DECORAZIONE VISIVA ---
      // Configurazione completa di icone (Prefix/Suffix), colori di riempimento
      // e bordi differenziati per stato (Abilitato, Focus, Errore, Disabilitato).
      decoration: InputDecoration(
        // Icona sinistra
        prefixIcon: Container(
          margin: EdgeInsets.only(right: 12.w),
          child: Icon(
            icon,
            size: 16.sp,
            color: enabled
                ? AppColors.primary
                : (isDark
                    ? AppColors.greyDark.withValues(alpha: 0.4)
                    : AppColors.greyLight.withValues(alpha: 0.4)),
          ),
        ),

        // Toggle Password (Occhio)
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                icon: Icon(
                  obscure ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                  size: 14.sp,
                  color: enabled
                      ? (isDark ? AppColors.greyDark : AppColors.greyLight)
                      : (isDark
                          ? AppColors.greyDark.withValues(alpha: 0.3)
                          : AppColors.greyLight.withValues(alpha: 0.3)),
                ),
                onPressed: enabled ? onToggleObscure : null,
              ),

        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: isDark ? AppColors.greyDark : AppColors.greyLight,
        ),

        filled: true,
        fillColor: enabled
            ? (isDark ? AppColors.borderDark.withValues(alpha: 0.7) : AppColors.borderLight.withValues(alpha: 0.7))
            : (isDark
                ? AppColors.borderDark.withValues(alpha: 0.5)
                : AppColors.borderLight.withValues(alpha: 0.5)),

        // Configurazione Bordi
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: isDark ? AppColors.backgroundDark : AppColors.borderLight,
            width: 1,
          ),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.backgroundDark.withValues(alpha: 0.5)
                : AppColors.borderLight.withValues(alpha: 0.5),
            width: 1,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.delete, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.delete, width: 1),
        ),

        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }
}