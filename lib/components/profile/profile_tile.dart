import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/theme/app_colors.dart';

/// FILE: profile_tile.dart
/// DESCRIZIONE: Componente UI riutilizzabile per visualizzare un singolo dato del profilo
/// (es. Nome, Email, Password). Combina un'icona decorativa, le informazioni testuali
/// e un pulsante di azione (solitamente per la modifica), gestendo anche lo stato di caricamento.

class ProfileTile extends StatelessWidget {
  // --- CONFIGURAZIONE ---
  // Parametri per i dati da visualizzare (Icona, Titolo, Valore),
  // callback per l'interazione e gestione dello stato di loading per l'azione.
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onPressed;
  final IconData trailingIcon;
  final String tooltip;
  final Widget? trailingWidget;
  final bool isLoading;

  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.onPressed,
    this.trailingIcon = Icons.edit_outlined,
    required this.tooltip,
    this.trailingWidget,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    // --- STRUTTURA LAYOUT ---
    // Riga orizzontale composta da:
    // 1. Icona decorativa a sinistra.
    // 2. Colonna di testo centrale (Etichetta + Valore).
    // 3. Widget di azione a destra (Edit button o Spinner).
    // 
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // Icona sinistra (con Gradiente e Ombra)
          Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
              ),
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

          // Informazioni Testuali
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyLight,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value ?? loc.notAvailable,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // Azione Laterale (Trailing)
          // Mostra un indicatore di caricamento se l'operazione è in corso,
          // altrimenti mostra il pulsante di azione configurato.
          trailingWidget ??
              Container(
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
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? AppColors.greyDark
                                : AppColors.greyLight,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          trailingIcon,
                          size: 20.r,
                          color: isDark
                              ? AppColors.greyDark
                              : AppColors.greyLight,
                        ),
                        tooltip: tooltip,
                        onPressed: onPressed,
                        padding: EdgeInsets.zero,
                      ),
              ),
        ],
      ),
    );
  }
}