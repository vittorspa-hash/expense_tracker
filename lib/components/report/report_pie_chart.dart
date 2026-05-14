// FILE: report_pie_chart.dart
// DESCRIZIONE: Widget che visualizza un grafico a torta per la ripartizione
// delle spese per categoria in un anno. Segue lo stesso pattern di ReportBarChart:
// Consumer<CurrencyProvider> per valuta, stile card coerente con il resto dei report.

import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportPieChart extends ConsumerStatefulWidget {
  // --- PARAMETRI ---
  // Mappa categoria -> totale già convertito nella valuta corrente.
  // Il filtraggio per anno è già avvenuto nel provider/calculator.
  final Map<ExpenseCategory, double> data;

  const ReportPieChart({super.key, required this.data});

  @override
  ConsumerState<ReportPieChart> createState() => _ReportPieChartState();
}

class _ReportPieChartState extends ConsumerState<ReportPieChart> {
  // --- STATO LOCALE ---
  // Indice della sezione "toccata" per il comportamento di espansione interattiva.
  // -1 indica nessuna sezione selezionata.
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    // --- GUARD: DATI VUOTI ---
    // Filtra le categorie con valore zero per evitare sezioni invisibili nel grafico.
    final filteredData = Map.fromEntries(
      widget.data.entries.where((e) => e.value > 0),
    );

    if (filteredData.isEmpty) return const SizedBox.shrink();

    // --- CALCOLO TOTALE ---
    // Necessario per calcolare le percentuali di ogni sezione.
    final double total = filteredData.values.fold(0.0, (a, b) => a + b);

    // --- COSTRUZIONE SEZIONI ---
    // Una PieChartSectionData per ogni categoria con valore > 0.
    // La sezione toccata si espande (radius maggiore) per feedback visivo.
    final sections = filteredData.entries.toList().asMap().entries.map((entry) {
      final i = entry.key;
      final category = entry.value.key;
      final value = entry.value.value;
      final isTouched = i == _touchedIndex;

      final double percentage = (value / total) * 100;
      final double radius = isTouched ? 72.r : 60.r;

      return PieChartSectionData(
        value: value,
        color: category.color,
        radius: radius,
        // Mostra la percentuale solo se la sezione è abbastanza grande
        // per evitare label sovrapposte su sezioni piccole.
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
          // --- GRAFICO ---
          SizedBox(
            height: 200.h,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40.r,

                // --- INTERAZIONE ---
                // Al tocco aggiorna _touchedIndex per espandere la sezione.
                // Al rilascio (index -1) resetta la selezione.
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // --- LEGENDA ---
          // Wrap a due colonne: ogni voce mostra dot colorato,
          // nome localizzato della categoria e totale formattato.
          Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: filteredData.entries.toList().asMap().entries.map((
              entry,
            ) {
              final i = entry.key;
              final category = entry.value.key;
              final value = entry.value.value;
              final isSelected = i == _touchedIndex;

              return GestureDetector(
                // Tap sulla legenda = stessa interazione della sezione del grafico
                onTap: () {
                  setState(() {
                    _touchedIndex = isSelected ? -1 : i;
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
                      // Dot colorato
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      // Nome categoria localizzato
                      Text(
                        category.label(loc),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textDark,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // Importo formattato nella valuta corrente
                      Text(
                        ref.watch(currencyNotifierProvider).formatAmount(value),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.greyDark
                              : AppColors.greyLight,
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
