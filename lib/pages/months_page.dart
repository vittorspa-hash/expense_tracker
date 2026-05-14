import 'package:expense_tracker/components/report/report_empty_state.dart';
import 'package:expense_tracker/components/report/report_period_list_item.dart';
import 'package:expense_tracker/components/report/report_section_header.dart';
import 'package:expense_tracker/components/report/report_total_card.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/pages/days_page.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:expense_tracker/utils/report_date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: months_page.dart
/// DESCRIZIONE: Schermata di dettaglio mensile.
/// Visualizza il totale delle spese per il mese selezionato e una lista
/// aggregata per giorni. Cliccando su un giorno si naviga al dettaglio giornaliero.

// ... (import identici)

class MonthsPage extends ConsumerStatefulWidget {
  static const route = "/months";

  final int year;
  final int month;

  const MonthsPage({super.key, required this.year, required this.month});

  @override
  ConsumerState<MonthsPage> createState() => _MonthsPageState();
}

class _MonthsPageState extends ConsumerState<MonthsPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
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
    final monthName = ReportDateUtils.getMonthNames(context)[widget.month - 1];
    final loc = AppLocalizations.of(context)!;

    // --- RIVERPOD: Accesso ai dati ---
    // watch(expenseProvider) assicura che se una spesa viene modificata/aggiunta,
    // la lista si aggiorni automaticamente.

    final dailyExpenses = ref.watch(expensesByDayProvider)(widget.year, widget.month);

    return Scaffold(
      appBar: CustomAppBar(
        title: "$monthName ${widget.year}",
        isDark: isDark,
        icon: Icons.calendar_month_rounded,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        child: SafeArea(
          child: _buildBody(context, dailyExpenses, monthName, loc),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Map<String, double> dailyExpenses,
    String monthName,
    AppLocalizations loc,
  ) {
    // --- STATO VUOTO ---
    if (dailyExpenses.isEmpty) {
      return buildWithFadeAnimation(
        ReportEmptyState(
          title: loc.noExpensesMonthTitle,
          subtitle: loc.noExpensesSubtitle,
          icon: Icons.event_busy_rounded,
          useCircleBackground: true,
        ),
      );
    }

    final totalMonth = dailyExpenses.values.fold(0.0, (a, b) => a + b);

    // --- CONTENUTO LISTA ---
    return buildWithFadeAnimation(
      Column(
        children: [
          // Riepilogo Mese
          ReportTotalCard(
            label: loc.totalMonthLabel(monthName),
            totalAmount: totalMonth,
            icon: Icons.calendar_month_rounded,
            itemCount: dailyExpenses.length,
            itemLabel: loc.dayCountLabel(dailyExpenses.length),
          ),

          ReportSectionHeader(title: loc.dailyExpenses),

          SizedBox(height: 12.h),

          // Lista Giorni
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              itemCount: dailyExpenses.length,
              separatorBuilder: (_, _) => SizedBox(height: 6.h),
              itemBuilder: (context, index) {
                final dayKey = dailyExpenses.keys.elementAt(index);
                final total = dailyExpenses[dayKey]!;
                
                // Parsing sicuro della chiave data (es. "dd/MM/yyyy")
                final dateParts = dayKey.split('/');
                final date = DateTime(
                  int.parse(dateParts[2]),
                  int.parse(dateParts[1]),
                  int.parse(dateParts[0]),
                );

                return ReportPeriodListItem(
                  badgeText: "${date.day}",
                  badgeSubtext: DateFormat(
                    "MMM",
                    Localizations.localeOf(context).toString(),
                  ).format(date).toUpperCase(),
                  title: ReportDateUtils.getDayOfWeek(context, date),
                  subtitle: ReportDateUtils.formatDate(context, date),
                  totalAmount: total,
                  percentage: totalMonth > 0 ? (total / totalMonth) * 100 : 0,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      DaysPage.route,
                      arguments: {
                        'year': date.year,
                        'month': date.month,
                        'day': date.day
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}