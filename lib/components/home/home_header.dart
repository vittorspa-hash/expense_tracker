// home_header.dart
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/profile_provider.dart'; // 👈 Importa il ProfileProvider
import 'package:expense_tracker/pages/years_page.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomeHeader extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final bool isDark;
  final VoidCallback onTapProfile;

  // ✂️ RIMOSSI: localAvatar e user. Ora li prendiamo dal provider.
  const HomeHeader({
    super.key,
    required this.fadeAnimation,
    required this.isDark,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    // 🎧 Usiamo Consumer2 per ascoltare SIA le spese CHE il profilo
    return Consumer2<ExpenseProvider, ProfileProvider>(
      builder: (context, expenseProvider, profileProvider, child) {
        // Recuperiamo i dati dal ProfileProvider
        final user = profileProvider.user;
        final localAvatar = profileProvider.localImage;

        return FadeTransition(
          opacity: fadeAnimation,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -----------------------------------------------------------------
                    // 🔷 RIGA SUPERIORE
                    // -----------------------------------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 📅 Pulsante "Resoconto annuale"
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, YearsPage.route),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColors.backgroundLight.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14.sp,
                                  color: isDark
                                      ? AppColors.textDark
                                      : AppColors.textLight,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "RESOCONTO ANNUALE",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: isDark
                                        ? AppColors.textDark
                                        : AppColors.textLight,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 👤 Avatar utente (Aggiornato automaticamente dal Provider)
                        GestureDetector(
                          onTap: onTapProfile,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.backgroundLight.withValues(
                                  alpha: 0.4,
                                ),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              key: ObjectKey(localAvatar),
                              radius: 20.r,
                              backgroundColor: AppColors.backgroundLight
                                  .withValues(alpha: 0.3),
                              // Logica immagine: Locale > Rete > Null
                              backgroundImage: localAvatar != null
                                  ? FileImage(localAvatar)
                                  : (user?.photoURL != null
                                        ? NetworkImage(user!.photoURL!)
                                        : null),

                              // Icona fallback
                              child:
                                  localAvatar == null && user?.photoURL == null
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 32.sp,
                                      color: isDark
                                          ? AppColors.textDark
                                          : AppColors.textLight,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // -----------------------------------------------------------------
                    // 💰 SEZIONE SPESA DEL MESE
                    // -----------------------------------------------------------------
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "QUESTO MESE",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark
                                ? AppColors.textDark.withValues(alpha: 0.9)
                                : AppColors.textLight.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            "€ ${expenseProvider.totalExpenseMonth.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 35.sp,
                              color: isDark
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // -----------------------------------------------------------------
                    // 📊 STATISTICHE
                    // -----------------------------------------------------------------
                    Row(
                      children: [
                        Expanded(
                          child: HeaderExpenseState(
                            value: expenseProvider.totalExpenseToday,
                            label: "Oggi",
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: HeaderExpenseState(
                            value: expenseProvider.totalExpenseWeek,
                            label: "Settimana",
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: HeaderExpenseState(
                            value: expenseProvider.totalExpenseYear,
                            label: "Anno",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ... HeaderExpenseState rimane invariato ...
class HeaderExpenseState extends StatelessWidget {
  final double value;
  final String label;

  const HeaderExpenseState({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.cardLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppColors.cardLight.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Text(
              "€ ${value.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? AppColors.textDark : AppColors.textLight,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9.sp,
                color: isDark
                    ? AppColors.textDark.withValues(alpha: 0.9)
                    : AppColors.textLight.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
