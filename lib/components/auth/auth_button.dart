// auth_button.dart
// -----------------------------------------------------------------------------
// 🚀 BOTTONE PER AUTENTICAZIONE
//
// Widget riutilizzabile per i form di autenticazione (login/registrazione).
// Mantiene uno stile consistente con il tema dell'app e gestisce icona + testo.
// Supporta uno stato di caricamento con indicatore circolare.
// -----------------------------------------------------------------------------

import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthButton extends StatelessWidget {
  final VoidCallback? onPressed; //  Nullable per permettere disabilitazione
  final IconData? icon; //  Nullable per nascondere durante il loading
  final String text;
  final Widget? child; //  Per mostrare custom content (es. loading indicator)

  const AuthButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon, 
    this.child, 
  });

  @override
  Widget build(BuildContext context) {
    // Determina se il bottone è disabilitato
    final isDisabled = onPressed == null;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled
            ? AppColors.primary.withValues(alpha: 0.6) //  Colore ridotto se disabilitato
            : AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: isDisabled ? 2 : 6, //  Elevazione ridotta se disabilitato
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6), // Colore quando disabilitato
        disabledForegroundColor: AppColors.textLight.withValues(alpha: 0.8), // Colore testo quando disabilitato
      ),
      //  Mostra child custom se fornito, altrimenti layout normale
      child: child ??
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //  Mostra icona solo se fornita
              if (icon != null) ...[
                Icon(icon, size: 15.r, color: AppColors.textLight),
                SizedBox(width: 12.w),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
    );
  }
}