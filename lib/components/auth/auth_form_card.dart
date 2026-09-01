import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: auth_form_card.dart
/// DESCRIZIONE: Card condivisa tra LoginForm e RegisterForm: contenitore con
/// titolo, sottotitolo e i campi del form passati come children. Elimina la
/// duplicazione della decorazione presente prima in entrambi i form.

class AuthFormCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const AuthFormCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textLight : AppColors.textDark2,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? AppColors.greyDark : AppColors.greyLight,
            ),
          ),
          SizedBox(height: 18.h),
          ...children,
        ],
      ),
    );
  }
}