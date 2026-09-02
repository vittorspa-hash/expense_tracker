import 'package:expense_tracker/components/settings/settings_container.dart';
import 'package:expense_tracker/components/settings/settings_section_header.dart';
import 'package:expense_tracker/components/settings/settings_tile.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/notifiers/notification_notifier.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: notifications_section.dart
/// DESCRIZIONE: Sezione Impostazioni per il promemoria giornaliero e l'avviso
/// di superamento budget mensile. Include il box informativo statico e i
/// dialoghi di orario/limite, gestiti internamente.

class NotificationsSection extends ConsumerWidget {
  const NotificationsSection({super.key});

  // Restituisce l'icona Material appropriata in base all'enum della valuta.
  IconData _getCurrencyIcon(ExpenseCurrency currency) {
    switch (currency) {
      case ExpenseCurrency.euro:
        return Icons.euro_rounded;
      case ExpenseCurrency.usd:
        return Icons.attach_money_rounded;
      case ExpenseCurrency.gbp:
        return Icons.currency_pound_rounded;
      case ExpenseCurrency.jpy:
        return Icons.currency_yen_rounded;
    }
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? AppColors.dividerDark.withValues(alpha: 0.3)
            : AppColors.dividerLight.withValues(alpha: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationState = ref.watch(notificationNotifierProvider);
    final currencyState = ref.watch(currencyNotifierProvider);
    final loc = AppLocalizations.of(context)!;
    final currentCurrencyIcon = _getCurrencyIcon(currencyState.currentCurrency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(icon: Icons.notifications_outlined, title: loc.notifications),
        SizedBox(height: 12.h),
        SettingsContainer(
          child: Column(
            children: [
              // Opzione 1: Promemoria giornaliero (Switch)
              SettingsTile(
                icon: Icons.alarm_rounded,
                title: loc.dailyReminder,
                subtitle: notificationState.dailyReminderEnabled
                    ? loc.activeAt(notificationState.reminderTime.format(context))
                    : loc.deactivated,
                trailingWidget: Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: notificationState.dailyReminderEnabled,
                    onChanged: (value) {
                      ref
                          .read(notificationNotifierProvider.notifier)
                          .toggleDailyReminder(value, AppLocalizations.of(context)!);
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                logout: false,
              ),

              // Opzione 1.1: Selettore orario (visibile solo se attivo)
              if (notificationState.dailyReminderEnabled) ...[
                _buildDivider(isDark),
                SettingsTile(
                  icon: Icons.schedule_rounded,
                  title: loc.reminderTime,
                  subtitle: notificationState.reminderTime.format(context),
                  trailingIcon: Icons.chevron_right_rounded,
                  logout: false,
                  onPressed: () => _selectTime(context, ref, notificationState),
                ),
              ],

              _buildDivider(isDark),

              // Opzione 2: Avviso limite spesa (Switch)
              SettingsTile(
                icon: Icons.warning_amber_rounded,
                title: loc.spendingLimitAlert,
                subtitle: notificationState.limitAlertEnabled
                    ? loc.activeMonthlyLimit(
                        currencyState.formatAmount(notificationState.monthlyLimit),
                      )
                    : loc.deactivated,
                trailingWidget: Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: notificationState.limitAlertEnabled,
                    onChanged: (value) {
                      ref.read(notificationNotifierProvider.notifier).toggleLimitAlert(value);
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                logout: false,
              ),

              // Opzione 2.1: Input limite mensile (visibile solo se attivo)
              if (notificationState.limitAlertEnabled) ...[
                _buildDivider(isDark),
                SettingsTile(
                  icon: currentCurrencyIcon,
                  title: loc.monthlyLimit,
                  subtitle: currencyState.formatAmount(notificationState.monthlyLimit),
                  trailingIcon: Icons.chevron_right_rounded,
                  logout: false,
                  onPressed: () =>
                      _selectLimit(context, ref, notificationState, currentCurrencyIcon),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // --- BOX INFORMATIVO ---
        // Nota: non usiamo SettingsContainer qui perché lo stile è specifico (bordo primary).
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primary, width: 0),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  loc.notificationsInfo,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- DIALOGHI ---

  Future<void> _selectTime(
    BuildContext context,
    WidgetRef ref,
    NotificationState notificationState,
  ) async {
    final picked = await DialogUtils.showTimePickerAdaptive(
      context,
      initialTime: notificationState.reminderTime,
    );

    if (picked != null && picked != notificationState.reminderTime && context.mounted) {
      await ref
          .read(notificationNotifierProvider.notifier)
          .setReminderTime(picked, AppLocalizations.of(context)!);
    }
  }

  Future<void> _selectLimit(
    BuildContext context,
    WidgetRef ref,
    NotificationState notificationState,
    IconData currencyIcon,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final result = await DialogUtils.showInputDialogAdaptive(
      context,
      title: loc.setMonthlyLimitTitle,
      fields: [
        {
          "label": loc.monthlyLimit,
          "hintText": loc.insertAmountHint,
          "prefixIcon": currencyIcon,
          "keyboardType": TextInputType.number,
          "initialValue": notificationState.monthlyLimit.toStringAsFixed(0),
          "obscureText": false,
        },
      ],
    );

    if (result != null && result.isNotEmpty) {
      final value = double.tryParse(result.first);
      if (value != null && value > 0) {
        ref.read(notificationNotifierProvider.notifier).setMonthlyLimit(value);
      }
    }
  }
}