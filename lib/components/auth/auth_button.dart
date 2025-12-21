import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: auth_button.dart
/// DESCRIZIONE: Widget pulsante standardizzato per le schermate di login e registrazione.
/// Supporta stati di disabilitazione, contenuto personalizzato (es. loading spinner)
/// e mantiene coerenza stilistica con il tema dell'applicazione.

class AuthButton extends StatelessWidget {
  // --- PARAMETRI ---
  // Callback per l'azione (null = disabilitato), metadati visivi (icona/testo)
  // e widget opzionale per sostituire il contenuto standard (utile per stati di caricamento).
  final VoidCallback? onPressed; 
  final IconData? icon; 
  final String text;
  final Widget? child; 

  const AuthButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon, 
    this.child, 
  });

  @override
  Widget build(BuildContext context) {
    // --- CALCOLO STATO ---
    // Verifica se il bottone è interattivo basandosi sulla presenza della callback.
    final isDisabled = onPressed == null;

    return ElevatedButton(
      onPressed: onPressed,
      // --- STILE VISIVO ---
      // Adattamento dinamico di colori, ombre ed elevazione in base allo stato
      // (Attivo vs Disabilitato).
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled
            ? AppColors.primary.withValues(alpha: 0.6) 
            : AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: isDisabled ? 2 : 6, 
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6), 
        disabledForegroundColor: AppColors.textLight.withValues(alpha: 0.8), 
      ),
      // --- CONTENUTO ---
      // Renderizza il 'child' se presente (es. CircularProgressIndicator),
      // altrimenti costruisce il layout standard Icona + Testo.
      child: child ??
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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