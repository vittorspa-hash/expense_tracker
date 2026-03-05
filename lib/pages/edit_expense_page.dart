import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/providers/currency_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/components/expense/expense_edit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: edit_expense_page.dart
/// DESCRIZIONE: Pagina dedicata alla modifica di una spesa esistente.
/// Pre-popola il modulo con i dati dell'oggetto ExpenseModel passato e gestisce
/// logiche avanzate come la visualizzazione del tasso di cambio storico se la
/// valuta della spesa originale differisce da quella attualmente impostata nell'app.

class EditExpensePage extends StatefulWidget {
  static const route = "/expense/edit";
  final ExpenseModel expenseModel;

  const EditExpensePage(this.expenseModel, {super.key});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  // --- CONFIGURAZIONE ANIMAZIONE ---
  @override
  TickerProvider get vsync => this;

  @override
  Duration get fadeAnimationDuration => const Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    initFadeAnimation();
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  // --- HEADER CONVERSIONE VALUTA ---
  Widget? _buildExchangeRateBanner(BuildContext context, bool isHovered) {
    final model = widget.expenseModel;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );
    final currentAppCurrency = currencyProvider.currentCurrency;
    if (model.currency == currentAppCurrency) return null;

    final bool hasRate = model.exchangeRates.containsKey(currentAppCurrency.code);

    final Color baseColor = AppColors.primary;
    final Color iconColor = isHovered ? AppColors.textLight : baseColor;
    final Color titleColor = isHovered
        ? AppColors.textLight
        : (isDark ? AppColors.greyLight : AppColors.greyDark);
    final Color textColor = isHovered
        ? AppColors.textLight
        : (isDark ? AppColors.textLight : AppColors.textDark);
    final Color highlightColor = isHovered ? AppColors.textLight : baseColor;
    final Color boxBgColor = isHovered
        ? AppColors.textLight.withValues(alpha: 0.1)
        : baseColor.withValues(alpha: 0.08);
    final Color boxBorderColor = isHovered
        ? AppColors.textLight.withValues(alpha: 0.3)
        : baseColor.withValues(alpha: 0.2);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: boxBgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: boxBorderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasRate
                ? Icons.currency_exchange_rounded
                : Icons.warning_amber_rounded,
            color: iconColor,
            size: 26.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasRate) ...[
                  Text(
                    loc.editExpenseConvertedTitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 2.h),
                ],
                if (hasRate) ...[
                  _buildSuccessContent(
                    context,
                    model,
                    currentAppCurrency,
                    currencyProvider,
                    loc,
                    textColor,
                    highlightColor,
                  ),
                ] else ...[
                  _buildErrorContent(textColor, highlightColor, loc),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(
    BuildContext context,
    ExpenseModel model,
    ExpenseCurrency  targetCurrency,
    CurrencyProvider cp,
    AppLocalizations loc,
    Color textColor,
    Color highlightColor,
  ) {
    final convertedValue = model.getValueIn(targetCurrency);
    final formattedConverted = cp.formatAmount(convertedValue);
    final dateStr = DateFormat('dd/MM/yyyy').format(model.createdOn);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 15.sp,
          color: textColor,
          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        ),
        children: [
          TextSpan(text: loc.editExpenseExchangeRateDate(dateStr)),
          TextSpan(
            text: "≈ $formattedConverted",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: highlightColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(
    Color textColor,
    Color highlightColor,
    AppLocalizations loc,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.conversionUnavailable,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: highlightColor,
            ),
          ),
          Text(
            loc.retryWhenOnline,
            style: TextStyle(fontSize: 12.sp, color: textColor),
          ),
        ],
      ),
    );
  }

  // --- SALVATAGGIO MODIFICHE ---
  // Ora include il parametro category per aggiornare anche la categoria su Firestore.
  Future<void> onSubmit({
    required double value,
    required String? description,
    required DateTime date,
    required ExpenseCurrency currencyCode,
    required ExpenseCategory category, // NUOVO
    required AppLocalizations l10n,
  }) async {
    final provider = context.read<ExpenseProvider>();

    await provider.editExpense(
      widget.expenseModel,
      value: value,
      description: description,
      date: date,
      currencyCode: currencyCode,
      category: category, 
      l10n: l10n,
    );
  }

  // --- ELIMINAZIONE SPESA ---
  Future<ExpenseModel?> onDelete() async {
    final provider = context.read<ExpenseProvider>();
    final modelToDelete = widget.expenseModel;

    await provider.deleteExpenses([modelToDelete]);

    if (!mounted) return null;
    if (provider.errorMessage != null) return null;

    return modelToDelete;
  }

  // --- COSTRUZIONE UI ---
  // Passa initialCategory pre-popolata con la categoria della spesa esistente.
  @override
  Widget build(BuildContext context) {
    return buildWithFadeAnimation(
      ExpenseEdit(
        initialValue: widget.expenseModel.value,
        initialDescription: widget.expenseModel.description,
        initialDate: widget.expenseModel.createdOn,
        initialCurrencyCode: widget.expenseModel.currency.code,
        initialCategory: widget.expenseModel.category, 

        headerBuilder: (isHovered) =>
            _buildExchangeRateBanner(context, isHovered),

        floatingActionButtonIcon: Icons.delete,
        onFloatingActionButtonPressed: onDelete,
        onSubmit: onSubmit,
      ),
    );
  }
}
