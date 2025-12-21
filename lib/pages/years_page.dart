import 'package:expense_tracker/components/report/bar_chart_widget.dart';
import 'package:expense_tracker/components/report/period_list_item_widget.dart';
import 'package:expense_tracker/components/report/total_card_widget.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/pages/months_page.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: years_page.dart
/// DESCRIZIONE: Schermata di reportistica annuale.
/// Visualizza:
/// 1. Un selettore per cambiare l'anno di riferimento.
/// 2. Un grafico a barre con l'andamento mensile.
/// 3. Una lista dettagliata dei mesi, navigabile verso il dettaglio mensile.

class YearsPage extends StatefulWidget {
  static const route = "/years";

  const YearsPage({super.key});

  @override
  State<YearsPage> createState() => _YearsPageState();
}

class _YearsPageState extends State<YearsPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  
  // --- STATO LOCALE ---
  // Anno attualmente selezionato per il filtro.
  String? selectedYear;

  final monthListKey = GlobalKey();

  final List<String> monthNames = [
    "Gennaio",
    "Febbraio",
    "Marzo",
    "Aprile",
    "Maggio",
    "Giugno",
    "Luglio",
    "Agosto",
    "Settembre",
    "Ottobre",
    "Novembre",
    "Dicembre",
  ];

  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();
    initFadeAnimation();
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Resoconto Annuale",
        isDark: isDark,
        icon: Icons.bar_chart_rounded,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        child: SafeArea(
          // --- RECUPERO DATI (CONSUMER) ---
          // Ascolta ExpenseProvider per ottenere i dati aggregati.
          // Filtra le spese per anno e calcola i totali dinamici.
          // 
          child: Consumer<ExpenseProvider>(
            builder: (context, expenseProvider, child) {
              // Recupera mappa grezza { "YYYY-MM": totale }
              final Map<String, double> monthlyExpenses = expenseProvider.expensesByMonth;

              // Estrae anni unici disponibili e li ordina
              final years =
                  monthlyExpenses.keys
                      .map((key) => key.split('-')[0])
                      .toSet()
                      .toList()
                    ..sort();

              // Stato Vuoto: Nessuna spesa registrata
              if (years.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 80.sp,
                        color: isDark
                            ? AppColors.greyDark
                            : AppColors.greyLight,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "Nessuna spesa disponibile",
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: isDark
                              ? AppColors.greyDark
                              : AppColors.greyLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Inizializzazione anno corrente (ultimo disponibile di default)
              selectedYear ??= years.last;

              // Generazione dati per il grafico (lista di 12 double)
              final List<double> values = List.generate(12, (i) {
                final monthKey =
                    "$selectedYear-${(i + 1).toString().padLeft(2, '0')}";
                return monthlyExpenses[monthKey] ?? 0.0;
              });

              final double totalYear = values.reduce((a, b) => a + b);

              return buildWithFadeAnimation(
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),

                      // --- SELETTORE ANNO ---
                      // Apre un dialog per scegliere l'anno tra quelli disponibili.
                      // 
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: InkWell(
                          onTap: () async {
                            final year =
                                await DialogUtils.showYearPickerAdaptive(
                                  context,
                                  years: years,
                                  selectedYear: selectedYear!,
                                );

                            if (year != null && year != selectedYear) {
                              setState(() => selectedYear = year);
                            }
                          },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.secondaryDark
                                  : AppColors.secondaryLight,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: isDark
                                      ? AppColors.textDark
                                      : AppColors.primary,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  selectedYear!,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textDark
                                        : AppColors.primary,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: isDark
                                      ? AppColors.textDark
                                      : AppColors.primary,
                                  size: 26.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // --- RIEPILOGO E GRAFICO ---
                      // Card con totale annuo e grafico a barre mensile.
                      //
                      TotalCardWidget(
                        label: "Totale $selectedYear",
                        totalAmount: totalYear,
                        icon: Icons.bar_chart_rounded,
                      ),

                      BarChartWidget(values: values, monthNames: monthNames),

                      SizedBox(height: 12.h),

                      // Header Sezione Lista
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Dettaglio mensile",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.greyDark
                                  : AppColors.greyLight,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // --- LISTA MESI ---
                      // Genera 12 tile, una per mese. Cliccando si naviga al dettaglio (MonthsPage).
                      // 
                      Column(
                        key: monthListKey,
                        children: List.generate(12, (index) {
                          final monthNum = index + 1;
                          final total = values[index];

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: 6.h,
                              left: 20.w,
                              right: 20.w,
                            ),
                            child: PeriodListItemWidget(
                              badgeText: "$monthNum",
                              title: monthNames[index],
                              totalAmount: total,
                              percentage: totalYear > 0
                                  ? (total / totalYear) * 100
                                  : 0,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MonthsPage(
                                      year: int.parse(selectedYear!),
                                      month: monthNum,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}