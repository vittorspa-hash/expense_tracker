import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/profile_provider.dart';
import 'package:expense_tracker/providers/currency_provider.dart';
import 'package:expense_tracker/pages/years_page.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// FILE: home_header.dart
/// DESCRIZIONE: Componente superiore della Home Page (Dashboard).
/// Visualizza i totali delle spese (Oggi, Settimana, Mese, Anno) e l'avatar utente.
/// Utilizza un [Consumer3] per aggiornarsi reattivamente ai cambiamenti
/// delle spese (ExpenseProvider), del profilo utente (ProfileProvider) e della valuta (CurrencyProvider).

class HomeHeader extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final bool isDark;
  final VoidCallback onTapProfile;

  const HomeHeader({
    super.key,
    required this.fadeAnimation,
    required this.isDark,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    // --- GESTIONE DATI MULTIPLA (CONSUMER) ---
    // Ascolta simultaneamente ExpenseProvider (per i totali), ProfileProvider (per l'avatar)
    // e CurrencyProvider (per la formattazione degli importi).
    // Questo evita rebuild inutili dell'intera pagina se cambiano solo questi dati.
    // 
    return Consumer3<ExpenseProvider, ProfileProvider, CurrencyProvider>(
      builder: (context, expenseProvider, profileProvider, currencyProvider, child) {
        // Recupero dati profilo per visualizzazione avatar
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
                    // --- BARRA NAVIGAZIONE SUPERIORE ---
                    // Include il pulsante per il resoconto annuale e l'avatar cliccabile.
                    // 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Pulsante Navigazione Anni
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

                        // Avatar Utente con Fallback Logic
                        // Priorità: Immagine Locale > URL Network (Firebase) > Icona Default
                        // 
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
                              backgroundImage: localAvatar != null
                                  ? FileImage(localAvatar)
                                  : (user?.photoURL != null
                                        ? NetworkImage(user!.photoURL!)
                                        : null),

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

                    // --- INDICATORE TOTALE MENSILE ---
                    // Focus principale della dashboard con formattazione dinamica della valuta.
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
                            currencyProvider.formatAmount(
                              expenseProvider.totalExpenseMonth,
                            ),
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

                    // --- CARDS STATISTICHE RAPIDE ---
                    // Griglia orizzontale per i totali di Oggi, Settimana e Anno.
                    Row(
                      children: [
                        Expanded(
                          child: HeaderExpenseState(
                            value: expenseProvider.totalExpenseToday,
                            label: "Oggi",
                            currencyProvider: currencyProvider,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: HeaderExpenseState(
                            value: expenseProvider.totalExpenseWeek,
                            label: "Settimana",
                            currencyProvider: currencyProvider,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: HeaderExpenseState(
                            value: expenseProvider.totalExpenseYear,
                            label: "Anno",
                            currencyProvider: currencyProvider,
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

// --- WIDGET HELPER STATISTICHE ---
// Card riutilizzabile per visualizzare una singola statistica (Valore + Etichetta).
// Ora include il CurrencyProvider per formattare correttamente gli importi.
class HeaderExpenseState extends StatelessWidget {
  final double value;
  final String label;
  final CurrencyProvider currencyProvider;

  const HeaderExpenseState({
    super.key,
    required this.value,
    required this.label,
    required this.currencyProvider,
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
              currencyProvider.formatAmount(value),
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