import 'package:expense_tracker/components/report/report_charts_carousel.dart';
import 'package:expense_tracker/components/report/report_empty_state.dart';
import 'package:expense_tracker/components/report/report_period_list_item.dart';
import 'package:expense_tracker/components/report/report_section_header.dart';
import 'package:expense_tracker/components/report/report_total_card.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/pages/months_page.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:expense_tracker/utils/report_date_utils.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: years_page.dart
/// DESCRIZIONE: Schermata dei report annuali delle spese.
/// Permette l'aggregazione dei dati su base annua, la navigazione interattiva
/// fra gli anni registrati tramite selettore adattivo e la visualizzazione di grafici
/// dedicati tramite un carosello di componenti analitici.

class YearsPage extends ConsumerStatefulWidget {
  static const route = "/years";
  const YearsPage({super.key});

  @override
  ConsumerState<YearsPage> createState() => _YearsPageState();
}

class _YearsPageState extends ConsumerState<YearsPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  String? _selectedYear;
  final _monthListKey = GlobalKey();

  // --- INIZIALIZZAZIONE ---
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

  // --- BUILD UI ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final monthlyExpenses = ref.watch(expensesByMonthProvider);

    // Estratta e ordinata cronologicamente la lista degli anni disponibili
    final years = monthlyExpenses.keys
        .map((key) => key.split('-')[0])
        .toSet()
        .toList()
      ..sort();

    // Reset dello stato se l'anno selezionato non è più presente a database
    if (_selectedYear != null && !years.contains(_selectedYear)) {
      _selectedYear = null;
    }

    // Gestione dello stato vuoto nel caso in cui non vi siano spese registrate
    if (years.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(
          title: loc.yearsPageTitle,
          isDark: isDark,
          icon: Icons.bar_chart_rounded,
        ),
        body: ReportEmptyState(
          title: loc.noExpensesTitle,
          subtitle: loc.noExpensesSubtitle,
          icon: Icons.analytics_outlined,
          useCircleBackground: false,
        ),
      );
    }

    // Default iniziale impostato sull'ultimo anno disponibile
    _selectedYear ??= years.last;
    final activeYear = _selectedYear!;

    // Generazione della distribuzione mensile dei costi (12 mesi)
    final List<double> monthlyValues = List.generate(12, (index) {
      final monthKey = "$activeYear-${(index + 1).toString().padLeft(2, '0')}";
      return monthlyExpenses[monthKey] ?? 0.0;
    });

    final double totalYearAmount = monthlyValues.fold(0.0, (sum, val) => sum + val);
    final categoryData = ref.watch(expensesByCategoryForYearProvider)(activeYear);
    final monthNames = ReportDateUtils.getMonthNames(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: loc.yearsPageTitle,
        isDark: isDark,
        icon: Icons.bar_chart_rounded,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        child: SafeArea(
          child: buildWithFadeAnimation(
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20.h),

                  // --- SELETTORE ANNO ---
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: InkWell(
                      onTap: () async {
                        final year = await DialogUtils.showYearPickerAdaptive(
                          context,
                          years: years,
                          selectedYear: activeYear,
                        );

                        if (year != null && year != activeYear) {
                          setState(() => _selectedYear = year);
                        }
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      child: _buildYearBadge(isDark, activeYear),
                    ),
                  ),

                  // --- TOTALE ANNUO ---
                  ReportTotalCard(
                    label: loc.totalYearLabel(activeYear),
                    totalAmount: totalYearAmount,
                    icon: Icons.bar_chart_rounded,
                  ),

                  // --- CAROUSEL GRAFICI ---
                  ReportChartsCarousel(
                    barValues: monthlyValues,
                    monthNames: monthNames,
                    categoryData: categoryData,
                  ),

                  SizedBox(height: 12.h),
                  ReportSectionHeader(title: loc.monthlyDetail),
                  SizedBox(height: 12.h),

                  // --- LISTA MESI ---
                  Column(
                    key: _monthListKey,
                    children: List.generate(12, (index) {
                      final monthNum = index + 1;
                      final totalMonthAmount = monthlyValues[index];
                      final currentMonthName = monthNames[index];

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 3.h),
                        child: ReportPeriodListItem(
                          badgeText: "$monthNum",
                          title: currentMonthName,
                          totalAmount: totalMonthAmount,
                          percentage: totalYearAmount > 0 ? (totalMonthAmount / totalYearAmount) * 100 : 0,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              MonthsPage.route,
                              arguments: {
                                'year': int.parse(activeYear),
                                'month': monthNum,
                              },
                            );
                          },
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- ELEMENTI GRAFICI SECONDARI ---
  /// Costruisce il badge interattivo per la selezione e visualizzazione dell'anno fiscale.
  Widget _buildYearBadge(bool isDark, String year) {
    final chipColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final contentColor = isDark ? AppColors.textDark : AppColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
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
            color: contentColor, 
            size: 16.sp,
          ),
          SizedBox(width: 12.w),
          Text(
            year,
            style: TextStyle(
              color: contentColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            Icons.arrow_drop_down_rounded, 
            color: contentColor, 
            size: 26.sp,
          ),
        ],
      ),
    );
  }
}