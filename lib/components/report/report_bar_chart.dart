import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:provider/provider.dart'; 
import 'package:expense_tracker/providers/currency_provider.dart'; 

/// FILE: report_bar_chart.dart
/// DESCRIZIONE: Widget che visualizza un grafico a barre per i report mensili.
/// Utilizza la libreria fl_chart per renderizzare i dati e si adatta
/// dinamicamente alla valuta selezionata per la formattazione degli assi e dei tooltip.

class ReportBarChart extends StatelessWidget {
  // --- PARAMETRI ---
  // Lista dei valori numerici (spese) e dei nomi dei mesi da visualizzare sull'asse X.
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
    // Determina il valore massimo Y e l'intervallo della griglia per evitare
    // grafici piatti o mal proporzionati.
    final double maxY = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 0;
    final double safeInterval = (maxY / 5).clamp(1, double.infinity);
    final double safeMaxY = maxY == 0 ? 100 : maxY * 1.2;

    // --- GESTIONE VALUTA ---
    // Consumer per ricostruire il grafico se cambia la valuta.
    // Calcola la posizione del simbolo (prefisso/suffisso) per l'asse Y.
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        final currency = currencyProvider.currentCurrency;
        final symbol = currencyProvider.currencySymbol;
        
        final bool isSymbolPrefix = currency == Currency.usd || currency == Currency.jpy;

        // --- CONTENITORE GRAFICO ---
        // Box con stile coerente (ombra, bordi) che ospita il grafico.
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

              // --- GRIGLIA ---
              // Linee orizzontali tratteggiate per facilitare la lettura dei livelli.
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

              // --- TITOLI ASSI ---
              // Configurazione dell'asse sinistro (Valori) e inferiore (Mesi).
              titlesData: FlTitlesData(
                // Asse Sinistro (Valori)
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50.w,
                    interval: safeInterval,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      
                      // Formattazione compatta per l'asse Y (es. $100 o 100€).
                      // Mantiene i numeri interi per pulizia visiva.
                      final String textValue;
                      if (isSymbolPrefix) {
                        textValue = "$symbol${value.toInt()}";
                      } else {
                        textValue = "${value.toInt()}$symbol";
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          textValue,
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
                        // Mostra le prime 3 lettere del nome del mese.
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

              borderData: FlBorderData(show: false),

              // --- INTERAZIONE (TOOLTIP) ---
              // Mostra il valore esatto formattato al tocco della barra.
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
                      currencyProvider.formatAmount(rod.toY),
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
              // Genera le barre con gradiente verticale basato sul colore primario.
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
      },
    );
  }
}