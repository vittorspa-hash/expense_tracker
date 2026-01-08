import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/utils/dialogs/dialog_utils.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/providers/currency_provider.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker/components/settings/settings_tile.dart';
import 'package:expense_tracker/components/settings/settings_section_header.dart';

/// FILE: settings_page.dart
/// DESCRIZIONE: Schermata principale delle impostazioni.
/// Permette all'utente di configurare il tema (Chiaro/Scuro), la valuta principale
/// e le notifiche (Promemoria giornalieri e avvisi di limite budget).
/// Utilizza i provider per persistere le modifiche.

class SettingsPage extends StatefulWidget {
  static const route = "/settings/page";
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  
  @override
  TickerProvider get vsync => this;

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

  // --- HELPER UTILITY ---
  // Restituisce l'icona Material appropriata in base all'enum della valuta.
  IconData _getCurrencyIcon(Currency currency) {
    switch (currency) {
      case Currency.euro:
        return Icons.euro_rounded;
      case Currency.usd:
        return Icons.attach_money_rounded;
      case Currency.gbp:
        return Icons.currency_pound_rounded;
      case Currency.jpy:
        return Icons.currency_yen_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    // Determina l'icona della valuta corrente per visualizzarla nei tile o dialoghi.
    final currentCurrencyIcon = _getCurrencyIcon(currencyProvider.currentCurrency);

    return Scaffold(
      appBar: CustomAppBar(
        title: "Impostazioni",
        icon: Icons.settings_rounded,
        isDark: isDark,
      ),

      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        // Applica l'animazione di fade-in alla lista delle opzioni.
        child: buildWithFadeAnimation(
          ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            children: [
              // --- SEZIONE ASPETTO ---
              // Gestione del cambio tema (Light/Dark mode).
              const SettingsSectionHeader(
                icon: Icons.palette_outlined,
                title: "Aspetto",
              ),

              SizedBox(height: 12.h),

              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark.withValues(alpha: 0.5)
                      : AppColors.cardLight.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(
                        alpha: isDark ? 0.3 : 0.08,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SettingsTile(
                  icon: isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: "Tema scuro",
                  subtitle: isDark ? "Attivato" : "Disattivato",
                  trailingWidget: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) =>
                              themeProvider.toggleTheme(value),
                          activeThumbColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // --- SEZIONE VALUTA ---
              // Permette di selezionare la valuta globale dell'app.
              const SettingsSectionHeader(
                icon: Icons.currency_exchange_rounded,
                title: "Valuta",
              ),

              SizedBox(height: 12.h),

              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark.withValues(alpha: 0.5)
                      : AppColors.cardLight.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(
                        alpha: isDark ? 0.3 : 0.08,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SettingsTile(
                  icon: Icons.payments_rounded,
                  title: "Valuta predefinita",
                  subtitle: "${currencyProvider.currencyName} (${currencyProvider.currencySymbol})",
                  trailingIcon: Icons.chevron_right_rounded,
                  onPressed: () {
                    _selectCurrency(context, isDark, currencyProvider);
                  },
                ),
              ),

              SizedBox(height: 32.h),

              // --- SEZIONE NOTIFICHE ---
              // Gestisce i promemoria orari e gli avvisi di superamento budget.
              const SettingsSectionHeader(
                icon: Icons.notifications_outlined,
                title: "Notifiche",
              ),

              SizedBox(height: 12.h),

              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark.withValues(alpha: 0.5)
                      : AppColors.cardLight.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(
                        alpha: isDark ? 0.3 : 0.08,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Opzione 1: Promemoria giornaliero (Switch)
                    SettingsTile(
                      icon: Icons.alarm_rounded,
                      title: "Promemoria giornaliero",
                      subtitle: notificationProvider.dailyReminderEnabled
                          ? "Attivo alle ${notificationProvider.reminderTime.format(context)}"
                          : "Disattivato",
                      trailingWidget: Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: notificationProvider.dailyReminderEnabled,
                          onChanged: (value) {
                            notificationProvider.toggleDailyReminder(value);
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                      ),
                    ),

                    // Opzione 1.1: Selettore orario (visibile solo se attivo)
                    if (notificationProvider.dailyReminderEnabled) ...[
                      _buildDivider(isDark),
                      SettingsTile(
                        icon: Icons.schedule_rounded,
                        title: "Orario promemoria",
                        subtitle: notificationProvider.reminderTime.format(
                          context,
                        ),
                        trailingIcon: Icons.chevron_right_rounded,
                        onPressed: () =>
                            _selectTime(context, notificationProvider),
                      ),
                    ],

                    _buildDivider(isDark),

                    // Opzione 2: Avviso limite spesa (Switch)
                    SettingsTile(
                      icon: Icons.warning_amber_rounded,
                      title: "Avviso limite spesa",
                      subtitle: notificationProvider.limitAlertEnabled
                          ? "Attivo (${currencyProvider.formatAmount(notificationProvider.monthlyLimit)}/mese)"
                          : "Disattivato",
                      trailingWidget: Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: notificationProvider.limitAlertEnabled,
                          onChanged: (value) {
                            notificationProvider.toggleLimitAlert(value);
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                      ),
                    ),

                    // Opzione 2.1: Input limite mensile (visibile solo se attivo)
                    if (notificationProvider.limitAlertEnabled) ...[
                      _buildDivider(isDark),
                      SettingsTile(
                        icon: currentCurrencyIcon, 
                        title: "Limite mensile",
                        subtitle: currencyProvider.formatAmount(
                          notificationProvider.monthlyLimit,
                        ),
                        trailingIcon: Icons.chevron_right_rounded,
                        onPressed: () =>
                            _selectLimit(context, notificationProvider, currentCurrencyIcon), 
                      ),
                    ],
                  ],
                ),
              ),
              
               SizedBox(height: 24.h),

              // --- BOX INFORMATIVO ---
              // Messaggio statico per spiegare l'utilità delle notifiche all'utente.
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 24.r,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        "Le notifiche ti aiuteranno a tenere traccia delle tue spese quotidiane e a rispettare il budget mensile",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIALOGHI & INTERAZIONI ---
  
  // Apre il TimePicker nativo per scegliere l'orario del promemoria.
  Future<void> _selectTime(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    final picked = await DialogUtils.showTimePickerAdaptive(
      context,
      initialTime: provider.reminderTime,
    );

    if (picked != null && picked != provider.reminderTime) {
      await provider.setReminderTime(picked);
    }
  }

  // Apre un dialog di input per impostare il budget mensile.
  // Utilizza l'icona della valuta corrente nel campo di testo.
  Future<void> _selectLimit(
    BuildContext context,
    NotificationProvider provider,
    IconData currencyIcon, 
  ) async {
    final result = await DialogUtils.showInputDialogAdaptive(
      context,
      title: "Imposta limite mensile",
      fields: [
        {
          "label": "Limite mensile",
          "hintText": "Inserisci importo",
          "prefixIcon": currencyIcon, 
          "keyboardType": TextInputType.number,
          "initialValue": provider.monthlyLimit.toStringAsFixed(0),
          "obscureText": false,
        },
      ],
    );

    if (result != null && result.isNotEmpty) {
      final value = double.tryParse(result.first);
      if (value != null && value > 0) {
        provider.setMonthlyLimit(value);
      }
    }
  }

  // Apre un BottomSheet per selezionare la valuta tra quelle disponibili.
  Future<void> _selectCurrency(
    BuildContext context,
    bool isDark,
    CurrencyProvider currencyProvider,
  ) async {
    final result = await DialogUtils.showSortSheet(
      context,
      isDark: isDark,
      title: "Seleziona valuta",
      options: Currency.values.map((currency) {
        return {
          "title": "${currency.name} (${currency.symbol})",
          "criteria": currency.code,
        };
      }).toList(),
    );

    if (result != null) {
      final selectedCurrency = Currency.fromCode(result);
      await currencyProvider.setCurrency(selectedCurrency);
    }
  }

  // Widget helper per separare visivamente le voci della lista.
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
}