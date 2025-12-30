import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

/// FILE: report_empty_state.dart
/// DESCRIZIONE: Widget di stato vuoto (Empty State) unificato per i report.
/// Gestisce visivamente i casi in cui non ci sono dati da mostrare (es. nessun anno, mese o spesa).
/// Supporta due varianti stilistiche:
/// 1. Standard (con cerchio di sfondo): usata in MonthsPage e DaysPage.
/// 2. Minimal (solo icona): usata in YearsPage per un look più pulito.

class ReportEmptyState extends StatelessWidget {
  
  // --- PARAMETRI ---
  final String title;
  final String? subtitle;
  final IconData icon;
  
  // Flag per determinare lo stile visivo:
  // true  -> Mostra l'icona dentro un container circolare (Default).
  // false -> Mostra solo l'icona ingrandita (stile minimal).
  final bool useCircleBackground;

  const ReportEmptyState({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.useCircleBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    // --- TEMA ---
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- COSTRUZIONE UI ---
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          
          // Logica Icona:
          // Se useCircleBackground è true, avvolge l'icona in un container circolare.
          // Altrimenti, mostra l'icona nuda e cruda con dimensione maggiore.
          if (useCircleBackground)
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64.sp,
                color: isDark ? AppColors.greyLight : AppColors.greyDark,
              ),
            )
          else
            Icon(
              icon,
              size: 80.sp,
              color: isDark ? AppColors.greyDark : AppColors.greyLight,
            ),
          
          // Spaziatura dinamica in base allo stile scelto
          SizedBox(height: useCircleBackground ? 24.h : 16.h),
          
          // Titolo
          // Il colore e il peso del font cambiano leggermente in base allo stile
          // per garantire la migliore leggibilità nel contesto specifico.
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              color: isDark 
                  ? (useCircleBackground ? AppColors.textLight : AppColors.greyDark)
                  : (useCircleBackground ? AppColors.textDark2 : AppColors.greyLight),
              fontWeight: useCircleBackground ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          
          // Sottotitolo (Opzionale)
          if (subtitle != null) ...[
            SizedBox(height: 8.h),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? AppColors.greyDark : AppColors.greyLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}