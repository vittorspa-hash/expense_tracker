import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: auth_header.dart
/// DESCRIZIONE: Header curvo della AuthPage con logo, titolo e sottotitolo.
/// Widget statico e senza dipendenze da Riverpod: usato come `const` nel
/// parent, non viene mai ricostruito quando cambia lo stato di loading.

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20.h,
        bottom: 30.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.avatar.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.avatar.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Image.asset(
              "assets/icons/money2_ardesia.png",
              width: 68.w,
              height: 68.w,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            loc.authAppTitle,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            loc.authAppSubtitle,
            style: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.9),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}