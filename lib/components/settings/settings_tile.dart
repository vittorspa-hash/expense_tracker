import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

/// FILE: settings_tile.dart
/// DESCRIZIONE: Componente UI per visualizzare una singola voce nella lista delle impostazioni.
/// Strutturato in tre parti: Icona decorativa (sinistra), Informazioni testuali (centro)
/// e Azione/Widget (destra, es. Switch o Chevron).

class SettingsTile extends StatelessWidget {
  // --- PARAMETRI ---
  // Configurazione del tile: icona principale, testi descrittivi e 
  // widget di coda opzionale (trailingWidget) che ha priorità sull'icona di default.
  final IconData icon; 
  final String title; 
  final String? subtitle; 
  final VoidCallback? onPressed; 
  final IconData trailingIcon; 
  final Widget? trailingWidget; 

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onPressed,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- STRUTTURA LAYOUT ---
    // Organizza gli elementi orizzontalmente con padding standard.
    // 
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // --- ICONA SINISTRA ---
          // Container decorativo con sfondo colorato semitrasparente e ombra.
          Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 24.r, color: AppColors.primary),
          ),

          SizedBox(width: 16.w),

          // --- INFO TESTUALI ---
          // Colonna centrale che si espande per occupare lo spazio disponibile.
          // Gestisce titolo e sottotitolo opzionale.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.greyLight,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // --- AZIONE TRAILING ---
          // Logica di visualizzazione della parte destra:
          // 1. Se esiste un `trailingWidget` (es. Switch), lo mostra.
          // 2. Altrimenti, se c'è un callback `onPressed`, mostra un bottone icona (es. Chevron).
          // 3. Altrimenti, nulla.
          trailingWidget ??
              (onPressed != null
                  ? Container(
                      width: 36.w,
                      height: 36.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderLight.withValues(alpha: 0.2)
                              : AppColors.borderDark.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          trailingIcon,
                          size: 20.r,
                          color: isDark
                              ? AppColors.greyDark
                              : AppColors.greyLight,
                        ),
                        onPressed: onPressed,
                        padding: EdgeInsets.zero,
                      ),
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );
  }
}