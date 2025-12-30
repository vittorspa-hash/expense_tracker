import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

/// FILE: report_section_header.dart
/// DESCRIZIONE: Widget riutilizzabile per le intestazioni delle sezioni
/// nei report (es. "Dettaglio mensile", "Spese giornaliere").
/// Garantisce consistenza di stile (font, colore, spaziatura) attraverso
/// tutte le schermate di reportistica (Years, Months, Days).

class ReportSectionHeader extends StatelessWidget {
  
  // --- PARAMETRI ---
  final String title;
  final EdgeInsetsGeometry? padding;

  const ReportSectionHeader({
    super.key, 
    required this.title,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // --- TEMA ---
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- COSTRUZIONE UI ---
    // Allinea il testo a sinistra con un padding standard (sovrascrivibile).
    // Utilizza uno stile di testo grigio intermedio per separare visivamente le sezioni.
    return Padding(
      // Default padding se non specificato (20.w laterale standard)
      padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.greyDark : AppColors.greyLight,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}