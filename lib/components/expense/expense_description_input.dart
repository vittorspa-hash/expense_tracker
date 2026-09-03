import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: expense_description_input.dart
/// DESCRIZIONE: Campo di testo per la descrizione opzionale della spesa.
/// Estratto da ExpenseEdit per coerenza con gli altri input del form.

class ExpenseDescriptionInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isTappedDown;

  const ExpenseDescriptionInput({
    super.key,
    required this.controller,
    required this.isTappedDown,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isTappedDown ? AppColors.textLight : AppColors.textTappedDown;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: TextField(
        keyboardType: TextInputType.text,
        maxLines: null,
        controller: controller,
        cursorColor: textColor,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          fontSize: 20.sp,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.descriptionHint,
          border: InputBorder.none,
          hintStyle: TextStyle(color: AppColors.secondaryDark, fontSize: 18.sp),
        ),
      ),
    );
  }
}