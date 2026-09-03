import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// FILE: expense_date_selector.dart
/// DESCRIZIONE: Riga cliccabile che mostra la data selezionata (icona +
/// testo formattato) e apre il date picker al tap. Estratto da ExpenseEdit.

class ExpenseDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final bool isTappedDown;
  final VoidCallback onTap;

  const ExpenseDateSelector({
    super.key,
    required this.selectedDate,
    required this.isTappedDown,
    required this.onTap,
  });

  /// Capitalizza forzatamente la prima lettera del mese (es. da "19 maggio
  /// 2026" a "19 Maggio 2026") per uniformità con il resto dell'app.
  String _capitalizeMonth(String date) {
    final parts = date.split(' ');
    if (parts.length < 3) return date;
    final day = parts[0];
    final month = parts[1][0].toUpperCase() + parts[1].substring(1);
    final year = parts[2];
    return "$day $month $year";
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formattedDate = DateFormat("d MMMM y", locale).format(selectedDate);
    final displayDate = _capitalizeMonth(formattedDate);
    final textColor = isTappedDown ? AppColors.textLight : AppColors.textTappedDown;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, color: textColor, size: 24.sp),
          SizedBox(width: 10.w),
          Text(
            displayDate,
            style: TextStyle(
              fontSize: 18.sp,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}