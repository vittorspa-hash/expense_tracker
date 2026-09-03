import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: expense_category_selector.dart
/// DESCRIZIONE: Griglia adattiva di chip per la selezione della categoria
/// merceologica della spesa. Il chip attivo si evidenzia col colore primario.
/// Estratto da ExpenseEdit.

class ExpenseCategorySelector extends StatelessWidget {
  final ExpenseCategory selectedCategory;
  final bool isTappedDown;
  final ValueChanged<ExpenseCategory> onCategorySelected;

  const ExpenseCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.isTappedDown,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final textColor = isTappedDown ? AppColors.textLight : AppColors.textTappedDown;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.w,
        runSpacing: 8.h,
        children: ExpenseCategory.values.map((category) {
          final isSelected = selectedCategory == category;
          final label = category.label(loc);

          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.07)),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16.sp,
                    color: isSelected ? AppColors.textLight : textColor,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.textLight : textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}