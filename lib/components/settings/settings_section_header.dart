import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

/// FILE: settings_section_header.dart
/// DESCRIZIONE: Componente UI per le intestazioni delle sezioni nella pagina Impostazioni.
/// Visualizza un'icona tematica e un titolo in maiuscolo, garantendo uniformità visiva
/// tra le diverse categorie di configurazione (es. Aspetto, Notifiche).

class SettingsSectionHeader extends StatelessWidget {
  // --- PARAMETRI ---
  // Icona rappresentativa della sezione e titolo testuale.
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

    // --- LAYOUT ---
    // Riga contenente l'icona (colorata con il primary color) e il testo
    // stilizzato in maiuscolo con spaziatura aumentata per leggibilità.
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