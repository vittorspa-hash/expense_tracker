// profile_tile.dart
// -----------------------------------------------------------------------------
// 📝 WIDGET PROFILE TILE (MOBILE ONLY)
// -----------------------------------------------------------------------------
// Gestisce la visualizzazione di una singola voce del profilo utente:
// - Icona a sinistra
// - Titolo e valore centrale
// - Pulsante azione / icona modificabile a destra
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

class ProfileTile extends StatelessWidget {
  // 🔧 Parametri principali
  final IconData icon; // Icona sinistra
  final String title; // Titolo della voce
  final String? value; // Valore della voce
  final VoidCallback? onPressed; // Callback azione sul trailing
  final IconData trailingIcon; // Icona trailing (default edit)
  final String tooltip; // Tooltip per il pulsante
  final Widget? trailingWidget; // Widget trailing personalizzato

  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.onPressed,
    this.trailingIcon = Icons.edit_outlined,
    required this.tooltip,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // -----------------------------------------------------------------
          // 🎨 ICONA SINISTRA CON GRADIENT E OMBRA
          // -----------------------------------------------------------------
          Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 24.r, color: AppColors.primary),
          ),

          SizedBox(width: 16.w),

          // -----------------------------------------------------------------
          // 📄 COLONNA CENTRALE: TITOLO + VALORE
          // -----------------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyLight,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value ?? "Non disponibile",
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // -----------------------------------------------------------------
          // 🖱 BOTTONE/TRAILING WIDGET
          // -----------------------------------------------------------------
          trailingWidget ??
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderLight.withValues(alpha: 0.2)
                        : AppColors.borderDark.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    trailingIcon,
                    size: 20.r,
                    color: isDark ? AppColors.greyDark : AppColors.greyLight,
                  ),
                  tooltip: tooltip,
                  onPressed: onPressed,
                  padding: EdgeInsets.zero,
                ),
              ),
        ],
      ),
    );
  }
}
