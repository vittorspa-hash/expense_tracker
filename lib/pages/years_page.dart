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

// ... (import identici) ...

class YearsPage extends ConsumerStatefulWidget {
  static const route = "/years";
  const YearsPage({super.key});

  @override
  ConsumerState<YearsPage> createState() => _YearsPageState();
}

class _YearsPageState extends ConsumerState<YearsPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  
  String? selectedYear;
  final monthListKey = GlobalKey();

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
    final loc = AppLocalizations.of(context)!;

    final monthlyExpenses = ref.watch(expensesByMonthProvider);

    // --- LOGICA DI FILTRAGGIO ---
    final years = monthlyExpenses.keys
        .map((key) => key.split('-')[0])
        .toSet()
        .toList()
      ..sort();

    // Se i dati cambiano e l'anno selezionato sparisce, resettiamo
    if (selectedYear != null && !years.contains(selectedYear)) {
      selectedYear = null;
    }

    // Stato Vuoto
    if (years.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: loc.yearsPageTitle, isDark: isDark, icon: Icons.bar_chart_rounded),
        body: ReportEmptyState(
          title: loc.noExpensesTitle,
          subtitle: loc.noExpensesSubtitle,
          icon: Icons.analytics_outlined,
          useCircleBackground: false,
        ),
      );
    }

    // Default all'ultimo anno disponibile
    selectedYear ??= years.last;

    // Dati per il grafico a barre
    final List<double> values = List.generate(12, (i) {
      final monthKey = "$selectedYear-${(i + 1).toString().padLeft(2, '0')}";
      return monthlyExpenses[monthKey] ?? 0.0;
    });

    final double totalYear = values.fold(0, (a, b) => a + b);

    // Recupera aggregazione per categoria (Metodo del notifier o dello stato)
    // Nota: Assicurati che expensesByCategoryForYear sia accessibile. 
    // Se è un metodo del Notifier, usa ref.read(expenseProvider.notifier).
    final categoryData = ref.watch(expensesByCategoryForYearProvider)(selectedYear!);

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
                          selectedYear: selectedYear!,
                        );

                        if (year != null && year != selectedYear) {
                          setState(() => selectedYear = year);
                        }
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      child: _buildYearBadge(isDark, selectedYear!),
                    ),
                  ),

                  // --- TOTALE ANNUO ---
                  ReportTotalCard(
                    label: loc.totalYearLabel(selectedYear!),
                    totalAmount: totalYear,
                    icon: Icons.bar_chart_rounded,
                  ),

                  // --- CAROUSEL GRAFICI ---
                  ReportChartsCarousel(
                    barValues: values,
                    monthNames: ReportDateUtils.getMonthNames(context),
                    categoryData: categoryData,
                  ),

                  SizedBox(height: 12.h),
                  ReportSectionHeader(title: loc.monthlyDetail),
                  SizedBox(height: 12.h),

                  // --- LISTA MESI ---
                  Column(
                    key: monthListKey,
                    children: List.generate(12, (index) {
                      final monthNum = index + 1;
                      final total = values[index];
                      final currentMonthName = ReportDateUtils.getMonthNames(context)[index];

                      return Padding(
                        padding: EdgeInsets.only(bottom: 6.h, left: 20.w, right: 20.w),
                        child: ReportPeriodListItem(
                          badgeText: "$monthNum",
                          title: currentMonthName,
                          totalAmount: total,
                          percentage: totalYear > 0 ? (total / totalYear) * 100 : 0,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              MonthsPage.route,
                              arguments: {
                                'year': int.parse(selectedYear!),
                                'month': monthNum,
                              },
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Piccolo refactor per pulizia: estrazione del widget badge
  Widget _buildYearBadge(bool isDark, String year) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
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
          Icon(Icons.calendar_today_rounded, 
               color: isDark ? AppColors.textDark : AppColors.primary, 
               size: 16.sp),
          SizedBox(width: 12.w),
          Text(
            year,
            style: TextStyle(
              color: isDark ? AppColors.textDark : AppColors.primary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: 8.w),
          Icon(Icons.arrow_drop_down_rounded, 
               color: isDark ? AppColors.textDark : AppColors.primary, 
               size: 26.sp),
        ],
      ),
    );
  }
}