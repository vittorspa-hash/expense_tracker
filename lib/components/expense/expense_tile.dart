// expense_tile.dart
// -----------------------------------------------------------------------------
// 📄 WIDGET TILE PER SINGOLA SPESA (ExpenseTile)
// -----------------------------------------------------------------------------
// Rappresenta una singola spesa nella lista giornaliera con:
// - Visualizzazione importo in evidenza
// - Data formattata in italiano
// - Descrizione della spesa
// - Stato di selezione per modalità multi-select
// - Animazione di pressione (tap) con effetto scala
// - Navigazione verso EditExpensePage se non in modalità selezione
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/pages/edit_expense_page.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExpenseTile extends StatefulWidget {
  final ExpenseModel expenseModel; // 🔹 Modello dati della spesa
  final bool isSelectionMode; // 🔹 Flag modalità selezione multipla
  final bool isSelected; // 🔹 Flag se la spesa è selezionata
  final VoidCallback? onLongPress; // 🔹 Callback su pressione prolungata
  final VoidCallback? onSelectToggle; // 🔹 Callback per togglare selezione

  const ExpenseTile(
    this.expenseModel, {
    super.key,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelectToggle,
  });

  @override
  State<ExpenseTile> createState() => _ExpenseTileState();
}

class _ExpenseTileState extends State<ExpenseTile> {
  bool _isPressed = false; // 🔹 Stato di pressione per animazione scala

  // ---------------------------------------------------------------------------
  // 🔹 FORMATTAZIONE DATA IN ITALIANO
  // ---------------------------------------------------------------------------
  String formatDateItaliano(DateTime date) {
    final giorno = DateFormat("d", "it_IT").format(date);
    final mese = DateFormat("MMMM", "it_IT").format(date);
    final anno = DateFormat("y", "it_IT").format(date);
    final meseCapitalizzato = mese[0].toUpperCase() + mese.substring(1);
    return "$giorno $meseCapitalizzato $anno";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      // -----------------------------------------------------------------------
      // 🔹 GESTIONE TAP E LONGPRESS
      // -----------------------------------------------------------------------
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        setState(() => _isPressed = false);
        if (widget.isSelectionMode) {
          widget.onSelectToggle?.call();
        } else {
          Navigator.pushNamed(
            context,
            EditExpensePage.route,
            arguments: widget.expenseModel,
          );
        }
      },

      // -----------------------------------------------------------------------
      // 🔹 ANIMAZIONE SCALA SU TAP
      // -----------------------------------------------------------------------
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : (isDark ? AppColors.cardDark : AppColors.cardLight),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.backgroundLight),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.shadow.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: widget.isSelected ? 12 : 8,
                offset: Offset(0, widget.isSelected ? 6 : 3),
              ),
            ],
          ),

          // ---------------------------------------------------------------------
          // 🔹 CONTENUTO DEL TILE
          // ---------------------------------------------------------------------
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                // -----------------------------------------------------------------
                // 🔹 CONTAINER IMPORTO SPESA
                // -----------------------------------------------------------------
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.secondaryDark
                        : AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    "€ ${widget.expenseModel.value.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: isDark ? AppColors.textDark : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // -----------------------------------------------------------------
                // 🔹 COLONNA CON DATA E DESCRIZIONE
                // -----------------------------------------------------------------
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDateItaliano(widget.expenseModel.createdOn),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textDark2,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.expenseModel.description ??
                            "Nessuna descrizione",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? AppColors.greyDark
                              : AppColors.greyLight,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // -----------------------------------------------------------------
                // 🔹 ICONA SELEZIONE O NAVIGAZIONE
                // -----------------------------------------------------------------
                SizedBox(
                  width: 40.w,
                  height: 40.h,
                  child: Icon(
                    widget.isSelectionMode
                        ? (widget.isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded)
                        : Icons.chevron_right_rounded,
                    color: widget.isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.greyDark : AppColors.greyLight),
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
