import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: custom_app_bar.dart
/// DESCRIZIONE: AppBar personalizzata che gestisce dinamicamente due stati:
/// navigazione standard e modalità "selezione multipla".
/// Adatta automaticamente icone, titoli e azioni in base al contesto e al tema.

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  // --- CONFIGURAZIONE ---
  // Parametri per contenuto statico, stato del tema e gestione
  // della modalità di selezione (conteggi e callback).
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
    // --- COSTRUZIONE UI ---
    // Gestisce il cambio di stato visivo tra modalità normale e selezione.
    // 
    return AppBar(
      elevation: 0,
      iconTheme: IconThemeData(
        color: isDark ? AppColors.textDark : AppColors.textLight,
      ),

      // --- LEADING ACTION ---
      // In modalità selezione mostra una "X" per annullare,
      // altrimenti mostra il widget standard (es. Back Button o Menu).
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

      // --- TITOLO DINAMICO ---
      // Alterna tra il contatore degli elementi selezionati e il titolo/sottotitolo standard.
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

      centerTitle: true,

      // --- AZIONI CONTESTUALI ---
      // Modalità Selezione: Pulsanti per "Seleziona tutto" e "Elimina".
      // Modalità Normale: Azioni passate dal parent (es. Filtri, Impostazioni).
      actions: isSelectionMode
          ? [
              // Toggle Seleziona/Deseleziona Tutto
              IconButton(
                icon: Icon(
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

              // Pulsante Eliminazione
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

      flexibleSpace: Container(
        decoration: BoxDecoration(color: AppColors.primary),
      ),
    );
  }

  // --- LAYOUT TITOLO STANDARD ---
  // Gestisce la visualizzazione combinata di Titolo + Icona ed eventuale Sottotitolo.
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}