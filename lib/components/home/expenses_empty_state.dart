import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: expenses_empty_state.dart
/// DESCRIZIONE: Stato vuoto della lista spese, con varianti contestuali per
/// "nessuna spesa registrata" e "nessun risultato per la ricerca corrente".

class ExpensesEmptyState extends StatelessWidget {
  final bool isDark;
  final bool isSearching;

  const ExpensesEmptyState({
    super.key,
    required this.isDark,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final mutedColor = isDark ? AppColors.greyDark : AppColors.greyLight;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            Icon(
              isSearching ? Icons.search_off_rounded : Icons.receipt_long_outlined,
              size: 56.sp,
              color: mutedColor,
            ),
            SizedBox(height: 16.h),
            Text(
              isSearching ? loc.emptySearchTitle : loc.emptyExpensesTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: mutedColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              isSearching ? loc.emptySearchSubtitle : loc.emptyExpensesSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: mutedColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}