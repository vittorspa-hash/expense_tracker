// home_header.dart
// -----------------------------------------------------------------------------
// 🏠 HEADER DELLA HOME PAGE + STATISTICHE INLINE
//
// Questo file contiene:
// - HomeHeader: header animato con avatar, bottone resoconto annuale
//   e riepilogo delle spese del mese corrente.
// - HeaderExpenseState: widget compatto per mostrare un valore (oggi/settimana/anno)
//   con grafica moderna.
//
// Include animazioni fade, supporto dark mode, avatar locale, avatar remoto,
// e integrazione con StoreModel via Obx. 
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:expense_tracker/models/store_model.dart';
import 'package:expense_tracker/pages/years_page.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeHeader extends StatelessWidget {
  final Animation<double>
  fadeAnimation; // ✨ Animazione fade-in del blocco header
  final File? localAvatar; // 📁 Avatar salvata localmente
  final User? user; // 👤 Utente Firebase loggato
  final bool isDark; // 🌙 Theme mode attuale
  final VoidCallback onTapProfile; // 🔘 Apertura sheet profilo

  const HomeHeader({
    super.key,
    required this.fadeAnimation,
    required this.localAvatar,
    required this.user,
    required this.isDark,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => FadeTransition(
        opacity: fadeAnimation, // 🎞️ Header fade-in
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary, // 🎨 Background principale dell’header
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),

          // Evita overlap con notch, dinamiche, barra di stato
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -----------------------------------------------------------------
                  // 🔷 RIGA SUPERIORE: Bottone resoconto annuale + Avatar profilo
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

                      // 👤 Avatar utente (locale → remoto → icona fallback)
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
                            radius: 20.r,
                            backgroundColor: AppColors.backgroundLight
                                .withValues(alpha: 0.3),

                            // Priorità avatar:
                            // 1. File locale
                            // 2. Foto Firebase
                            // 3. Icona
                            backgroundImage: localAvatar != null
                                ? FileImage(localAvatar!)
                                : (user?.photoURL != null
                                      ? NetworkImage(user!.photoURL!)
                                      : null),

                            child: localAvatar == null && user?.photoURL == null
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
                  // 💰 SEZIONE SPESA DEL MESE CORRENTE
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

                      Text(
                        "€ ${storeModel.value.totalExpenseMonth.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 35.sp,
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textLight,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // -----------------------------------------------------------------
                  // 📊 STATISTICHE GIORNO / SETTIMANA / ANNO
                  // -----------------------------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: HeaderExpenseState(
                          value: storeModel.value.totalExpenseToday,
                          label: "Oggi",
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: HeaderExpenseState(
                          value: storeModel.value.totalExpenseWeek,
                          label: "Settimana",
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: HeaderExpenseState(
                          value: storeModel.value.totalExpenseYear,
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
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 📦 WIDGET: Stato spese (piccola card per Oggi / Settimana / Anno)
// -----------------------------------------------------------------------------
class HeaderExpenseState extends StatelessWidget {
  final double value; // 💶 Valore della spesa
  final String label; // 🏷️ Etichetta (oggi / settimana / anno)

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

      // Contenuto verticale: valore + etichetta
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 💶 Valore spesa formattato
          Text(
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

          SizedBox(height: 2.h),

          // 🏷️ Label card
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
