import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/notifiers/expense_notifier.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: home_header.dart
/// DESCRIZIONE: Componente superiore della Home Page (Dashboard).
/// Visualizza i totali delle spese (Oggi, Settimana, Mese, Anno), formattati
/// nella valuta corrente dell'app tramite currencyNotifierProvider.

class HomeHeader extends ConsumerWidget {
  final Animation<double> fadeAnimation;
  final bool isDark;
  final VoidCallback onReturn;

  const HomeHeader({
    super.key,
    required this.fadeAnimation,
    required this.isDark,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- ASCOLTO STATI (RIVERPOD) ---
    // select mirato: si ricostruisce solo quando cambiano i totali, non ad
    // ogni variazione di isLoading/errorMessage nello stato delle spese.
    final totals = ref.watch(
          expenseNotifierProvider.select((s) => s.value?.totals),
        ) ??
        ExpenseState().totals;
    final currencyState = ref.watch(currencyNotifierProvider);

    final loc = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32.r),
            bottomRight: Radius.circular(32.r),
          ),
          color: AppColors.primary,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),

                // --- PANNELLO TOTALE MENSILE ---
                // Sezione principale focalizzata sul riepilogo delle spese correnti del mese corrente.
                Text(
                  loc.thisMonth,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark
                        ? AppColors.textDark.withValues(alpha: 0.9)
                        : AppColors.textLight.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    currencyState.formatAmount(totals.month),
                    style: TextStyle(
                      fontSize: 35.sp,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // --- CARDS STATISTICHE RAPIDE ---
                // Griglia riassuntiva orizzontale per i totali di Oggi, Settimana e Anno.
                Row(
                  children: [
                    Expanded(
                      child: HeaderExpenseState(value: totals.today, label: loc.today),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: HeaderExpenseState(value: totals.week, label: loc.week),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: HeaderExpenseState(value: totals.year, label: loc.year),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- WIDGET HELPER STATISTICHE ---
/// Card atomica e riutilizzabile incaricata di mostrare un singolo aggregato di spesa (Valore + Etichetta).
/// Sfrutta currencyNotifierProvider per formattare gli importi numerici in modo coerente.
class HeaderExpenseState extends ConsumerWidget {
  final double value;
  final String label;

  const HeaderExpenseState({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.cardLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppColors.cardLight.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Text(
              ref.watch(currencyNotifierProvider).formatAmount(value),
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? AppColors.textDark : AppColors.textLight,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9.sp,
                color: isDark
                    ? AppColors.textDark.withValues(alpha: 0.9)
                    : AppColors.textLight.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}