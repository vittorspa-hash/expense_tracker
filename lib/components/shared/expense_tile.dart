import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/currency_model.dart';
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
/// Visualizza i dettagli principali (importo, data, descrizione).
/// Gestisce la logica multi-valuta: se la spesa è in una valuta diversa da quella dell'app,
/// mostra il controvalore convertito oppure un'icona di warning se i tassi non sono disponibili
/// (es. spesa creata offline con strategia "Soft Fail").

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
  // Gestisce la capitalizzazione del mese per coerenza stilistica.
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

  // Restituisce la stringa dell'importo formattata secondo la valuta originale della spesa.
  String _getOriginalAmount() {
    final currency = Currency.fromCode(widget.expenseModel.currency);
    return currency.format(widget.expenseModel.value);
  }

  // --- COSTRUZIONE UI ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        
        // --- 1. LOGICA DI CONVERSIONE E FEEDBACK ---
        final currentCurrencyCode = currencyProvider.currencyCode;
        final originalCurrencyCode = widget.expenseModel.currency;
        
        // Determiniamo se è necessario mostrare informazioni aggiuntive (valute diverse)
        final bool showConversion = currentCurrencyCode != originalCurrencyCode;
        
        String? convertedAmountString;
        bool hasRate = false;

        if (showConversion) {
          // Verifica integrità dati: controlliamo se il tasso necessario esiste.
          // Se manca, significa che la spesa è stata salvata offline ("Soft Fail").
          hasRate = widget.expenseModel.exchangeRates.containsKey(currentCurrencyCode);

          if (hasRate) {
             final convertedValue = widget.expenseModel.getValueIn(currentCurrencyCode);
             convertedAmountString = "≈ ${currencyProvider.formatAmount(convertedValue)}";
          }
        }

        // --- 2. LAYOUT COMPONENTE ---
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
                    // Visualizza l'importo originale e, se necessario, la conversione o il warning.
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
                          // A) Valore Originale (Sempre visibile)
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
                          
                          // B) Riga Sottostante (Conversione o Icona Errore)
                          if (showConversion) ...[
                             SizedBox(height: 2.h), 
                             
                             if (!hasRate) 
                               // CASO ERRORE (Soft Fail):
                               // La mappa dei tassi è incompleta. Mostriamo icona discreta.
                               Icon(
                                 Icons.warning_amber_rounded,
                                 color: AppColors.primary, 
                                 size: 14.sp,
                               )
                             else if (convertedAmountString != null)
                               // CASO SUCCESSO:
                               // Mostriamo il controvalore calcolato.
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