import 'package:expense_tracker/l10n/app_localizations.dart';
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
/// Visualizza i dettagli principali (importo, data, descrizione) e gestisce intelligentemente
/// la valuta: se la spesa è stata fatta in una valuta diversa da quella attuale dell'app,
/// mostra sia l'originale che la conversione.

class ExpenseTile extends StatefulWidget {
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
  bool _isPressed = false; 

  // --- FORMATTAZIONE DATI ---
  // Helper locale per formattare la data (es. "12 Gennaio 2024").
  // Capitalizza manualmente il mese poiché DateFormat potrebbe restituirlo minuscolo.
  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    
    final giorno = DateFormat("d", locale).format(date);
    final mese = DateFormat("MMMM", locale).format(date);
    final anno = DateFormat("y", locale).format(date);
    
    final meseCapitalizzato = mese.isNotEmpty 
        ? mese[0].toUpperCase() + mese.substring(1) 
        : mese;
        
    return "$giorno $meseCapitalizzato $anno";
  }

  // Restituisce la stringa dell'importo formattata secondo la valuta
  // in cui è stata originariamente registrata la spesa.
  String _getOriginalAmount() {
    final currency = Currency.fromCode(widget.expenseModel.currency);
    return currency.format(widget.expenseModel.value);
  }

  // --- COSTRUZIONE UI ---
  // Utilizza un Consumer sul CurrencyProvider per aggiornare la UI in tempo reale
  // se l'utente cambia la valuta principale dell'applicazione.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        
        // 1. Logica di Conversione
        // Confrontiamo la valuta corrente dell'app con quella salvata nella spesa.
        final currentCurrencyCode = currencyProvider.currencyCode;
        final originalCurrencyCode = widget.expenseModel.currency;
        
        // Se diverse, calcoliamo il controvalore da mostrare come info aggiuntiva.
        final bool showConversion = currentCurrencyCode != originalCurrencyCode;
        
        String? convertedAmountString;
        
        if (showConversion) {
          final convertedValue = widget.expenseModel.getValueIn(currentCurrencyCode);
          // Aggiungiamo '≈' per indicare che è una conversione basata su tassi storici.
          convertedAmountString = "≈ ${currencyProvider.formatAmount(convertedValue)}";
        }

        // 2. Gestione Interazioni
        // Gestisce il tap (modifica/selezione) e l'animazione di pressione (scale).
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

              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    // --- BOX IMPORTO ---
                    // Visualizza l'importo. Contiene logica condizionale per mostrare
                    // anche il valore convertito se necessario.
                    Container(
                      width: 90.w,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w, 
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
                      child: Column( 
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Valore Originale (Grande)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              _getOriginalAmount(),
                              style: TextStyle(
                                color: isDark ? AppColors.textDark : AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp, 
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          
                          // Valore Convertito (Piccolo) - Visibile solo se le valute differiscono
                          if (showConversion && convertedAmountString != null) ...[
                             SizedBox(height: 2.h), 
                             SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                               child: Text(
                                convertedAmountString,
                                style: TextStyle(
                                  color: isDark 
                                    ? AppColors.textDark.withValues(alpha: 0.8) 
                                    : AppColors.primary.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10.sp, 
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                               ),
                             ),
                          ]
                        ],
                      ),
                    ),

                    SizedBox(width: 16.w),

                    // --- DETTAGLI SPESA ---
                    // Data e descrizione testuale.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(context, widget.expenseModel.createdOn),
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
                                loc.noDescription,
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

                    // --- INDICATORE STATO ---
                    // Mostra una freccia (navigazione) o checkbox (selezione).
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
    );
  }
}