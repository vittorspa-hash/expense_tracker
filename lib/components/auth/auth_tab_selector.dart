import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// FILE: auth_tab_selector.dart
/// DESCRIZIONE: Switch grafico Login/Registrazione con indicatore animato.
/// Widget "dumb": riceve `isLoading` dal parent invece di leggere il
/// provider da solo, per non duplicare il watch già presente in AuthPage
/// (serve anche lì per la TabBarView).

class AuthTabSelector extends StatelessWidget {
  final TabController controller;
  final bool isLoading;

  const AuthTabSelector({
    super.key,
    required this.controller,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isLoading ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: isLoading,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TabBar(
            controller: controller,
            // Personalizza l'effetto al tocco (splash/highlight)
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return AppColors.primary.withValues(alpha: 0.12);
              }
              return null;
            }),
            splashBorderRadius: BorderRadius.circular(12.r),
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.textLight,
            unselectedLabelColor: isDark
                ? AppColors.greyDark
                : AppColors.greyLight,
            labelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.rightToBracket, size: 15.sp),
                    SizedBox(width: 8.w),
                    Text(loc.loginTab),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.userPlus, size: 15.sp),
                    SizedBox(width: 8.w),
                    Text(loc.registerTab),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
