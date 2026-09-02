import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/pages/new_expense_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: new_expense_fab.dart
/// DESCRIZIONE: Floating Action Button per l'inserimento di una nuova spesa.
/// Naviga a NewExpensePage e, al ritorno, invoca onReturn per pulire
/// eventuale stato di ricerca residuo nella HomePage.

class NewExpenseFab extends StatelessWidget {
  final bool isDark;
  final VoidCallback onReturn;

  const NewExpenseFab({super.key, required this.isDark, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: 70.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: FloatingActionButton.extended(
          heroTag: null,
          elevation: 0,
          backgroundColor: Colors.transparent,
          onPressed: () async {
            await Navigator.pushNamed(context, NewExpensePage.route);
            if (context.mounted) onReturn();
          },
          label: Text(
            loc.newExpense,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          icon: Icon(Icons.add_rounded, size: 20.sp),
          foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
        ),
      ),
    );
  }
}