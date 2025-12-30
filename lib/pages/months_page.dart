import 'package:expense_tracker/components/report/report_empty_state.dart';
import 'package:expense_tracker/components/report/report_period_list_item.dart';
import 'package:expense_tracker/components/report/report_section_header.dart';
import 'package:expense_tracker/components/report/report_total_card.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/pages/days_page.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:expense_tracker/utils/report_date_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: months_page.dart
/// DESCRIZIONE: Schermata di dettaglio mensile.
/// Visualizza il totale delle spese per il mese selezionato e una lista
/// aggregata per giorni. Cliccando su un giorno si naviga al dettaglio giornaliero.

class MonthsPage extends StatefulWidget {
  static const route = "/months";

  final int year;
  final int month;

  const MonthsPage({super.key, required this.year, required this.month});

  @override
  State<MonthsPage> createState() => _MonthsPageState();
}

class _MonthsPageState extends State<MonthsPage>
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
    final monthName = ReportDateUtils.monthNames[widget.month - 1];

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
          // --- RECUPERO DATI (CONSUMER) ---
          // Ascolta il Provider per ottenere le spese aggregate per giorno.
          // La logica di raggruppamento (Map<Giorno, Totale>) è delegata al Provider.
          // 
          child: Consumer<ExpenseProvider>(
            builder: (context, expenseProvider, child) {
              
              final dailyExpenses = expenseProvider.expensesByDay(
                widget.year,
                widget.month,
              );

              // --- STATO VUOTO ---
              // Visualizzazione alternativa se non ci sono dati per il periodo selezionato.
              // 
              if (dailyExpenses.isEmpty) {
                return buildWithFadeAnimation(
                  const ReportEmptyState(
                    title: "Nessuna spesa in questo mese",
                    subtitle: "Le spese che aggiungi appariranno qui",
                    icon: Icons.event_busy_rounded,
                    useCircleBackground: true, // Mantiene lo stile originale col cerchio
                  ),
                );
              }

              final totalMonth = dailyExpenses.values.reduce((a, b) => a + b);

              // --- CONTENUTO LISTA ---
              // Visualizza la Card Totale e la lista dei giorni.
              // 
              return buildWithFadeAnimation(
                Column(
                  children: [
                    // Riepilogo Mese
                    ReportTotalCard(
                      label: "Totale $monthName",
                      totalAmount: totalMonth,
                      icon: Icons.calendar_month_rounded,
                      itemCount: dailyExpenses.length,
                      itemLabel: dailyExpenses.length == 1
                          ? "giorno"
                          : "giorni",
                    ),

                    const ReportSectionHeader(title: "Spese giornaliere"),

                    SizedBox(height: 12.h),

                    // Lista Giorni
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                        itemCount: dailyExpenses.length,
                        separatorBuilder: (_, _) => SizedBox(height: 6.h),
                        itemBuilder: (context, index) {
                          // Parsing della chiave data (es. "dd/MM/yyyy")
                          final day = dailyExpenses.keys.elementAt(index);
                          final total = dailyExpenses[day]!;
                          final date = DateTime.parse(
                            day.split('/').reversed.join('-'),
                          );

                          // Navigazione al dettaglio giornaliero (DaysPage)
                          // 
                          return ReportPeriodListItem(
                            badgeText: "${date.day}",
                            badgeSubtext: DateFormat(
                              "MMM",
                              "it_IT",
                            ).format(date).toUpperCase(),
                            title: ReportDateUtils.getDayOfWeek(date),
                            subtitle: ReportDateUtils.formatDateItaliano(date),
                            totalAmount: total,
                            percentage: (total / totalMonth) * 100,
                            onTap: () {
                              final parts = day.split('/');
                              final d = int.parse(parts[0]);
                              final m = int.parse(parts[1]);
                              final y = int.parse(parts[2]);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DaysPage(year: y, month: m, day: d),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}