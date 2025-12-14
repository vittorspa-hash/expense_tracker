// months_page.dart
// -----------------------------------------------------------------------------
// 📅 PAGINA RESOCONTO MENSILE (MONTHS PAGE)
// -----------------------------------------------------------------------------
// Mostra le spese giornaliere di un mese selezionato con:
// - Card del totale mensile
// - Lista dei giorni con badge e percentuale rispetto al totale mese
// - Navigazione verso dettagli giornalieri (DaysPage)
// -----------------------------------------------------------------------------

import 'package:expense_tracker/components/report/period_list_item_widget.dart';
import 'package:expense_tracker/components/report/total_card_widget.dart';
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/pages/days_page.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expense_tracker/stores/expense_store.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MonthsPage extends StatefulWidget {
  static const route = "/months";

  final int year; // 🔧 Anno selezionato
  final int month; // 🔧 Mese selezionato

  const MonthsPage({super.key, required this.year, required this.month});

  @override
  State<MonthsPage> createState() => _MonthsPageState();
}

class _MonthsPageState extends State<MonthsPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  final List<String> monthNames = [
    // 📅 Nomi dei mesi
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
  // Getter per il vsync richiesto dal mixin
  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();
    // 🔄 Animazione fade in iniziale
    initFadeAnimation();
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 📌 FUNZIONI DI FORMATTARE DATA
  // ---------------------------------------------------------------------------
  String formatDateItaliano(DateTime date) {
    final giorno = DateFormat("d", "it_IT").format(date);
    final mese = DateFormat("MMMM", "it_IT").format(date);
    final anno = DateFormat("y", "it_IT").format(date);
    final meseCapitalizzato = mese[0].toUpperCase() + mese.substring(1);
    return "$giorno $meseCapitalizzato $anno";
  }

  String getDayOfWeek(DateTime date) {
    final giornoSettimana = DateFormat("EEEE", "it_IT").format(date);
    return giornoSettimana[0].toUpperCase() + giornoSettimana.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthName = monthNames[widget.month - 1];

    return Scaffold(
      appBar: CustomAppBar(
        title: "$monthName ${widget.year}",
        isDark: isDark,
        icon: Icons.calendar_month_rounded,
      ),

      // -------------------------------------------------------------------------
      // 🗂 BODY PRINCIPALE
      // -------------------------------------------------------------------------
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        child: SafeArea(
          child: Obx(() {
            // 🔹 Recupera spese giornaliere per mese selezionato
            final dailyExpenses = expenseStore.value.expensesByDay(
              widget.year,
              widget.month,
            );

            // ---------------------------------------------------------------------
            // ⚠️ Nessuna spesa per il mese
            // ---------------------------------------------------------------------
            if (dailyExpenses.isEmpty) {
              return buildWithFadeAnimation(
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.secondaryDark
                              : AppColors.secondaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_busy_rounded,
                          size: 64.sp,
                          color: isDark
                              ? AppColors.greyLight
                              : AppColors.greyDark,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        "Nessuna spesa in questo mese",
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textDark2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Le spese che aggiungi appariranno qui",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark
                              ? AppColors.greyDark
                              : AppColors.greyLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 🔹 Totale spese mese
            final totalMonth = dailyExpenses.values.reduce((a, b) => a + b);

            return buildWithFadeAnimation(
              Column(
                children: [
                  // -----------------------------------------------------------------
                  // 💰 TOTAL CARD WIDGET MENSILE
                  // -----------------------------------------------------------------
                  TotalCardWidget(
                    label: "Totale $monthName",
                    totalAmount: totalMonth,
                    icon: Icons.calendar_month_rounded,
                    itemCount: dailyExpenses.length,
                    itemLabel: dailyExpenses.length == 1 ? "giorno" : "giorni",
                  ),

                  // -----------------------------------------------------------------
                  // 📝 TITOLO SPESA GIORNALIERA
                  // -----------------------------------------------------------------
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Spese giornaliere",
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

                  // -----------------------------------------------------------------
                  // 📋 LISTA DETTAGLIO GIORNALIERO
                  // -----------------------------------------------------------------
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                      itemCount: dailyExpenses.length,
                      separatorBuilder: (_, _) => SizedBox(height: 6.h),
                      itemBuilder: (context, index) {
                        final day = dailyExpenses.keys.elementAt(index);
                        final total = dailyExpenses[day]!;
                        final date = DateTime.parse(
                          day.split('/').reversed.join('-'),
                        );

                        return PeriodListItemWidget(
                          badgeText: "${date.day}",
                          badgeSubtext: DateFormat(
                            "MMM",
                            "it_IT",
                          ).format(date).toUpperCase(),
                          title: getDayOfWeek(date),
                          subtitle: formatDateItaliano(date),
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
          }),
        ),
      ),
    );
  }
}
