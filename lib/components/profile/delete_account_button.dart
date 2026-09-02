import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: delete_account_button.dart
/// DESCRIZIONE: Bottone di eliminazione account, con stato di caricamento
/// (spinner al posto di icona+testo). Estratto da ProfilePage per isolare
/// l'azione distruttiva come componente autonomo e riutilizzabile.

class DeleteAccountButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const DeleteAccountButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
        elevation: 6,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: SizedBox(
                width: 20.r,
                height: 20.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textLight,
                ),
              ),
            )
          else ...[
            Icon(
              Icons.delete_outline_rounded,
              size: 22.r,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
            SizedBox(width: 12.w),
          ],
          Text(
            loc.deleteAccountButton,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}