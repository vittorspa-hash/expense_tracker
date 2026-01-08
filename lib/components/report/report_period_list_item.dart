import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/currency_provider.dart';

/// FILE: report_period_list_item.dart
/// DESCRIZIONE: Componente UI riutilizzabile per le liste dei report.
/// Visualizza una riga contenente un badge (es. Mese/Giorno), titolo, sottotitolo,
/// importo totale formattato secondo la valuta corrente e percentuale di incidenza.

class ReportPeriodListItem extends StatelessWidget {
  // --- PARAMETRI ---
  // Dati da visualizzare nel badge, testi descrittivi, valori finanziari
  // e callback per la navigazione al dettaglio.
  final String badgeText; 
  final String? badgeSubtext; 
  final String title; 
  final String? subtitle; 
  final double totalAmount; 
  final double percentage; 
  final VoidCallback onTap; 
  final Color? badgeBackgroundColor; 

  const ReportPeriodListItem({
    super.key,
    required this.badgeText,
    this.badgeSubtext,
    required this.title,
    this.subtitle,
    required this.totalAmount,
    required this.percentage,
    required this.onTap,
    this.badgeBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- CARD INTERATTIVA ---
    // InkWell fornisce l'effetto ripple al tocco.
    // Il contenitore gestisce bordi, ombre e sfondo in base al tema.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // --- BADGE (SINISTRA) ---
            // Visualizza l'indicatore principale (es. giorno o mese abbreviato).
            Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color:
                    badgeBackgroundColor ??
                    (isDark
                        ? AppColors.secondaryDark
                        : AppColors.secondaryLight),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textDark : AppColors.primary,
                      height: badgeSubtext != null ? 1.2 : null,
                    ),
                  ),
                  if (badgeSubtext != null)
                    Text(
                      badgeSubtext!,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDark : AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(width: 16.w),

            // --- INFO TESTUALI (CENTRO) ---
            // Titolo del periodo e sottotitolo opzionale (es. range date).
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textLight : AppColors.textDark2,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark
                            ? AppColors.greyDark
                            : AppColors.greyLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // --- DATI FINANZIARI (DESTRA) ---
            // Mostra l'importo formattato tramite CurrencyProvider e la percentuale.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  width: 70.w,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Consumer<CurrencyProvider>(
                      builder: (context, currencyProvider, child) {
                        return Text(
                          currencyProvider.formatAmount(totalAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                            color: AppColors.primary,
                            letterSpacing: -0.3,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (totalAmount > 0) ...[
                  SizedBox(height: 4.h),
                  Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? AppColors.greyDark : AppColors.greyLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),

            SizedBox(width: 8.w),

            // --- INDICATORE NAVIGAZIONE ---
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.greyDark : AppColors.greyLight,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}