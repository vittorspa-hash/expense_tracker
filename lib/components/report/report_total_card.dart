import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: report_card_widget.dart
/// DESCRIZIONE: Componente UI per la visualizzazione di riepilogo (Card Totale).
/// Mostra un importo aggregato con un'icona descrittiva e un contatore opzionale (es. numero di transazioni).
/// Utilizzato nelle pagine di report (Mensile/Annuale).

class ReportTotalCard extends StatelessWidget {
  // --- PARAMETRI ---
  // Configurazione del contenuto: etichetta, importo, icona
  // e dati opzionali per il contatore laterale.
  final String label; 
  final double totalAmount; 
  final IconData icon; 
  final int? itemCount; 
  final String? itemLabel; 

  const ReportTotalCard({
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

    // --- LAYOUT PRINCIPALE ---
    // Container con ombra ed effetto elevazione.
    // Organizza il contenuto in una riga orizzontale: Icona - Dati - Contatore.
    // 
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
          // --- ICONA ---
          // Box quadrato con angoli arrotondati e colore secondario.
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

          // --- DETTAGLI ---
          // Colonna centrale espandibile per Etichetta e Valore Monetario.
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

          // --- CONTATORE OPZIONALE ---
          // Widget condizionale a destra per mostrare statistiche numeriche extra.
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