// total_card_widget.dart
// -----------------------------------------------------------------------------
// 💰 WIDGET CARD TOTALE (TOTAL CARD WIDGET)
// -----------------------------------------------------------------------------
// Mostra il totale di un periodo (giorno/mese/anno) con:
// - Etichetta descrittiva
// - Icona rappresentativa
// - Importo totale formattato
// - Opzionale: conteggio elementi e label
// - Adattamento modalità chiaro/scuro
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TotalCardWidget extends StatelessWidget {
  final String label; // 🔹 Testo descrittivo del totale
  final double totalAmount; // 🔹 Valore numerico totale
  final IconData icon; // 🔹 Icona della card
  final int? itemCount; // 🔹 Conteggio opzionale di elementi
  final String? itemLabel; // 🔹 Etichetta opzionale per il conteggio

  const TotalCardWidget({
    super.key,
    required this.label,
    required this.totalAmount,
    required this.icon,
    this.itemCount,
    this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.all(16.w),
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
      child: Row(
        children: [
          // -------------------------------------------------------------------
          // 🔹 ICONA CARD
          // -------------------------------------------------------------------
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.secondaryDark
                  : AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.textDark : AppColors.primary,
              size: 30.sp,
            ),
          ),

          SizedBox(width: 16.w),

          // -------------------------------------------------------------------
          // 🔹 ETICHETTA E IMPORTO TOTALE
          // -------------------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.greyDark : AppColors.greyLight,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    "€ ${totalAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 16.w),

          // -------------------------------------------------------------------
          // 🔹 CONTEGGIO OPZIONALE ELEMENTI
          // -------------------------------------------------------------------
          if (itemCount != null && itemLabel != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.secondaryDark
                    : AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Text(
                    "$itemCount",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textDark : AppColors.primary,
                    ),
                  ),
                  Text(
                    itemLabel!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
