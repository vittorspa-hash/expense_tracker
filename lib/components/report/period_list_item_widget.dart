// period_list_item_widget.dart
// -----------------------------------------------------------------------------
// 📄 WIDGET PER ITEM DEL DETTAGLIO PERIODICO (PeriodListItemWidget)
// -----------------------------------------------------------------------------
// Rappresenta un singolo elemento di un periodo (giorno/mese/anno) con:
// - Badge numerico e opzionale sottotitolo
// - Titolo principale e sottotitolo opzionale
// - Totale importo e percentuale sul totale
// - Clickable con effetto InkWell
// - Adattamento chiaro/scuro
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PeriodListItemWidget extends StatelessWidget {
  final String badgeText; // 🔹 Testo principale del badge (es. giorno o numero mese)
  final String? badgeSubtext; // 🔹 Sottotesto opzionale del badge (es. abbreviazione mese)
  final String title; // 🔹 Titolo principale (es. nome giorno/mese)
  final String? subtitle; // 🔹 Sottotitolo opzionale (es. data completa)
  final double totalAmount; // 🔹 Totale spesa del periodo
  final double percentage; // 🔹 Percentuale rispetto al totale
  final VoidCallback onTap; // 🔹 Azione al click
  final Color? badgeBackgroundColor; // 🔹 Colore personalizzato del badge

  const PeriodListItemWidget({
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
            // -----------------------------------------------------------------
            // 🔹 BADGE CON TESTO E SOTTOTESTO
            // -----------------------------------------------------------------
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

            // -----------------------------------------------------------------
            // 🔹 COLONNA CON TITOLI
            // -----------------------------------------------------------------
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

            // -----------------------------------------------------------------
            // 🔹 COLONNA CON TOTALE E PERCENTUALE
            // -----------------------------------------------------------------
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  width: 70.w,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      "€ ${totalAmount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
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

            // -----------------------------------------------------------------
            // 🔹 ICONA FRECCIA PER INDICARE CLICK
            // -----------------------------------------------------------------
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
