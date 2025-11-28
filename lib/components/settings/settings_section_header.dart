// settings_section_header.dart
// -----------------------------------------------------------------------------
// 📋 WIDGET INTESTAZIONE SEZIONE IMPOSTAZIONI
// -----------------------------------------------------------------------------
// Mostra l'intestazione di una sezione nelle impostazioni con:
// - Icona a sinistra
// - Titolo in grassetto
// - Stile coerente con il tema dell'app
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

class SettingsSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const SettingsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.r,
            color: AppColors.primary,
          ),
          SizedBox(width: 8.w),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.greyDark : AppColors.greyLight,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}