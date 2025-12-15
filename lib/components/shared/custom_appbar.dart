// custom_app_bar.dart
// AppBar personalizzata dell'app.
// Supporta modalità normale e modalità selezione multipla.
// Mostra titolo, sottotitolo opzionale, icona opzionale e azioni personalizzate.
// Gestisce automaticamente lo stato dark/light e i colori del tema.

import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isDark;
  final bool isSelectionMode;
  final int selectedCount;
  final int? totalCount;
  final VoidCallback? onCancelSelection;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final Widget? leading;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.isDark,
    this.isSelectionMode = false,
    this.selectedCount = 0,
    this.totalCount,
    this.onCancelSelection,
    this.onDeleteSelected,
    this.onSelectAll,
    this.onDeselectAll,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      iconTheme: IconThemeData(
        color: isDark ? AppColors.textDark : AppColors.textLight,
      ),

      // Leading personalizzato o pulsante di chiusura in modalità selezione
      leading: isSelectionMode
          ? Container(
              margin: EdgeInsets.only(left: 20.w),
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                  size: 26.sp,
                ),
                onPressed: onCancelSelection,
              ),
            )
          : leading,

      // Titolo della AppBar:
      // - mostra il numero di elementi selezionati in modalità selezione
      // - altrimenti mostra il titolo standard
      title: isSelectionMode
          ? Text(
              "$selectedCount ${selectedCount == 1 ? "selezionata" : "selezionate"}",
              style: TextStyle(
                color: isDark ? AppColors.textDark : AppColors.textLight,
                fontWeight: FontWeight.w700,
                fontSize: 20.sp,
                letterSpacing: 0.5,
              ),
            )
          : _buildTitle(),

      // Centra sempre il titolo
      centerTitle: true,

      // Azioni della AppBar:
      // - pulsante "seleziona tutto" + pulsante di eliminazione in modalità selezione
      // - azioni personalizzate in modalità normale
      actions: isSelectionMode
          ? [
              // Toggle Seleziona/Deseleziona Tutto
              IconButton(
                icon: Icon(
                  // Se sono già tutti selezionati, mostra l'icona per deselezionare
                  (totalCount != null && selectedCount == totalCount)
                      ? Icons.remove_done_rounded
                      : Icons.done_all_rounded,
                  size: 28.sp,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
                tooltip: (totalCount != null && selectedCount == totalCount)
                    ? "Deseleziona tutto"
                    : "Seleziona tutto",
                onPressed: (totalCount != null && selectedCount == totalCount)
                    ? onDeselectAll
                    : onSelectAll,
              ),

              SizedBox(width: 8.w),

              // Pulsante eliminazione
              Container(
                margin: EdgeInsets.only(right: 20.w),
                decoration: BoxDecoration(
                  color: AppColors.delete.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  icon: Icon(Icons.delete_rounded, size: 24.sp),
                  color: AppColors.delete,
                  tooltip: "Elimina selezionate",
                  onPressed: onDeleteSelected,
                ),
              ),
            ]
          : actions,

      // Sfondo della AppBar con colore primario
      flexibleSpace: Container(
        decoration: BoxDecoration(color: AppColors.primary),
      ),
    );
  }

  // Costruisce il titolo della AppBar in modalità normale
  // Supporta:
  // - titolo con sottotitolo
  // - titolo con icona opzionale
  Widget _buildTitle() {
    if (subtitle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (icon != null) ...[
                SizedBox(width: 6.w),
                Icon(
                  icon,
                  size: 22.r,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ],
            ],
          ),
          Text(
            subtitle!,
            style: TextStyle(
              color: isDark
                  ? AppColors.textDark.withValues(alpha: 0.85)
                  : AppColors.textLight.withValues(alpha: 0.85),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    }

    // Titolo senza sottotitolo
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.textDark : AppColors.textLight,
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        if (icon != null) ...[
          SizedBox(width: 6.w),
          Icon(
            icon,
            size: 26.r,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ],
      ],
    );
  }

  // Altezza standard della AppBar
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
