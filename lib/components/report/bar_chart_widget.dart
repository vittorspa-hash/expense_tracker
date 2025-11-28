// bar_chart_widget.dart
// -----------------------------------------------------------------------------
// 📊 WIDGET GRAFICO A BARRE (BAR CHART WIDGET)
// -----------------------------------------------------------------------------
// Mostra un grafico a barre mensile delle spese con:
// - Titoli asse X e Y
// - Tooltip personalizzati
// - Gradiente barre
// - Adattamento modalità chiaro/scuro
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

class BarChartWidget extends StatelessWidget {
  final List<double> values; // 🔹 Lista dei valori mensili
  final List<String> monthNames; // 🔹 Nomi dei mesi

  const BarChartWidget({
    super.key,
    required this.values,
    required this.monthNames,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🔹 Calcolo valore massimo Y e intervallo per linee orizzontali
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
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: safeMaxY,

          // ---------------------------------------------------------------------
          // 🔹 GRIGLIA ORIZZONTALE
          // ---------------------------------------------------------------------
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

          // ---------------------------------------------------------------------
          // 🔹 TITOLI ASSE X E Y
          // ---------------------------------------------------------------------
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50.w,
                interval: safeInterval,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    "€${value.toInt()}",
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: isDark ? AppColors.greyDark : AppColors.greyLight,
                      fontWeight: FontWeight.w600,
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
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < 12) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        monthNames[i].substring(0, 3),
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

          // ---------------------------------------------------------------------
          // 🔹 BORDO ESTERNO
          // ---------------------------------------------------------------------
          borderData: FlBorderData(show: false),

          // ---------------------------------------------------------------------
          // 🔹 TOOLTIPS AL PASSAGGIO SULLE BARRE
          // ---------------------------------------------------------------------
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

          // ---------------------------------------------------------------------
          // 🔹 CREAZIONE BARRE
          // ---------------------------------------------------------------------
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
