// auth_button.dart
// -----------------------------------------------------------------------------
// 🚀 BOTTONE PER AUTENTICAZIONE
//
// Widget riutilizzabile per i form di autenticazione (login/registrazione).
// Mantiene uno stile consistente con il tema dell'app e gestisce icona + testo.
// -----------------------------------------------------------------------------

import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String text;

  const AuthButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15.r, color: AppColors.textLight),
          SizedBox(width: 12.w),
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
