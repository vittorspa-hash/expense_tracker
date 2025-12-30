import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

/// FILE: report_bar_chart.dart
/// DESCRIZIONE: Widget che renderizza un grafico a barre per i report mensili.
/// Utilizza la libreria 'fl_chart' per disegnare i dati, calcolando dinamicamente
/// le scale (Y-Axis) e formattando i tooltip e le etichette degli assi.

class ReportBarChart extends StatelessWidget {
  // --- PARAMETRI ---
  // Dati numerici da rappresentare e relative etichette (mesi).
  final List<double> values; 
  final List<String> monthNames; 

  const ReportBarChart({
    super.key,
    required this.values,
    required this.monthNames,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- CALCOLO SCALE ---
    // Determina il valore massimo per adattare l'asse Y e calcola
    // intervalli "sicuri" per evitare sovrapposizioni nelle etichette.
    final double maxY = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 0;
    final double safeInterval = (maxY / 5).clamp(1, double.infinity);
    final double safeMaxY = maxY == 0 ? 100 : maxY * 1.2;

    return Container(
      height: 240.h,
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
      // --- CONFIGURAZIONE GRAFICO ---
      // 
      // Configurazione completa del BarChart: Griglia, Titoli, Interazione e Dati.
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: safeMaxY,

          // Configurazione Griglia (Linee orizzontali tratteggiate)
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: safeInterval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.greyDark,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),

          // Configurazione Assi (Titoli)
          titlesData: FlTitlesData(
            // Asse Sinistro (Valori €)
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50.w,
                interval: safeInterval,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      "€${value.toInt()}",
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: isDark
                            ? AppColors.greyDark
                            : AppColors.greyLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            // Asse Inferiore (Mesi)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < 12) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        monthNames[i].substring(0, 3), // Tronca a 3 lettere
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: isDark
                              ? AppColors.greyDark
                              : AppColors.greyLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // Nasconde bordo esterno grafico
          borderData: FlBorderData(show: false),

          // --- INTERAZIONE (TOOLTIP) ---
          // Configura il comportamento al tocco: mostra un tooltip personalizzato
          // con il valore esatto della spesa.
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) =>
                  isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
              tooltipBorderRadius: BorderRadius.circular(12.r),
              tooltipPadding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              tooltipMargin: 8.h,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  "€ ${rod.toY.toStringAsFixed(2)}",
                  TextStyle(
                    color: isDark ? AppColors.textDark : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                );
              },
            ),
          ),

          // --- RENDERING BARRE ---
          // Genera visivamente le barre applicando un gradiente verticale.
          barGroups: values.asMap().entries.map((entry) {
            final i = entry.key;
            final val = entry.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: val,
                  width: 8.w,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(6.r),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}