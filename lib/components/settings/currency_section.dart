import 'package:expense_tracker/components/settings/settings_container.dart';
import 'package:expense_tracker/components/settings/settings_section_header.dart';
import 'package:expense_tracker/components/settings/settings_tile.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/notifiers/currency_notifier.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: currency_section.dart
/// DESCRIZIONE: Sezione Impostazioni per la valuta globale dell'app. Alla
/// selezione, aggiorna sia currencyNotifierProvider sia i totali già
/// calcolati in expenseNotifierProvider (conversione senza ricaricare le spese).

class CurrencySection extends ConsumerWidget {
  const CurrencySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyState = ref.watch(currencyNotifierProvider);
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(icon: Icons.currency_exchange_rounded, title: loc.currency),
        SizedBox(height: 12.h),
        SettingsContainer(
          child: SettingsTile(
            icon: Icons.payments_rounded,
            title: loc.defaultCurrency,
            subtitle: "${currencyState.currencyName} (${currencyState.currencySymbol})",
            trailingIcon: Icons.chevron_right_rounded,
            logout: false,
            onPressed: () => _selectCurrency(context, ref, isDark, currencyState),
          ),
        ),
      ],
    );
  }

  Future<void> _selectCurrency(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    CurrencyState currencyState,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final result = await DialogUtils.showSortSheet(
      context,
      isDark: isDark,
      title: loc.selectCurrencyTitle,
      options: ExpenseCurrency.values.map((currency) {
        return {
          "title": "${currency.name} (${currency.symbol})",
          "criteria": currency.code,
        };
      }).toList(),
    );

    if (result != null) {
      final selectedCurrency = ExpenseCurrency.fromCode(result);
      await ref.read(currencyNotifierProvider.notifier).setCurrency(selectedCurrency);
      if (context.mounted) {
        ref.read(expenseNotifierProvider.notifier).updateAppCurrency(selectedCurrency);
      }
    }
  }
}