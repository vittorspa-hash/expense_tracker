// FILE: report_pie_chart.dart
// DESCRIZIONE: Widget che visualizza un grafico a torta per la ripartizione
// delle spese per categoria in un anno. Segue lo stesso pattern di ReportBarChart:
// Utilizza currencyNotifierProvider per la valuta corrente e mantiene uno stile card coerente.

import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportPieChart extends ConsumerStatefulWidget {
  // Mappa categoria -> totale già convertito nella valuta corrente.
  // Il filtraggio per arco temporale è delegato ai provider/calculator a monte.
  final Map<ExpenseCategory, double> data;

  const ReportPieChart({super.key, required this.data});

  @override
  ConsumerState<ReportPieChart> createState() => _ReportPieChartState();
}

class _ReportPieChartState extends ConsumerState<ReportPieChart> {
  // Indice della sezione selezionata per l'effetto di espansione interattiva.
  // Il valore -1 indica che nessuna sezione è attualmente focalizzata.
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final currencyNotifier = ref.watch(currencyNotifierProvider);

    // --- GUARD & FILTER ---
    // Estrae e filtra solo le voci con importo positivo per prevenire artefatti visivi nel grafico
    final activeEntries = widget.data.entries.where((e) => e.value > 0).toList();
    if (activeEntries.isEmpty) return const SizedBox.shrink();

    // Calcolo del volume complessivo delle spese per determinare le percentuali di ripartizione
    final double totalAmount = activeEntries.fold(0.0, (sum, entry) => sum + entry.value);

    // --- COSTRUZIONE SEZIONI GRAFICO ---
    final pieSections = activeEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      final isTouched = index == _touchedIndex;

      final double percentage = (amount / totalAmount) * 100;
      final double sectionRadius = isTouched ? 72.r : 60.r;

      return PieChartSectionData(
        value: amount,
        color: category.color,
        radius: sectionRadius,
        // Mostra la percentuale testuale solo per fette ampie (>= 5%) per evitare sovrapposizioni
        title: percentage >= 5 ? "${percentage.toStringAsFixed(0)}%" : "",
        titleStyle: TextStyle(
          fontSize: isTouched ? 13.sp : 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
          shadows: [Shadow(color: AppColors.shadow, blurRadius: 4)],
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- ELEMENTO GRAFICO (PIE CHART) ---
          SizedBox(
            height: 200.h,
            child: PieChart(
              PieChartData(
                sections: pieSections,
                centerSpaceRadius: 40.r,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // --- LEGENDA INTERATTIVA ---
          Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: activeEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value.key;
              final amount = entry.value.value;
              final isSelected = index == _touchedIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _touchedIndex = isSelected ? -1 : index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? category.color.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicatore cromatico della categoria
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      
                      // Etichetta testuale localizzata
                      Text(
                        category.label(loc),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      
                      // Importo monetario formattato
                      Text(
                        currencyNotifier.formatAmount(amount),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.greyDark : AppColors.greyLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}