import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/pages/years_page.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: home_header.dart
/// DESCRIZIONE: Componente superiore della Home Page (Dashboard).
/// Visualizza i totali delle spese (Oggi, Settimana, Mese, Anno) e l'avatar utente.
/// Monitora in modo reattivo i notifier delle spese, del profilo e della valuta
/// tramite i rispettivi provider Riverpod.

class HomeHeader extends ConsumerWidget {
  final Animation<double> fadeAnimation;
  final bool isDark;
  final VoidCallback onTapProfile;
  final VoidCallback onReturn;

  const HomeHeader({
    super.key,
    required this.fadeAnimation,
    required this.isDark,
    required this.onTapProfile,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- RECOVERY STATI (RIVERPOD) ---
    // Sottoscrizione ai provider per l'aggiornamento in tempo reale di spese, profilo e valuta.
    final expenseState = ref.watch(expenseNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final currencyState = ref.watch(currencyNotifierProvider);
    
    // Estrazione dati del profilo utente
    final user = profileState.user;
    final localAvatar = profileState.localImage;
    final loc = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32.r),
            bottomRight: Radius.circular(32.r),
          ),
          color: AppColors.primary,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BARRA NAVIGAZIONE SUPERIORE ---
                // Gestisce l'accesso al resoconto annuale e la visualizzazione del profilo.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // PULSANTE RESOCONTO ANNUALE
                    GestureDetector(
                      onTap: () async {
                        await Navigator.pushNamed(context, YearsPage.route);
                        onReturn();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.backgroundLight.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14.sp,
                              color: isDark ? AppColors.textDark : AppColors.textLight,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              loc.annualReport,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: isDark ? AppColors.textDark : AppColors.textLight,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // AVATAR UTENTE (Logica: Immagine Locale -> Network Image -> Fallback Icon)
                    GestureDetector(
                      onTap: onTapProfile,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.backgroundLight.withValues(alpha: 0.4),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          key: ObjectKey(localAvatar),
                          radius: 20.r,
                          backgroundColor: AppColors.backgroundLight.withValues(alpha: 0.3),
                          backgroundImage: localAvatar != null
                              ? FileImage(localAvatar)
                              : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
                          child: localAvatar == null && user?.photoURL == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 32.sp,
                                  color: isDark ? AppColors.textDark : AppColors.textLight,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // --- PANNELLO TOTALE MENSILE ---
                // Sezione principale focalizzata sul riepilogo delle spese correnti del mese corrente.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.thisMonth,
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
                        currencyState.formatAmount(expenseState.totalExpenseMonth),
                        style: TextStyle(
                          fontSize: 35.sp,
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // --- CARDS STATISTICHE RAPIDE ---
                // Griglia riassuntiva orizzontale per i totali di Oggi, Settimana e Anno.
                Row(
                  children: [
                    Expanded(
                      child: HeaderExpenseState(
                        value: expenseState.totalExpenseToday,
                        label: loc.today,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: HeaderExpenseState(
                        value: expenseState.totalExpenseWeek,
                        label: loc.week,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: HeaderExpenseState(
                        value: expenseState.totalExpenseYear,
                        label: loc.year,
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
  }
}

// --- WIDGET HELPER STATISTICHE ---
/// Card atomica e riutilizzabile incaricata di mostrare un singolo aggregato di spesa (Valore + Etichetta).
/// Sfrutta currencyNotifierProvider per formattare gli importi numerici in modo coerente.
class HeaderExpenseState extends ConsumerWidget {
  final double value;
  final String label;

  const HeaderExpenseState({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // SEZIONE VALORE FORMATTATO
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Text(
              ref.watch(currencyNotifierProvider).formatAmount(value),
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
          
          // SEZIONE ETICHETTA TEMPORALE
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