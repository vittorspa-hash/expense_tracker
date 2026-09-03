import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: currency_amount_input.dart
/// DESCRIZIONE: Input combinato simbolo valuta (cliccabile, apre il picker)
/// + campo numerico per l'importo, con normalizzazione automatica virgola→punto.
/// Estratto da ExpenseEdit per isolare la logica di input più complessa del form.

class CurrencyAmountInput extends StatelessWidget {
  final TextEditingController controller;
  final ExpenseCurrency selectedCurrency;
  final ValueChanged<ExpenseCurrency> onCurrencyChanged;
  final bool isTappedDown;

  const CurrencyAmountInput({
    super.key,
    required this.controller,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.isTappedDown,
  });

  @override
  Widget build(BuildContext context) {
    final String hintText = selectedCurrency == ExpenseCurrency.jpy ? "0" : "0.00";
    final textColor = isTappedDown ? AppColors.textLight : AppColors.textTappedDown;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Selettore della valuta (Codice monetario e simbolo)
          GestureDetector(
            onTap: () => _showCurrencyPicker(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              color: Colors.transparent,
              child: Text(
                selectedCurrency.symbol,
                style: TextStyle(
                  fontSize: 50.sp,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Campo di input numerico per l'ammontare speso
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: textColor,
                  style: TextStyle(
                    fontSize: 50.sp,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    // Normalizzazione automatica della virgola in punto decimale
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text.replaceAll(',', '.');
                      return newValue.copyWith(
                        text: text,
                        selection: newValue.selection,
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: AppColors.secondaryDark,
                      fontSize: 50.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = ExpenseCurrency.values
        .map((c) => {"title": "${c.name} (${c.symbol})", "criteria": c.code})
        .toList();

    final result = await DialogUtils.showSortSheet(
      context,
      isDark: isDark,
      options: options,
      title: AppLocalizations.of(context)!.selectCurrencyTitle,
    );

    if (result != null) {
      onCurrencyChanged(ExpenseCurrency.fromCode(result));
    }
  }
}