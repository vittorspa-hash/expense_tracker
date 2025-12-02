// settings_tile.dart
// -----------------------------------------------------------------------------
// ⚙️ WIDGET SETTINGS TILE
// -----------------------------------------------------------------------------
// Gestisce la visualizzazione di una singola voce delle impostazioni:
// - Icona a sinistra
// - Titolo e sottotitolo centrale
// - Widget trailing personalizzabile (switch, icona, etc.)
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

class SettingsTile extends StatelessWidget {
  // 🔧 Parametri principali
  final IconData icon; // Icona sinistra
  final String title; // Titolo della voce
  final String? subtitle; // Sottotitolo/valore
  final VoidCallback? onPressed; // Callback azione
  final IconData trailingIcon; // Icona trailing (default chevron)
  final Widget? trailingWidget; // Widget trailing personalizzato

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onPressed,
    this.trailingIcon = Icons.chevron_right_rounded,
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
              color: AppColors.primary.withValues(alpha: 0.15),
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
          // 📄 COLONNA CENTRALE: TITOLO + SOTTOTITOLO
          // -----------------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.greyLight,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // -----------------------------------------------------------------
          // 🖱 TRAILING WIDGET O ICONA
          // - Può essere sovrascritto da trailingWidget personalizzato
          // -----------------------------------------------------------------
          trailingWidget ??
              (onPressed != null
                  ? Container(
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
                          color: isDark
                              ? AppColors.greyDark
                              : AppColors.greyLight,
                        ),
                        onPressed: onPressed,
                        padding: EdgeInsets.zero,
                      ),
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
