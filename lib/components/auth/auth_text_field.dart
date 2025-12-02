// auth_text_field.dart
// -----------------------------------------------------------------------------
// 📝 TEXTFIELD RIUTILIZZABILE
//
// Campo di testo personalizzato utilizzato nel Login e Register form.
// Comprende: icona, hint, gestione del focus, validazione, modalità password,
// supporto al tema scuro e animazioni fluide.
// -----------------------------------------------------------------------------

import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// -----------------------------------------------------------------------------
// 🧱 AuthTextField – Widget riutilizzabile
// -----------------------------------------------------------------------------
class AuthTextField extends StatelessWidget {
  final TextEditingController controller; // Controller del campo
  final String hint; // Testo segnaposto
  final IconData icon; // Icona a sinistra
  final String? Function(String?)? validator; // Validazione personalizzata
  final bool obscure; // Obscure text per password
  final VoidCallback? onToggleObscure; // Funzione per cambiare visibilità password
  final TextInputType keyboardType; // Tipo tastiera (email, testo, numeri)
  final TextCapitalization capitalization; // Comportamento di capitalizzazione
  final FocusNode? focusNode; // Focus attuale
  final FocusNode? nextFocus; // Focus del campo successivo
  final bool isLast; // Ultimo campo del form?

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
  });

  @override
  Widget build(BuildContext context) {
    // 🔦 Determiniamo se il tema è scuro o chiaro
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      validator: validator,
      textInputAction:
          isLast 
          ? TextInputAction.done
          : TextInputAction.next,
      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),

      // 🔄 Gestione del focus quando l’utente preme "invio"
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          // Sposta il focus al prossimo
          FocusScope.of(focusNode!.context!).requestFocus(nextFocus);
        } else {
          // Rimuove la tastiera
          FocusScope.of(focusNode!.context!).unfocus();
        }
      },

      // -------------------------------------------------------------------------
      // 🎨 DECORAZIONE DEL CAMPO – stile moderno, pulito ed elevato
      // -------------------------------------------------------------------------
      decoration: InputDecoration(
        // 📌 Icona principale a sinistra
        prefixIcon: Container(
          margin: EdgeInsets.only(right: 12.w),
          child: Icon(icon, size: 16.sp, color: AppColors.primary),
        ),

        // 👁‍🗨 Icona per mostra/nascondi password
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                icon: Icon(
                  obscure ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                  size: 14.sp,
                  color: isDark ? AppColors.greyDark : AppColors.greyLight,
                ),
                onPressed: onToggleObscure,
              ),

        // 💬 Hint text
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: isDark ? AppColors.greyDark : AppColors.greyLight,
        ),

        // 🎨 Colore di sfondo diverso per light/dark mode
        filled: true,
        fillColor: isDark ? AppColors.borderDark : AppColors.borderLight,

        // 🔲 Bordi moderni
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),

        // Bordo quando non è selezionato
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: isDark ? AppColors.backgroundDark : AppColors.borderLight,
            width: 1,
          ),
        ),

        // Bordo in focus
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1),
        ),

        // Bordi in caso di errore
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.delete, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.delete, width: 1),
        ),

        // 🔘 Spaziatura interna
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }
}
