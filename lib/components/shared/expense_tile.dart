import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/pages/edit_expense_page.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: expense_tile.dart
/// DESCRIZIONE: Componente UI che rappresenta una singola voce di spesa nella lista.
/// Visualizza i dettagli principali (importo, data, categoria, descrizione).
/// Gestisce la logica multi-valuta: se la spesa è in una valuta diversa da quella dell'app,
/// mostra il controvalore convertito oppure un'icona di warning se i tassi non sono disponibili
/// (es. spesa creata offline con strategia "Soft Fail").

class ExpenseTile extends ConsumerStatefulWidget {
  final ExpenseModel expenseModel;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectToggle;
  final VoidCallback onReturn;

  const ExpenseTile(
    this.expenseModel, {
    super.key,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelectToggle,
    required this.onReturn,
  });

  @override
  ConsumerState<ExpenseTile> createState() => _ExpenseTileState();
}

class _ExpenseTileState extends ConsumerState<ExpenseTile> {
  bool _isPressed = false;

  // --- FORMATTAZIONE DATI ---
  
  /// Formatta la data di creazione (es. "12 Gennaio 2024") localizzandola.
  /// Applica la capitalizzazione sulla prima lettera del mese per uniformità grafica.
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

  /// Restituisce la stringa dell'importo formattata con il simbolo della valuta d'origine.
  String _getOriginalAmount() {
    return widget.expenseModel.currency.format(widget.expenseModel.value);
  }

  // --- COSTRUZIONE UI ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final currencyState = ref.watch(currencyNotifierProvider);

    // --- 1. LOGICA DI CONVERSIONE E FEEDBACK ---
    final currentCurrency = currencyState.currentCurrency;
    final bool showConversion = widget.expenseModel.currency != currentCurrency;

    String? convertedAmountString;
    bool hasRate = false;

    if (showConversion) {
      // Verifica l'integrità dei dati: controlliamo se il tasso necessario esiste in mappa.
      // Se manca, significa che la spesa è stata salvata offline (strategia "Soft Fail").
      hasRate = widget.expenseModel.exchangeRates.containsKey(currentCurrency.code);

      if (hasRate) {
        final convertedValue = widget.expenseModel.getValueIn(currentCurrency);
        convertedAmountString = "≈ ${currencyState.formatAmount(convertedValue)}";
      }
    }

    // --- 2. LAYOUT COMPONENTE ---
    return GestureDetector(
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () async {
        setState(() => _isPressed = false);
        if (widget.isSelectionMode) {
          widget.onSelectToggle?.call();
        } else {
          await Navigator.pushNamed(
            context,
            EditExpensePage.route,
            arguments: widget.expenseModel,
          );
          widget.onReturn();
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
                // Visualizza l'importo originale e, se necessario, il controvalore o il warning di mancata conversione.
                Container(
                  width: 90.w,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
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
                      // A) Valore Originale (Sempre visibile in primo piano)
                      // Utilizza uno scroll orizzontale per evitare overflow in caso di cifre molto lunghe.
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

                      // B) Riga Sottostante (Conversione in tempo reale o Icona Errore)
                      if (showConversion) ...[
                        SizedBox(height: 2.h),
                        if (!hasRate)
                          // CASO ERRORE (Soft Fail): Mappa dei tassi incompleta a causa dell'offline.
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.primary,
                            size: 14.sp,
                          )
                        else if (convertedAmountString != null)
                          // CASO SUCCESSO: Mostriamo il tasso di cambio approssimativo.
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
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 16.w),

                // --- DETTAGLI SPESA ---
                // Sezione centrale con i metadati descrittivi della spesa disposti verticalmente.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. DATA DI CREAZIONE
                      Text(
                        _formatDate(context, widget.expenseModel.createdOn),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textLight : AppColors.textDark2,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 4.h),

                      // 2. CATEGORIA (Icona + Etichetta localizzata)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.expenseModel.category.icon,
                            size: 12.sp,
                            color: isDark ? AppColors.greyDark : AppColors.greyLight,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            widget.expenseModel.category.label(loc),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? AppColors.greyDark : AppColors.greyLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),

                      // 3. DESCRIZIONE TESTUALE
                      Text(
                        widget.expenseModel.description ?? loc.noDescription,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? AppColors.greyDark : AppColors.greyLight,
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
                // Mostra un checkbox circolare se l'app è in modalità selezione multipla,
                // altrimenti una freccia direzionale per indicare la navigabilità alla modifica.
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