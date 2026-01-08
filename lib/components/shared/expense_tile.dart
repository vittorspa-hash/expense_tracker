import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/pages/edit_expense_page.dart';
import 'package:expense_tracker/providers/currency_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: expense_tile.dart
/// DESCRIZIONE: Componente UI che rappresenta una singola voce di spesa nella lista.
/// Gestisce la visualizzazione dei dati con formattazione dinamica della valuta,
/// la formattazione della data, le animazioni al tocco e logica condizionale
/// per la navigazione o la selezione multipla.

class ExpenseTile extends StatefulWidget {
  // --- PARAMETRI ---
  // Modello dati, flag per lo stato di selezione e callback per le interazioni.
  final ExpenseModel expenseModel; 
  final bool isSelectionMode; 
  final bool isSelected; 
  final VoidCallback? onLongPress; 
  final VoidCallback? onSelectToggle; 

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
  // Stato interno per gestire l'animazione di "shrink" alla pressione.
  bool _isPressed = false; 

  // --- FORMATTAZIONE DATA ---
  // Helper locale per convertire il timestamp in formato leggibile italiano.
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
    
    // --- CURRENCY PROVIDER ---
    // Consumer per ascoltare i cambiamenti della valuta e aggiornare automaticamente
    // la formattazione dell'importo visualizzato.
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        // --- INTERAZIONE & GESTURE ---
        // Gestisce:
        // 1. LongPress: Attiva la modalità selezione.
        // 2. Tap: Naviga al dettaglio O commuta la selezione (se in modalità edit).
        // 3. Feedback Tattile: Modifica lo stato _isPressed per l'animazione.
        // 
        return GestureDetector(
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

          // --- CONTENITORE VISIVO ANIMATO ---
          // Applica un fattore di scala quando premuto.
          // Il bordo e il colore di sfondo cambiano dinamicamente se l'elemento è selezionato.
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

              // --- LAYOUT CONTENUTO ---
              // Struttura a riga: Importo (Box) - Dettagli (Testo) - Indicatore (Icona).
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    // --- BOX IMPORTO ---
                    // Utilizza la formattazione dinamica della valuta dal CurrencyProvider
                    Container(
                      width: 90.w,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      alignment: Alignment.center,
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          currencyProvider.formatAmount(
                            widget.expenseModel.value,
                          ),
                          style: TextStyle(
                            color: isDark ? AppColors.textDark : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 16.w),

                    // --- DETTAGLI (Data e Descrizione) ---
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

                    // --- INDICATORE DI STATO ---
                    // Mostra un Chevron (Navigazione) o un Checkbox/Radio (Selezione)
                    // in base alla modalità corrente.
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
      },
    );
  }
}